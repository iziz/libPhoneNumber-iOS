#!/usr/bin/swift

import Foundation

enum ScriptError: Error, CustomStringConvertible {
  case invalidArguments(String)
  case downloadFailed(URL, String)
  case invalidResponse(URL)
  case missingTool(String)
  case missingCarrierDirectory(URL)
  case missingPhoneMetadataXML(URL)
  case invalidMetadataFile(URL, Int, String)
  case processFailed(String)

  var description: String {
    switch self {
    case .invalidArguments(let message):
      return message
    case .downloadFailed(let url, let message):
      return "Failed to download \(url.absoluteString): \(message)"
    case .invalidResponse(let url):
      return "Unexpected response while downloading \(url.absoluteString)"
    case .missingTool(let tool):
      return "Required tool not found: \(tool)"
    case .missingCarrierDirectory(let url):
      return "Could not find resources/carrier under \(url.path)"
    case .missingPhoneMetadataXML(let url):
      return "Could not find resources/PhoneNumberMetadata.xml under \(url.path)"
    case .invalidMetadataFile(let url, let line, let message):
      return "Invalid carrier metadata file \(url.path):\(line): \(message)"
    case .processFailed(let message):
      return message
    }
  }
}

struct Options {
  var ref: String?
  var sourceDirectory: URL?
  var outputDirectory: URL?
  var replaceBundle = false
  var dryRun = false
  var keepTemporaryFiles = false
}

struct CarrierEntry: Codable {
  let locale: String
  let prefix: String
  let carrierName: String
}

struct CarrierArtifact: Codable {
  let schemaVersion: Int
  let upstreamRef: String
  let sourcePath: String
  let sourceSHA256: String
  let entryCount: Int
  let mobilePortableRegionCount: Int
  let mobilePortableRegions: [String]
  let localeCounts: [String: Int]
  let entries: [CarrierEntry]
}

let scriptURL = absoluteURL(forPath: CommandLine.arguments[0])
let scriptsDirectory = scriptURL.deletingLastPathComponent()
let repositoryRoot = scriptsDirectory.deletingLastPathComponent()
let bundleDirectory = repositoryRoot
  .appendingPathComponent("libPhoneNumberCarrierMetaData/CarrierMetaData.bundle")

func usage() -> String {
  """
  Usage:
    swift scripts/updateCarrierMetadata.swift <version|master|ref> [--output <dir>] [--replace-bundle] [--dry-run]
    swift scripts/updateCarrierMetadata.swift --source <google-libphonenumber-dir-or-carrier-dir> [--output <dir>] [--replace-bundle] [--dry-run]

  Examples:
    swift scripts/updateCarrierMetadata.swift 9.0.30 --output .build/carrier-metadata/v9.0.30
    swift scripts/updateCarrierMetadata.swift 9.0.30 --replace-bundle
    swift scripts/updateCarrierMetadata.swift --source /tmp/libphonenumber --dry-run
  """
}

func parseArguments(_ arguments: [String]) throws -> Options {
  var options = Options()
  var index = 1

  while index < arguments.count {
    let argument = arguments[index]
    switch argument {
    case "-h", "--help":
      print(usage())
      exit(0)
    case "--source":
      index += 1
      guard index < arguments.count else { throw ScriptError.invalidArguments("--source requires a path") }
      options.sourceDirectory = absoluteURL(forPath: arguments[index])
    case "--output", "-o":
      index += 1
      guard index < arguments.count else { throw ScriptError.invalidArguments("\(argument) requires a path") }
      options.outputDirectory = absoluteURL(forPath: arguments[index])
    case "--replace-bundle":
      options.replaceBundle = true
    case "--dry-run":
      options.dryRun = true
    case "--keep-temp":
      options.keepTemporaryFiles = true
    default:
      if argument.hasPrefix("-") {
        throw ScriptError.invalidArguments("Unknown argument: \(argument)\n\n\(usage())")
      } else if options.ref == nil {
        options.ref = argument
      } else {
        throw ScriptError.invalidArguments("Unexpected extra argument: \(argument)\n\n\(usage())")
      }
    }
    index += 1
  }

  if options.ref == nil && options.sourceDirectory == nil {
    throw ScriptError.invalidArguments("Must specify a ref or --source.\n\n\(usage())")
  }
  if options.ref != nil && options.sourceDirectory != nil {
    throw ScriptError.invalidArguments("Specify either a ref or --source, not both.\n\n\(usage())")
  }
  return options
}

