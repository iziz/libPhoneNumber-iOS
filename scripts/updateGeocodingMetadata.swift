#!/usr/bin/swift

import Foundation

enum ScriptError: Error, CustomStringConvertible {
  case invalidArguments(String)
  case missingTool(String)
  case downloadFailed(URL, String)
  case invalidResponse(URL)
  case missingGeocodingDirectory(URL)
  case processFailed(String)
  case invalidMetadataFile(URL)

  var description: String {
    switch self {
    case .invalidArguments(let message):
      return message
    case .missingTool(let tool):
      return "Required tool not found: \(tool)"
    case .downloadFailed(let url, let message):
      return "Failed to download \(url.absoluteString): \(message)"
    case .invalidResponse(let url):
      return "Unexpected response while downloading \(url.absoluteString)"
    case .missingGeocodingDirectory(let url):
      return "Could not find resources/geocoding under \(url.path)"
    case .processFailed(let message):
      return message
    case .invalidMetadataFile(let url):
      return "Invalid geocoding metadata file: \(url.path)"
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

struct MetadataEntry {
  let nationalNumber: String
  let description: String
}

let scriptURL = absoluteURL(forPath: CommandLine.arguments[0])
let scriptsDirectory = scriptURL.deletingLastPathComponent()
let repositoryRoot = scriptsDirectory.deletingLastPathComponent()
let bundleDirectory = repositoryRoot
  .appendingPathComponent("libPhoneNumberGeocodingMetaData/GeocodingMetaData.bundle")

func usage() -> String {
  """
  Usage:
    ./scripts/updateGeocodingMetadata.swift <version|master|ref> [--output <dir>] [--replace-bundle] [--dry-run]
    ./scripts/updateGeocodingMetadata.swift --source <google-libphonenumber-dir-or-geocoding-dir> [--output <dir>] [--replace-bundle]

  Examples:
    ./scripts/updateGeocodingMetadata.swift 9.0.29 --replace-bundle
    ./scripts/updateGeocodingMetadata.swift v9.0.29 --output /tmp/geocoding
    ./scripts/updateGeocodingMetadata.swift master --dry-run
    ./scripts/updateGeocodingMetadata.swift --source /tmp/libphonenumber --output /tmp/geocoding

  Notes:
    - Numeric versions are normalized to GitHub tags, e.g. 9.0.29 -> v9.0.29.
    - Without --replace-bundle, output defaults to .build/geocoding-metadata/<ref-or-source>.
    - --replace-bundle replaces libPhoneNumberGeocodingMetaData/GeocodingMetaData.bundle/*.db.
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

func shellEscaped(_ value: String) -> String {
  "'\(value.replacingOccurrences(of: "'", with: "''"))'"
}

func tableName(for countryCode: String) throws -> String {
  guard countryCode.range(of: #"^\d+$"#, options: .regularExpression) != nil else {
    throw ScriptError.invalidArguments("Invalid country calling code in geocoding metadata: \(countryCode)")
  }
  return "geocodingpairs\(countryCode)"
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
  request.setValue("libPhoneNumber-iOS updateGeocodingMetadata", forHTTPHeaderField: "User-Agent")

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
    throw ScriptError.missingGeocodingDirectory(destinationURL)
  }

  return root
}

func geocodingDirectory(from source: URL) throws -> URL {
  let resourceGeocoding = source.appendingPathComponent("resources/geocoding")
  if FileManager.default.fileExists(atPath: resourceGeocoding.path) {
    return resourceGeocoding
  }

  let directChildren = try? FileManager.default.contentsOfDirectory(
    at: source,
    includingPropertiesForKeys: [.isDirectoryKey],
    options: [.skipsHiddenFiles]
  )

  if let directChildren, directChildren.contains(where: { child in
    var isDirectory: ObjCBool = false
    guard FileManager.default.fileExists(atPath: child.path, isDirectory: &isDirectory),
          isDirectory.boolValue else {
      return false
    }
    let textFiles = (try? FileManager.default.contentsOfDirectory(atPath: child.path)) ?? []
    return textFiles.contains { $0.hasSuffix(".txt") }
  }) {
    return source
  }

  throw ScriptError.missingGeocodingDirectory(source)
}

func outputDirectory(for options: Options, refOrSourceName: String) -> URL {
  if let outputDirectory = options.outputDirectory {
    return outputDirectory
  }

  if options.replaceBundle {
    return bundleDirectory
  }

  return repositoryRoot
    .appendingPathComponent(".build/geocoding-metadata")
    .appendingPathComponent(refOrSourceName)
}

func parseMetadataFile(_ url: URL) throws -> [MetadataEntry] {
  guard let content = String(data: try Data(contentsOf: url), encoding: .utf8) else {
    throw ScriptError.invalidMetadataFile(url)
  }

  var entries: [MetadataEntry] = []
  for line in content.components(separatedBy: .newlines) {
    let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
    if trimmed.isEmpty || trimmed.hasPrefix("#") {
      continue
    }

    let parts = trimmed.components(separatedBy: "|")
    guard parts.count == 2 else {
      continue
    }

    entries.append(MetadataEntry(
      nationalNumber: parts[0].trimmingCharacters(in: .whitespacesAndNewlines),
      description: parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
    ))
  }

  return entries
}

func sqlForMetadataFile(_ fileURL: URL, countryCode: String) throws -> String {
  let table = try tableName(for: countryCode)
  let indexName = "nationalNumberIndex\(countryCode)"
  let entries = try parseMetadataFile(fileURL)

  var lines: [String] = [
    "CREATE TABLE IF NOT EXISTS \(table) (",
    "ID INTEGER PRIMARY KEY AUTOINCREMENT,",
    "NATIONALNUMBER TEXT,",
    "DESCRIPTION TEXT);",
    "CREATE INDEX IF NOT EXISTS \(indexName) ON \(table)(NATIONALNUMBER);"
  ]

  for entry in entries {
    lines.append("INSERT INTO \(table) (NATIONALNUMBER, DESCRIPTION) VALUES (\(shellEscaped(entry.nationalNumber)), \(shellEscaped(entry.description)));")
  }

  return lines.joined(separator: "\n")
}

func generateDatabase(languageDirectory: URL, outputDirectory: URL, dryRun: Bool) throws -> Int {
  let language = languageDirectory.lastPathComponent
  let databaseURL = outputDirectory.appendingPathComponent("\(language).db")
  let files = try FileManager.default.contentsOfDirectory(
    at: languageDirectory,
    includingPropertiesForKeys: nil,
    options: [.skipsHiddenFiles]
  )
    .filter { $0.pathExtension.lowercased() == "txt" }
    .sorted { $0.lastPathComponent < $1.lastPathComponent }

  if dryRun {
    print("  would generate \(databaseURL.path) from \(files.count) files")
    return files.count
  }

  if FileManager.default.fileExists(atPath: databaseURL.path) {
    try FileManager.default.removeItem(at: databaseURL)
  }

  var sql = "PRAGMA journal_mode=OFF;\nPRAGMA synchronous=OFF;\nBEGIN TRANSACTION;\n"
  for file in files {
    let countryCode = file.deletingPathExtension().lastPathComponent
    sql += try sqlForMetadataFile(file, countryCode: countryCode)
    sql += "\n"
  }
  sql += "COMMIT;\n"

  let sqlURL = outputDirectory.appendingPathComponent("\(language).sql")
  try sql.write(to: sqlURL, atomically: true, encoding: .utf8)
  defer { try? FileManager.default.removeItem(at: sqlURL) }

  try runProcess("/usr/bin/sqlite3", [databaseURL.path, ".read \(sqlURL.path)"])
  return files.count
}

func removeExistingDatabases(in directory: URL, dryRun: Bool) throws {
  guard FileManager.default.fileExists(atPath: directory.path) else {
    return
  }

  let databases = try FileManager.default.contentsOfDirectory(
    at: directory,
    includingPropertiesForKeys: nil,
    options: [.skipsHiddenFiles]
  ).filter { $0.pathExtension == "db" }

  for database in databases {
    if dryRun {
      print("  would remove \(database.path)")
    } else {
      try FileManager.default.removeItem(at: database)
    }
  }
}

func generateDatabases(from geocodingDirectory: URL, to outputDirectory: URL, replaceBundle: Bool, dryRun: Bool) throws {
  print("Reading geocoding metadata from \(geocodingDirectory.path)")
  print("\(dryRun ? "Dry run output" : "Writing output") to \(outputDirectory.path)")

  if dryRun {
    print("  would create \(outputDirectory.path)")
  } else {
    try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)
  }

  if replaceBundle {
    try removeExistingDatabases(in: outputDirectory, dryRun: dryRun)
  }

  let languageDirectories = try FileManager.default.contentsOfDirectory(
    at: geocodingDirectory,
    includingPropertiesForKeys: [.isDirectoryKey],
    options: [.skipsHiddenFiles]
  )
    .filter { url in
      let values = try? url.resourceValues(forKeys: [.isDirectoryKey])
      return values?.isDirectory == true
    }
    .sorted { $0.lastPathComponent < $1.lastPathComponent }

  var generatedDatabaseCount = 0
  var sourceFileCount = 0

  for languageDirectory in languageDirectories {
    let fileCount = try generateDatabase(
      languageDirectory: languageDirectory,
      outputDirectory: outputDirectory,
      dryRun: dryRun
    )
    sourceFileCount += fileCount
    generatedDatabaseCount += 1
    print("  \(dryRun ? "would generate" : "generated") \(languageDirectory.lastPathComponent).db from \(fileCount) files")
  }

  print("Geocoding metadata \(dryRun ? "dry run completed" : "updated"): \(generatedDatabaseCount) databases, \(sourceFileCount) source files")
}

func main() throws {
  try ensureTool("/usr/bin/sqlite3")
  try ensureTool("/usr/bin/unzip")

  let options = try parseArguments(CommandLine.arguments)
  let temporaryDirectory = FileManager.default.temporaryDirectory
    .appendingPathComponent("libPhoneNumber-geocoding-\(UUID().uuidString)", isDirectory: true)
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

  let geocodingDirectory = try geocodingDirectory(from: sourceRoot)
  let outputURL = outputDirectory(for: options, refOrSourceName: refOrSourceName)
  try generateDatabases(
    from: geocodingDirectory,
    to: outputURL,
    replaceBundle: options.replaceBundle,
    dryRun: options.dryRun
  )
}

do {
  try main()
} catch {
  fputs("error: \(error)\n", stderr)
  exit(1)
}
