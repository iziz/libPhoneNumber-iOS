#!/usr/bin/swift

import Foundation

enum ScriptError: Error, CustomStringConvertible {
  case invalidArguments(String)
  case downloadFailed(URL, String)
  case invalidResponse(URL, String)
  case invalidUTF8(URL)
  case invalidJSON(String)
  case processFailed(String)

  var description: String {
    switch self {
    case .invalidArguments(let message):
      return message
    case .downloadFailed(let url, let message):
      return "Failed to download \(url.absoluteString): \(message)"
    case .invalidResponse(let url, let message):
      return "Unexpected response while downloading \(url.absoluteString): \(message)"
    case .invalidUTF8(let url):
      return "Downloaded data is not UTF-8: \(url.absoluteString)"
    case .invalidJSON(let message):
      return "Invalid JSON: \(message)"
    case .processFailed(let message):
      return message
    }
  }
}

struct Options {
  var currentRef: String?
  var outputDirectory: URL?
  var failOnUpdate = false
}

struct MetadataFile: CaseIterable {
  let displayName: String
  let remotePath: String

  static let phoneNumber = MetadataFile(
    displayName: "Phone number metadata",
    remotePath: "javascript/i18n/phonenumbers/metadata.js"
  )
  static let testing = MetadataFile(
    displayName: "Testing metadata",
    remotePath: "javascript/i18n/phonenumbers/metadatafortesting.js"
  )
  static let shortNumber = MetadataFile(
    displayName: "Short-number metadata",
    remotePath: "javascript/i18n/phonenumbers/shortnumbermetadata.js"
  )

  static let allCases: [MetadataFile] = [.phoneNumber, .testing, .shortNumber]
}

struct RemoteTag: Decodable {
  let name: String
}

struct GitHubObject: Decodable {
  let sha: String
  let type: String
  let url: String?
}

struct GitHubRefResponse: Decodable {
  let object: GitHubObject
}

struct GitHubTagResponse: Decodable {
  let object: GitHubObject
}

struct FileSummary {
  let file: MetadataFile
  let currentBytes: Int
  let latestBytes: Int
  let currentSHA256: String
  let latestSHA256: String

  var changed: Bool {
    currentSHA256 != latestSHA256
  }
}

let scriptURL = absoluteURL(forPath: CommandLine.arguments[0])
let scriptsDirectory = scriptURL.deletingLastPathComponent()
let repositoryRoot = scriptsDirectory.deletingLastPathComponent()