func absoluteURL(forPath path: String) -> URL {
  if path.hasPrefix("/") {
    return URL(fileURLWithPath: path).standardizedFileURL
  }
  return URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    .appendingPathComponent(path)
    .standardizedFileURL
}

func isNumericVersion(_ value: String) -> Bool {
  value.range(of: #"^\d+(\.\d+){0,2}$"#, options: .regularExpression) != nil
}

func normalizedGitRef(_ value: String) -> String {
  let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
  if isNumericVersion(trimmed) {
    return "v\(trimmed)"
  }
  if trimmed.hasPrefix("v") && isNumericVersion(String(trimmed.dropFirst())) {
    return trimmed
  }
  return trimmed
}

func ensureTool(_ path: String) throws {
  guard FileManager.default.isExecutableFile(atPath: path) else {
    throw ScriptError.missingTool(path)
  }
}

@discardableResult
func runProcess(_ executable: String, _ arguments: [String]) throws -> Data {
  let process = Process()
  process.executableURL = URL(fileURLWithPath: executable)
  process.arguments = arguments

  let standardOutput = Pipe()
  let standardError = Pipe()
  process.standardOutput = standardOutput
  process.standardError = standardError

  try process.run()
  let output = standardOutput.fileHandleForReading.readDataToEndOfFile()
  let errorOutput = standardError.fileHandleForReading.readDataToEndOfFile()
  process.waitUntilExit()

  guard process.terminationStatus == 0 else {
    let errorText = String(data: errorOutput, encoding: .utf8) ?? "unknown error"
    throw ScriptError.processFailed("\(executable) \(arguments.joined(separator: " ")) failed: \(errorText)")
  }
  return output
}

func downloadArchive(ref: String, to temporaryDirectory: URL) throws -> URL {
  let archiveURL = URL(string: "https://github.com/google/libphonenumber/archive/\(ref).zip")!
  let outputURL = temporaryDirectory.appendingPathComponent("libphonenumber-\(ref).zip")

  print("Downloading \(archiveURL.absoluteString)")

  let semaphore = DispatchSemaphore(value: 0)
  var resultData: Data?
  var resultResponse: URLResponse?
  var resultError: Error?

  var request = URLRequest(url: archiveURL)
  request.timeoutInterval = 120
  request.setValue("libPhoneNumber-iOS updateCarrierMetadata", forHTTPHeaderField: "User-Agent")

  let task = URLSession.shared.dataTask(with: request) { data, response, error in
    resultData = data
    resultResponse = response
    resultError = error
    semaphore.signal()
  }
  task.resume()
  semaphore.wait()

  if let resultError {
    throw ScriptError.downloadFailed(archiveURL, resultError.localizedDescription)
  }
  guard let httpResponse = resultResponse as? HTTPURLResponse else {
    throw ScriptError.invalidResponse(archiveURL)
  }
  guard (200...299).contains(httpResponse.statusCode), let resultData else {
    throw ScriptError.downloadFailed(archiveURL, "HTTP \(httpResponse.statusCode)")
  }

  try resultData.write(to: outputURL, options: .atomic)
  return outputURL
}

func unzipArchive(_ archiveURL: URL, to destinationURL: URL) throws -> URL {
  try runProcess("/usr/bin/unzip", ["-q", archiveURL.path, "-d", destinationURL.path])
  let children = try FileManager.default.contentsOfDirectory(
    at: destinationURL,
    includingPropertiesForKeys: [.isDirectoryKey],
    options: [.skipsHiddenFiles]
  )
  let directories = try children.filter { url in
    let values = try url.resourceValues(forKeys: [.isDirectoryKey])
    return values.isDirectory == true
  }
  guard let root = directories.first(where: { $0.lastPathComponent.hasPrefix("libphonenumber-") })
    ?? directories.first else {
    throw ScriptError.missingCarrierDirectory(destinationURL)
  }
  return root
}

func carrierDirectory(from source: URL) throws -> URL {
  let resourceCarrier = source.appendingPathComponent("resources/carrier")
  if FileManager.default.fileExists(atPath: resourceCarrier.path) {
    return resourceCarrier
  }

  let children = (try? FileManager.default.contentsOfDirectory(
    at: source,
    includingPropertiesForKeys: [.isDirectoryKey],
    options: [.skipsHiddenFiles]
  )) ?? []
  if children.contains(where: { child in
    ((try? child.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false) == true
  }) {
    return source
  }

  throw ScriptError.missingCarrierDirectory(source)
}

func phoneMetadataXML(from source: URL) throws -> URL {
  let direct = source.appendingPathComponent("resources/PhoneNumberMetadata.xml")
  if FileManager.default.fileExists(atPath: direct.path) {
    return direct
  }

  let carrierSibling = source.deletingLastPathComponent()
  let siblingXML = carrierSibling.appendingPathComponent("PhoneNumberMetadata.xml")
  if FileManager.default.fileExists(atPath: siblingXML.path) {
    return siblingXML
  }

  throw ScriptError.missingPhoneMetadataXML(source)
}

func reviewOutputDirectory(for options: Options, refOrSourceName: String) -> URL {
  if let outputDirectory = options.outputDirectory {
    return outputDirectory
  }
  return repositoryRoot
    .appendingPathComponent(".build/carrier-metadata")
    .appendingPathComponent(refOrSourceName)
}

func parseCarrierEntries(from carrierDirectory: URL) throws -> [CarrierEntry] {
  let localeDirectories = try FileManager.default.contentsOfDirectory(
    at: carrierDirectory,
    includingPropertiesForKeys: [.isDirectoryKey],
    options: [.skipsHiddenFiles]
  )
    .filter { ((try? $0.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false) == true }
    .sorted { $0.lastPathComponent < $1.lastPathComponent }

  var entries: [CarrierEntry] = []
  var seenKeys = Set<String>()

  for localeDirectory in localeDirectories {
    let locale = localeDirectory.lastPathComponent
    let files = try FileManager.default.contentsOfDirectory(
      at: localeDirectory,
      includingPropertiesForKeys: nil,
      options: [.skipsHiddenFiles]
    )
      .filter { $0.pathExtension.lowercased() == "txt" }
      .sorted { $0.lastPathComponent < $1.lastPathComponent }

    for file in files {
      let text = try String(contentsOf: file, encoding: .utf8)
      for (offset, line) in text.components(separatedBy: .newlines).enumerated() {
        let lineNumber = offset + 1
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty || trimmed.hasPrefix("#") {
          continue
        }

        let parts = trimmed.split(separator: "|", omittingEmptySubsequences: false)
        guard parts.count == 2 else {
          throw ScriptError.invalidMetadataFile(file, lineNumber, "expected prefix|carrier-name")
        }

        let prefix = String(parts[0])
        let carrierName = String(parts[1]).trimmingCharacters(in: .whitespacesAndNewlines)
        guard prefix.range(of: #"^[0-9]+$"#, options: .regularExpression) != nil else {
          throw ScriptError.invalidMetadataFile(file, lineNumber, "prefix must contain digits only")
        }
        guard !carrierName.isEmpty else {
          throw ScriptError.invalidMetadataFile(file, lineNumber, "carrier name must not be empty")
        }

        let key = "\(locale)|\(prefix)"
        guard seenKeys.insert(key).inserted else {
          throw ScriptError.invalidMetadataFile(file, lineNumber, "duplicate locale/prefix \(key)")
        }

        entries.append(CarrierEntry(locale: locale, prefix: prefix, carrierName: carrierName))
      }
    }
  }

  return entries.sorted { lhs, rhs in
    if lhs.locale != rhs.locale {
      return lhs.locale < rhs.locale
    }
    if lhs.prefix.count != rhs.prefix.count {
      return lhs.prefix.count < rhs.prefix.count
    }
    return lhs.prefix < rhs.prefix
  }
}

func parseMobilePortableRegions(from metadataXML: URL) throws -> [String] {
  let text = try String(contentsOf: metadataXML, encoding: .utf8)
  let pattern = #"<territory\b[^>]*\bid=\"([A-Z]{2}|001)\"[^>]*\bmobileNumberPortableRegion=\"true\""#
  let regex = try NSRegularExpression(pattern: pattern)
  let nsRange = NSRange(text.startIndex..<text.endIndex, in: text)
  let matches = regex.matches(in: text, range: nsRange)
  let regions = matches.compactMap { match -> String? in
    guard let range = Range(match.range(at: 1), in: text) else {
      return nil
    }
    return String(text[range])
  }
  return Array(Set(regions)).sorted()
}

func sha256ForDirectory(_ directory: URL) throws -> String {
  let files = try FileManager.default.contentsOfDirectory(
    at: directory,
    includingPropertiesForKeys: [.isRegularFileKey],
    options: [.skipsHiddenFiles]
  )
  let allFiles = try files.flatMap { url -> [URL] in
    let values = try url.resourceValues(forKeys: [.isDirectoryKey, .isRegularFileKey])
    if values.isRegularFile == true {
      return [url]
    }
    if values.isDirectory == true {
      return try FileManager.default.contentsOfDirectory(
        at: url,
        includingPropertiesForKeys: [.isRegularFileKey],
        options: [.skipsHiddenFiles]
      ).filter { ($0.pathExtension.lowercased() == "txt") }
    }
    return []
  }.sorted { $0.path < $1.path }

  var data = Data()
  for file in allFiles {
    data.append(file.path.replacingOccurrences(of: directory.path, with: "").data(using: .utf8)!)
    data.append(0)
    data.append(try Data(contentsOf: file))
    data.append(0)
  }
  return try sha256(data)
}

func sha256ForFiles(_ files: [URL]) throws -> String {
  var data = Data()
  for file in files.sorted(by: { $0.path < $1.path }) {
    data.append(file.path.data(using: .utf8)!)
    data.append(0)
    data.append(try Data(contentsOf: file))
    data.append(0)
  }
  return try sha256(data)
}

func sha256(_ data: Data) throws -> String {
  let process = Process()
  process.executableURL = URL(fileURLWithPath: "/usr/bin/shasum")
  process.arguments = ["-a", "256"]

  let input = Pipe()
  let standardOutput = Pipe()
  process.standardInput = input
  process.standardOutput = standardOutput

  try process.run()
  input.fileHandleForWriting.write(data)
  input.fileHandleForWriting.closeFile()
  let digestData = standardOutput.fileHandleForReading.readDataToEndOfFile()
  process.waitUntilExit()

  guard process.terminationStatus == 0,
        let digestLine = String(data: digestData, encoding: .utf8),
        let digest = digestLine.split(separator: " ").first else {
    throw ScriptError.processFailed("shasum -a 256 failed")
  }
  return String(digest)
}

func sqlEscaped(_ value: String) -> String {
  "'\(value.replacingOccurrences(of: "'", with: "''"))'"
}

func generateDatabase(
  entries: [CarrierEntry],
  mobilePortableRegions: [String],
  outputDirectory: URL,
  upstreamRef: String,
  sourceSHA256: String,
  dryRun: Bool
) throws {
  let databaseURL = outputDirectory.appendingPathComponent("carriers.db")

  if dryRun {
    print("  would generate \(databaseURL.path)")
    return
  }

  try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)
  if FileManager.default.fileExists(atPath: databaseURL.path) {
    try FileManager.default.removeItem(at: databaseURL)
  }

  var sql = """
  PRAGMA journal_mode=OFF;
  PRAGMA synchronous=OFF;
  BEGIN TRANSACTION;
  CREATE TABLE metadata_info (
    key TEXT PRIMARY KEY NOT NULL,
    value TEXT NOT NULL
  );
  CREATE TABLE carrier_prefixes (
    locale TEXT NOT NULL,
    prefix TEXT NOT NULL,
    carrier_name TEXT NOT NULL,
    PRIMARY KEY (locale, prefix)
  );
  CREATE INDEX carrier_prefixes_lookup ON carrier_prefixes(locale, prefix);
  CREATE TABLE mobile_portable_regions (
    region_code TEXT PRIMARY KEY NOT NULL
  );

  """
  sql += "INSERT INTO metadata_info (key, value) VALUES ('schema_version', '1');\n"
  sql += "INSERT INTO metadata_info (key, value) VALUES ('upstream_ref', \(sqlEscaped(upstreamRef)));\n"
  sql += "INSERT INTO metadata_info (key, value) VALUES ('source_path', 'resources/carrier');\n"
  sql += "INSERT INTO metadata_info (key, value) VALUES ('source_sha256', \(sqlEscaped(sourceSHA256)));\n"
  sql += "INSERT INTO metadata_info (key, value) VALUES ('row_count', '\(entries.count)');\n"
  sql += "INSERT INTO metadata_info (key, value) VALUES ('mobile_portable_region_count', '\(mobilePortableRegions.count)');\n"
  for entry in entries {
    sql += "INSERT INTO carrier_prefixes (locale, prefix, carrier_name) VALUES (\(sqlEscaped(entry.locale)), \(sqlEscaped(entry.prefix)), \(sqlEscaped(entry.carrierName)));\n"
  }
  for region in mobilePortableRegions {
    sql += "INSERT INTO mobile_portable_regions (region_code) VALUES (\(sqlEscaped(region)));\n"
  }
  sql += "COMMIT;\n"

  let sqlURL = outputDirectory.appendingPathComponent("carriers.sql")
  try sql.write(to: sqlURL, atomically: true, encoding: .utf8)
  defer { try? FileManager.default.removeItem(at: sqlURL) }

  try runProcess("/usr/bin/sqlite3", [databaseURL.path, ".read \(sqlURL.path)"])
}

func writeArtifacts(
  entries: [CarrierEntry],
  mobilePortableRegions: [String],
  carrierDirectory: URL,
  phoneMetadataXML: URL,
  outputDirectory: URL,
  upstreamRef: String,
  dryRun: Bool
) throws {
  let carrierDigest = try sha256ForDirectory(carrierDirectory)
  let sourceDigest = try sha256ForFiles([phoneMetadataXML]) + ":\(carrierDigest)"
  let localeCounts = Dictionary(grouping: entries, by: \.locale).mapValues(\.count)
  let artifact = CarrierArtifact(
    schemaVersion: 1,
    upstreamRef: upstreamRef,
    sourcePath: "resources/carrier",
    sourceSHA256: sourceDigest,
    entryCount: entries.count,
    mobilePortableRegionCount: mobilePortableRegions.count,
    mobilePortableRegions: mobilePortableRegions,
    localeCounts: localeCounts,
    entries: entries
  )

  let encoder = JSONEncoder()
  encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
  let jsonData = try encoder.encode(artifact)
  let rawBytes = try rawSourceBytes(carrierDirectory)

  let sizeReport = """
  # Carrier Metadata Size Report

  - Upstream ref: `\(upstreamRef)`
  - Source: `resources/carrier`
  - Source SHA-256: `\(sourceDigest)`
  - Source bytes: \(rawBytes)
  - Parsed rows: \(entries.count)
  - Mobile portable regions: \(mobilePortableRegions.count)
  - Locales: \(localeCounts.keys.sorted().joined(separator: ", "))
  - Review JSON bytes: \(jsonData.count)

  ## Rows By Locale

  \(localeCounts.keys.sorted().map { "- `\($0)`: \(localeCounts[$0] ?? 0)" }.joined(separator: "\n"))
  """

  let logCandidate = """
  ## Carrier Metadata Candidate - \(upstreamRef)

  - Source: Google libphonenumber `resources/carrier`
  - Source SHA-256: `\(sourceDigest)`
  - Source bytes: \(rawBytes)
  - Parsed rows: \(entries.count)
  - Mobile portable regions: \(mobilePortableRegions.count)
  - Locales: \(localeCounts.keys.sorted().joined(separator: ", "))
  - Review artifact: `carrier-prefixes.json`
  """

  print("Carrier metadata parsed: \(entries.count) rows, \(localeCounts.count) locales")
  print("Mobile portable regions parsed: \(mobilePortableRegions.count)")
  print("Source bytes: \(rawBytes)")
  print("Review JSON bytes: \(jsonData.count)")

  if dryRun {
    print("Dry run completed; no files written.")
    return
  }

  try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)
  try jsonData.write(to: outputDirectory.appendingPathComponent("carrier-prefixes.json"), options: .atomic)
  try sizeReport.write(to: outputDirectory.appendingPathComponent("carrier-size-report.md"), atomically: true, encoding: .utf8)
  try logCandidate.write(to: outputDirectory.appendingPathComponent("carrier-update-log-entry.md"), atomically: true, encoding: .utf8)
  print("Wrote \(outputDirectory.path)")
}

func rawSourceBytes(_ directory: URL) throws -> Int {
  let files = try FileManager.default.subpathsOfDirectory(atPath: directory.path)
  return try files.reduce(0) { total, relativePath in
    let url = directory.appendingPathComponent(relativePath)
    guard url.pathExtension.lowercased() == "txt" else {
      return total
    }
    return total + (try Data(contentsOf: url)).count
  }
}

func main() throws {
  try ensureTool("/usr/bin/unzip")
  try ensureTool("/usr/bin/shasum")
  try ensureTool("/usr/bin/sqlite3")

  let options = try parseArguments(CommandLine.arguments)
  let temporaryDirectory = FileManager.default.temporaryDirectory
    .appendingPathComponent("libPhoneNumber-carrier-\(UUID().uuidString)", isDirectory: true)
  try FileManager.default.createDirectory(at: temporaryDirectory, withIntermediateDirectories: true)
  defer {
    if !options.keepTemporaryFiles {
      try? FileManager.default.removeItem(at: temporaryDirectory)
    }
  }

  let sourceRoot: URL
  let refOrSourceName: String
  if let sourceDirectory = options.sourceDirectory {
    sourceRoot = sourceDirectory
    refOrSourceName = sourceDirectory.lastPathComponent.isEmpty ? "source" : sourceDirectory.lastPathComponent
  } else {
    let ref = normalizedGitRef(options.ref!)
    let archiveURL = try downloadArchive(ref: ref, to: temporaryDirectory)
    sourceRoot = try unzipArchive(archiveURL, to: temporaryDirectory)
    refOrSourceName = ref.replacingOccurrences(of: "/", with: "-")
  }

  let carrierSource = try carrierDirectory(from: sourceRoot)
  let metadataXML = try phoneMetadataXML(from: sourceRoot)
  let entries = try parseCarrierEntries(from: carrierSource)
  let mobilePortableRegions = try parseMobilePortableRegions(from: metadataXML)
  let upstreamRef = options.ref.map(normalizedGitRef) ?? "source:\(sourceRoot.path)"
  let sourceDigest = try sha256ForFiles([metadataXML]) + ":\(try sha256ForDirectory(carrierSource))"
  let reviewOutputURL = reviewOutputDirectory(for: options, refOrSourceName: refOrSourceName)

  if options.replaceBundle {
    try generateDatabase(
      entries: entries,
      mobilePortableRegions: mobilePortableRegions,
      outputDirectory: bundleDirectory,
      upstreamRef: upstreamRef,
      sourceSHA256: sourceDigest,
      dryRun: options.dryRun
    )
  }

  try writeArtifacts(
    entries: entries,
    mobilePortableRegions: mobilePortableRegions,
    carrierDirectory: carrierSource,
    phoneMetadataXML: metadataXML,
    outputDirectory: reviewOutputURL,
    upstreamRef: upstreamRef,
    dryRun: options.dryRun
  )
}

do {
  try main()
} catch {
  fputs("error: \(error)\n", stderr)
  exit(1)
}
