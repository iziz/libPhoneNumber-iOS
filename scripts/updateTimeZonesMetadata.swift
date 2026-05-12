#!/usr/bin/swift

import Foundation

enum ScriptError: Error, CustomStringConvertible {
  case invalidArguments(String)
  case downloadFailed(URL, String)
  case invalidResponse(URL)
  case missingTool(String)
  case missingTimezonesDirectory(URL)
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
    case .missingTimezonesDirectory(let url):
      return "Could not find resources/timezones under \(url.path)"
    case .invalidMetadataFile(let url, let line, let message):
      return "Invalid timezone metadata file \(url.path):\(line): \(message)"
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

struct TimeZoneEntry: Codable {
  let prefix: String
  let timeZones: [String]
}

struct TimeZoneArtifact: Codable {
  let schemaVersion: Int
  let upstreamRef: String
  let sourcePath: String
  let sourceSHA256: String
  let entryCount: Int
  let entries: [TimeZoneEntry]
}

let scriptURL = absoluteURL(forPath: CommandLine.arguments[0])
let scriptsDirectory = scriptURL.deletingLastPathComponent()
let repositoryRoot = scriptsDirectory.deletingLastPathComponent()
let bundleDirectory = repositoryRoot
  .appendingPathComponent("libPhoneNumberTimeZonesMetaData/TimeZonesMetaData.bundle")

func usage() -> String {
  """
  Usage:
    swift scripts/updateTimeZonesMetadata.swift <version|master|ref> [--output <dir>] [--replace-bundle] [--dry-run]
    swift scripts/updateTimeZonesMetadata.swift --source <google-libphonenumber-dir-or-timezones-dir> [--output <dir>] [--replace-bundle] [--dry-run]

  Examples:
    swift scripts/updateTimeZonesMetadata.swift 9.0.30 --output .build/timezone-metadata/v9.0.30
    swift scripts/updateTimeZonesMetadata.swift 9.0.30 --replace-bundle
    swift scripts/updateTimeZonesMetadata.swift master --dry-run
    swift scripts/updateTimeZonesMetadata.swift --source /tmp/libphonenumber --output /tmp/timezones

  Notes:
    - Numeric versions are normalized to GitHub tags, e.g. 9.0.30 -> v9.0.30.
    - Without --output, artifacts are written to .build/timezone-metadata/<ref-or-source>.
    - --replace-bundle replaces libPhoneNumberTimeZonesMetaData/TimeZonesMetaData.bundle/timezones.db.
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
      guard index < arguments.count else {
        throw ScriptError.invalidArguments("--source requires a path")
      }
      options.sourceDirectory = absoluteURL(forPath: arguments[index])
    case "--output", "-o":
      index += 1
      guard index < arguments.count else {
        throw ScriptError.invalidArguments("\(argument) requires a path")
      }
      options.outputDirectory = absoluteURL(forPath: arguments[index])
    case "--dry-run":
      options.dryRun = true
    case "--replace-bundle":
      options.replaceBundle = true
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
  request.setValue("libPhoneNumber-iOS updateTimeZonesMetadata", forHTTPHeaderField: "User-Agent")

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
    throw ScriptError.missingTimezonesDirectory(destinationURL)
  }

  return root
}

func timezonesDirectory(from source: URL) throws -> URL {
  let resourceTimezones = source.appendingPathComponent("resources/timezones")
  if FileManager.default.fileExists(atPath: resourceTimezones.appendingPathComponent("map_data.txt").path) {
    return resourceTimezones
  }

  if FileManager.default.fileExists(atPath: source.appendingPathComponent("map_data.txt").path) {
    return source
  }

  throw ScriptError.missingTimezonesDirectory(source)
}

func reviewOutputDirectory(for options: Options, refOrSourceName: String) -> URL {
  if let outputDirectory = options.outputDirectory {
    return outputDirectory
  }

  return repositoryRoot
    .appendingPathComponent(".build/timezone-metadata")
    .appendingPathComponent(refOrSourceName)
}

func parseTimeZoneEntries(from mapDataURL: URL) throws -> [TimeZoneEntry] {
  let text = try String(contentsOf: mapDataURL, encoding: .utf8)
  var entries: [TimeZoneEntry] = []
  var seenPrefixes = Set<String>()

  for (offset, line) in text.components(separatedBy: .newlines).enumerated() {
    let lineNumber = offset + 1
    let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
    if trimmed.isEmpty || trimmed.hasPrefix("#") {
      continue
    }

    let parts = trimmed.split(separator: "|", omittingEmptySubsequences: false)
    guard parts.count == 2 else {
      throw ScriptError.invalidMetadataFile(mapDataURL, lineNumber, "expected prefix|timezone-list")
    }

    let prefix = String(parts[0])
    guard prefix.range(of: #"^[0-9]+$"#, options: .regularExpression) != nil else {
      throw ScriptError.invalidMetadataFile(mapDataURL, lineNumber, "prefix must contain digits only")
    }

    guard seenPrefixes.insert(prefix).inserted else {
      throw ScriptError.invalidMetadataFile(mapDataURL, lineNumber, "duplicate prefix \(prefix)")
    }

    let timeZones = parts[1]
      .split(separator: "&", omittingEmptySubsequences: false)
      .map(String.init)

    guard !timeZones.isEmpty else {
      throw ScriptError.invalidMetadataFile(mapDataURL, lineNumber, "timezone list must not be empty")
    }

    for timeZone in timeZones {
      guard timeZone.range(of: #"^[A-Za-z0-9_+\-./]+$"#, options: .regularExpression) != nil else {
        throw ScriptError.invalidMetadataFile(mapDataURL, lineNumber, "invalid timezone identifier \(timeZone)")
      }
    }

    entries.append(TimeZoneEntry(prefix: prefix, timeZones: timeZones))
  }

  return entries.sorted { lhs, rhs in
    if lhs.prefix.count == rhs.prefix.count {
      return lhs.prefix < rhs.prefix
    }
    return lhs.prefix.count < rhs.prefix.count
  }
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

func writeArtifacts(
  entries: [TimeZoneEntry],
  mapDataURL: URL,
  outputDirectory: URL,
  upstreamRef: String,
  dryRun: Bool
) throws {
  let sourceData = try Data(contentsOf: mapDataURL)
  let digest = try sha256(sourceData)
  let artifact = TimeZoneArtifact(
    schemaVersion: 1,
    upstreamRef: upstreamRef,
    sourcePath: "resources/timezones/map_data.txt",
    sourceSHA256: digest,
    entryCount: entries.count,
    entries: entries
  )

  let encoder = JSONEncoder()
  encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
  let jsonData = try encoder.encode(artifact)

  let uniqueZones = Set(entries.flatMap(\.timeZones)).sorted()
  let multipleZoneEntryCount = entries.filter { $0.timeZones.count > 1 }.count
  let longestPrefixLength = entries.map { $0.prefix.count }.max() ?? 0

  let sizeReport = """
  # Timezone Metadata Size Report

  - Upstream ref: `\(upstreamRef)`
  - Source: `resources/timezones/map_data.txt`
  - Source SHA-256: `\(digest)`
  - Source bytes: \(sourceData.count)
  - Parsed rows: \(entries.count)
  - Unique timezone IDs: \(uniqueZones.count)
  - Rows with multiple timezone IDs: \(multipleZoneEntryCount)
  - Longest prefix length: \(longestPrefixLength)
  - Review JSON bytes: \(jsonData.count)

  ## Sample Timezone IDs

  \(uniqueZones.prefix(20).map { "- `\($0)`" }.joined(separator: "\n"))
  """

  let logCandidate = """
  ## Timezone Metadata Candidate - \(upstreamRef)

  - Source: Google libphonenumber `resources/timezones/map_data.txt`
  - Source SHA-256: `\(digest)`
  - Source bytes: \(sourceData.count)
  - Parsed rows: \(entries.count)
  - Unique timezone IDs: \(uniqueZones.count)
  - Rows with multiple timezone IDs: \(multipleZoneEntryCount)
  - Review artifact: `timezone-prefixes.json`
  """

  print("Timezone metadata parsed: \(entries.count) rows, \(uniqueZones.count) unique timezone IDs")
  print("Source bytes: \(sourceData.count)")
  print("Review JSON bytes: \(jsonData.count)")

  if dryRun {
    print("Dry run completed; no files written.")
    return
  }

  try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)
  try jsonData.write(to: outputDirectory.appendingPathComponent("timezone-prefixes.json"), options: .atomic)
  try sizeReport.write(to: outputDirectory.appendingPathComponent("timezone-size-report.md"), atomically: true, encoding: .utf8)
  try logCandidate.write(to: outputDirectory.appendingPathComponent("timezone-update-log-entry.md"), atomically: true, encoding: .utf8)

  print("Wrote \(outputDirectory.path)")
}

func sqlEscaped(_ value: String) -> String {
  "'\(value.replacingOccurrences(of: "'", with: "''"))'"
}

func generateDatabase(
  entries: [TimeZoneEntry],
  outputDirectory: URL,
  upstreamRef: String,
  sourceSHA256: String,
  dryRun: Bool
) throws -> URL {
  let databaseURL = outputDirectory.appendingPathComponent("timezones.db")

  if dryRun {
    print("  would generate \(databaseURL.path)")
    return databaseURL
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
  CREATE TABLE timezone_prefixes (
    prefix TEXT PRIMARY KEY NOT NULL,
    time_zones TEXT NOT NULL
  );
  CREATE INDEX timezone_prefixes_lookup ON timezone_prefixes(prefix);

  """

  sql += "INSERT INTO metadata_info (key, value) VALUES ('schema_version', '1');\n"
  sql += "INSERT INTO metadata_info (key, value) VALUES ('upstream_ref', \(sqlEscaped(upstreamRef)));\n"
  sql += "INSERT INTO metadata_info (key, value) VALUES ('source_path', 'resources/timezones/map_data.txt');\n"
  sql += "INSERT INTO metadata_info (key, value) VALUES ('source_sha256', \(sqlEscaped(sourceSHA256)));\n"
  sql += "INSERT INTO metadata_info (key, value) VALUES ('row_count', '\(entries.count)');\n"

  for entry in entries {
    sql += "INSERT INTO timezone_prefixes (prefix, time_zones) VALUES (\(sqlEscaped(entry.prefix)), \(sqlEscaped(entry.timeZones.joined(separator: "&"))));\n"
  }
  sql += "COMMIT;\n"

  let sqlURL = outputDirectory.appendingPathComponent("timezones.sql")
  try sql.write(to: sqlURL, atomically: true, encoding: .utf8)
  defer { try? FileManager.default.removeItem(at: sqlURL) }

  try runProcess("/usr/bin/sqlite3", [databaseURL.path, ".read \(sqlURL.path)"])
  return databaseURL
}

func main() throws {
  try ensureTool("/usr/bin/unzip")
  try ensureTool("/usr/bin/shasum")
  try ensureTool("/usr/bin/sqlite3")

  let options = try parseArguments(CommandLine.arguments)
  let temporaryDirectory = FileManager.default.temporaryDirectory
    .appendingPathComponent("libPhoneNumber-timezones-\(UUID().uuidString)", isDirectory: true)
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

  let timezonesDirectory = try timezonesDirectory(from: sourceRoot)
  let mapDataURL = timezonesDirectory.appendingPathComponent("map_data.txt")
  let upstreamRef = options.ref.map(normalizedGitRef) ?? "source:\(sourceRoot.path)"
  let entries = try parseTimeZoneEntries(from: mapDataURL)
  let sourceDigest = try sha256(try Data(contentsOf: mapDataURL))
  let reviewOutputURL = reviewOutputDirectory(for: options, refOrSourceName: refOrSourceName)

  if options.replaceBundle {
    _ = try generateDatabase(
      entries: entries,
      outputDirectory: bundleDirectory,
      upstreamRef: upstreamRef,
      sourceSHA256: sourceDigest,
      dryRun: options.dryRun
    )
  }

  try writeArtifacts(
    entries: entries,
    mapDataURL: mapDataURL,
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