func usage() -> String {
  """
  Usage:
    swift scripts/checkMetadataFreshness.swift [--current-ref <ref>] [--output <dir>] [--fail-on-update]

  Examples:
    swift scripts/checkMetadataFreshness.swift
    swift scripts/checkMetadataFreshness.swift --current-ref v9.0.30
    swift scripts/checkMetadataFreshness.swift --output .build/metadata-freshness
    swift scripts/checkMetadataFreshness.swift --fail-on-update

  Notes:
    - Without --current-ref, the script reads the newest vX.Y.Z entry from docs/METADATA_UPDATE_LOG.md.
    - The script does not modify metadata. It writes review artifacts and candidate maintenance text.
    - With --fail-on-update, the script exits non-zero after writing artifacts when a newer tag exists.
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
    case "--current-ref":
      index += 1
      guard index < arguments.count else {
        throw ScriptError.invalidArguments("--current-ref requires a value")
      }
      options.currentRef = normalizedGitRef(arguments[index])
    case "--output", "-o":
      index += 1
      guard index < arguments.count else {
        throw ScriptError.invalidArguments("\(argument) requires a path")
      }
      options.outputDirectory = absoluteURL(forPath: arguments[index])
    case "--fail-on-update":
      options.failOnUpdate = true
    default:
      throw ScriptError.invalidArguments("Unknown argument: \(argument)\n\n\(usage())")
    }
    index += 1
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
  return trimmed
}

func versionParts(_ tag: String) -> [Int]? {
  let raw = tag.hasPrefix("v") ? String(tag.dropFirst()) : tag
  let parts = raw.split(separator: ".").compactMap { Int($0) }
  return parts.count == 3 ? parts : nil
}

func compareVersions(_ lhs: String, _ rhs: String) -> Bool {
  guard let left = versionParts(lhs), let right = versionParts(rhs) else {
    return lhs < rhs
  }
  return left.lexicographicallyPrecedes(right)
}

func latestRecordedMetadataRef() throws -> String {
  let logURL = repositoryRoot.appendingPathComponent("docs/METADATA_UPDATE_LOG.md")
  let text = try String(contentsOf: logURL, encoding: .utf8)
  let regex = try NSRegularExpression(pattern: #"Google libphonenumber `(v\d+\.\d+\.\d+)`|Google libphonenumber (v\d+\.\d+\.\d+)"#)
  let range = NSRange(text.startIndex..., in: text)
  guard let match = regex.firstMatch(in: text, range: range) else {
    throw ScriptError.invalidArguments("Could not infer current metadata ref from docs/METADATA_UPDATE_LOG.md. Pass --current-ref.")
  }
  for index in 1..<match.numberOfRanges {
    if let captureRange = Range(match.range(at: index), in: text) {
      return String(text[captureRange])
    }
  }
  throw ScriptError.invalidArguments("Could not infer current metadata ref from docs/METADATA_UPDATE_LOG.md. Pass --current-ref.")
}

func download(_ url: URL) throws -> Data {
  let semaphore = DispatchSemaphore(value: 0)
  var resultData: Data?
  var resultResponse: URLResponse?
  var resultError: Error?

  var request = URLRequest(url: url)
  request.timeoutInterval = 60
  request.setValue("libPhoneNumber-iOS checkMetadataFreshness", forHTTPHeaderField: "User-Agent")
  if url.host == "api.github.com" {
    request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
    request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
    if let token = githubAPIToken() {
      request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }
  }

  let task = URLSession.shared.dataTask(with: request) { data, response, error in
    resultData = data
    resultResponse = response
    resultError = error
    semaphore.signal()
  }
  task.resume()
  semaphore.wait()

  if let resultError {
    throw ScriptError.downloadFailed(url, resultError.localizedDescription)
  }
  guard let httpResponse = resultResponse as? HTTPURLResponse else {
    throw ScriptError.invalidResponse(url, "missing HTTP response")
  }
  guard (200..<300).contains(httpResponse.statusCode),
        let data = resultData else {
    throw ScriptError.invalidResponse(url, responseDiagnostics(httpResponse, data: resultData))
  }
  return data
}

func githubAPIToken() -> String? {
  let environment = ProcessInfo.processInfo.environment
  for key in ["GITHUB_TOKEN", "GH_TOKEN"] {
    if let token = environment[key]?.trimmingCharacters(in: .whitespacesAndNewlines),
       !token.isEmpty {
      return token
    }
  }
  return nil
}

func responseDiagnostics(_ response: HTTPURLResponse, data: Data?) -> String {
  var parts = ["HTTP \(response.statusCode)"]

  for header in ["X-RateLimit-Remaining", "X-RateLimit-Reset", "Retry-After", "X-GitHub-Request-Id"] {
    if let value = response.value(forHTTPHeaderField: header) {
      parts.append("\(header): \(value)")
    }
  }

  if let data, !data.isEmpty {
    if let body = String(data: data, encoding: .utf8) {
      let normalizedBody = body
        .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        .trimmingCharacters(in: .whitespacesAndNewlines)
      if !normalizedBody.isEmpty {
        let bodySnippet = normalizedBody.count > 500
          ? "\(normalizedBody.prefix(500))..."
          : normalizedBody
        parts.append("body: \(bodySnippet)")
      }
    } else {
      parts.append("body: \(data.count) non-UTF-8 bytes")
    }
  }

  return parts.joined(separator: "; ")
}

func latestUpstreamTag() throws -> String {
  let url = URL(string: "https://api.github.com/repos/google/libphonenumber/tags?per_page=100")!
  let data = try download(url)
  let tags = try JSONDecoder().decode([RemoteTag].self, from: data)
    .map(\.name)
    .filter { versionParts($0) != nil }
  guard let latest = tags.max(by: compareVersions) else {
    throw ScriptError.invalidJSON("No semantic libphonenumber tags found")
  }
  return latest
}

func isVersionTag(_ ref: String) -> Bool {
  ref.range(of: #"^v\d+\.\d+\.\d+$"#, options: .regularExpression) != nil
}

func resolvedRawGitRef(_ ref: String) throws -> String {
  guard isVersionTag(ref) else {
    return ref
  }

  let escapedRef = ref.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ref
  let refURL = URL(string: "https://api.github.com/repos/google/libphonenumber/git/ref/tags/\(escapedRef)")!
  let refResponse = try JSONDecoder().decode(GitHubRefResponse.self, from: download(refURL))

  guard refResponse.object.type == "tag",
        let tagURLString = refResponse.object.url,
        let tagURL = URL(string: tagURLString) else {
    return refResponse.object.sha
  }

  let tagResponse = try JSONDecoder().decode(GitHubTagResponse.self, from: download(tagURL))
  return tagResponse.object.type == "commit" ? tagResponse.object.sha : refResponse.object.sha
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

func sha256(_ data: Data, outputDirectory: URL, fileName: String) throws -> String {
  let fileURL = outputDirectory.appendingPathComponent(fileName)
  try data.write(to: fileURL)
  let output = try runProcess("/usr/bin/shasum", ["-a", "256", fileURL.path])
  guard let text = String(data: output, encoding: .utf8),
        let hash = text.split(separator: " ").first else {
    throw ScriptError.processFailed("Unable to parse shasum output for \(fileName)")
  }
  return String(hash)
}

func rawURL(ref: String, path: String) -> URL {
  URL(string: "https://raw.githubusercontent.com/google/libphonenumber/\(ref)/\(path)")!
}

func summarize(currentRef: String, latestRef: String, outputDirectory: URL) throws -> [FileSummary] {
  try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)
  let currentDownloadRef = try resolvedRawGitRef(currentRef)
  let latestDownloadRef = currentRef == latestRef ? currentDownloadRef : try resolvedRawGitRef(latestRef)
  return try MetadataFile.allCases.map { file in
    let currentData = try download(rawURL(ref: currentDownloadRef, path: file.remotePath))
    let latestData = try download(rawURL(ref: latestDownloadRef, path: file.remotePath))
    let safeName = file.remotePath.replacingOccurrences(of: "/", with: "_")
    return FileSummary(
      file: file,
      currentBytes: currentData.count,
      latestBytes: latestData.count,
      currentSHA256: try sha256(currentData, outputDirectory: outputDirectory, fileName: "\(currentRef)-\(safeName)"),
      latestSHA256: try sha256(latestData, outputDirectory: outputDirectory, fileName: "\(latestRef)-\(safeName)")
    )
  }
}

func writeArtifacts(currentRef: String, latestRef: String, summaries: [FileSummary], outputDirectory: URL) throws {
  let changed = summaries.filter(\.changed)
  let status = currentRef == latestRef ? "up to date" : "update available"
  let table = summaries.map { summary in
    "| \(summary.file.displayName) | \(summary.changed ? "changed" : "unchanged") | \(summary.currentBytes) | \(summary.latestBytes) | `\(summary.currentSHA256.prefix(12))` | `\(summary.latestSHA256.prefix(12))` |"
  }.joined(separator: "\n")

  let summaryText = """
  # Metadata Freshness Summary

  - Current local metadata ref: `\(currentRef)`
  - Latest upstream tag: `\(latestRef)`
  - Status: \(status)

  | File | Status | Current bytes | Latest bytes | Current SHA-256 | Latest SHA-256 |
  | --- | --- | ---: | ---: | --- | --- |
  \(table)

  Changed files: \(changed.count) / \(summaries.count)
  """

  let issueTemplate = """
  # Metadata update: \(currentRef) -> \(latestRef)

  ## Summary

  Google libphonenumber has a newer metadata tag available.

  - Current local metadata ref: `\(currentRef)`
  - Latest upstream tag: `\(latestRef)`
  - Changed metadata files: \(changed.count) / \(summaries.count)

  ## Update commands

  ```bash
  swift scripts/metadataGenerator.swift \(latestRef) --pretty
  swift scripts/updateGeocodingMetadata.swift \(latestRef) --replace-bundle
  swift scripts/checkUpstreamTestParity.swift --upstream-ref \(latestRef)
  swift scripts/checkUpstreamAPIParity.swift --upstream-ref \(latestRef)
  swift scripts/checkVersionConsistency.swift
  swift test
  LC_ALL=ko_KR.UTF-8 LANG=ko_KR.UTF-8 swift test
  swift build -c release
  git diff --check
  ```

  ## Review artifacts

  Attach or link `metadata-diff-summary.md` from this script output.
  """

  let prTemplate = """
  ## Metadata Update

  Updates Google libphonenumber metadata from `\(currentRef)` to `\(latestRef)`.

  ## Review Notes

  - Changed metadata files: \(changed.count) / \(summaries.count)
  - Main/test/short metadata diff summary generated by `scripts/checkMetadataFreshness.swift`.
  - Geocoding metadata should be reviewed via generated DB file list and local tests.

  ## Validation

  - [ ] `swift scripts/checkUpstreamTestParity.swift --upstream-ref \(latestRef)`
  - [ ] `swift scripts/checkUpstreamAPIParity.swift --upstream-ref \(latestRef)`
  - [ ] `swift scripts/checkVersionConsistency.swift`
  - [ ] `swift test`
  - [ ] `LC_ALL=ko_KR.UTF-8 LANG=ko_KR.UTF-8 swift test`
  - [ ] `swift build -c release`
  - [ ] `git diff --check`
  """

  let logCandidate = """
  ## \(isoDate()): Google libphonenumber \(latestRef)

  - Previous local metadata matched Google libphonenumber `\(currentRef)`.
  - Updated main phone-number metadata to `\(latestRef)`.
  - Updated short-number metadata to `\(latestRef)`.
  - Updated testing metadata to `\(latestRef)`.
  - Updated geocoding metadata to `\(latestRef)`.

  ### Freshness Summary

  See generated metadata freshness summary for file-level SHA-256 and byte-size changes.
  """

  try summaryText.write(to: outputDirectory.appendingPathComponent("metadata-diff-summary.md"), atomically: true, encoding: .utf8)
  try issueTemplate.write(to: outputDirectory.appendingPathComponent("metadata-update-issue.md"), atomically: true, encoding: .utf8)
  try prTemplate.write(to: outputDirectory.appendingPathComponent("metadata-update-pr.md"), atomically: true, encoding: .utf8)
  try logCandidate.write(to: outputDirectory.appendingPathComponent("metadata-update-log-entry.md"), atomically: true, encoding: .utf8)
}

func isoDate() -> String {
  let formatter = ISO8601DateFormatter()
  formatter.formatOptions = [.withFullDate]
  return formatter.string(from: Date())
}

do {
  let options = try parseArguments(CommandLine.arguments)
  let currentRef = try options.currentRef ?? latestRecordedMetadataRef()
  let latestRef = try latestUpstreamTag()
  let outputDirectory = options.outputDirectory ?? repositoryRoot.appendingPathComponent(".build/metadata-freshness")
  let summaries = try summarize(currentRef: currentRef, latestRef: latestRef, outputDirectory: outputDirectory)
  try writeArtifacts(currentRef: currentRef, latestRef: latestRef, summaries: summaries, outputDirectory: outputDirectory)

  print("Current metadata ref: \(currentRef)")
  print("Latest upstream tag: \(latestRef)")
  print("Output: \(outputDirectory.path)")
  print(currentRef == latestRef ? "Metadata is up to date." : "Metadata update is available.")
  if options.failOnUpdate && currentRef != latestRef {
    exit(2)
  }
} catch {
  fputs("checkMetadataFreshness failed: \(error)\n", stderr)
  exit(1)
}
