#!/usr/bin/swift

import Foundation

enum ScriptError: Error, CustomStringConvertible {
  case invalidArguments(String)
  case processFailed(String)

  var description: String {
    switch self {
    case .invalidArguments(let message):
      return message
    case .processFailed(let message):
      return message
    }
  }
}

struct Options {
  var currentRef: String?
  var upstreamRef = "master"
  var outputDirectory: URL?
  var failOnDrift = false
}

let trackedPaths = [
  "javascript/i18n/phonenumbers/phonenumberutil.js",
  "javascript/i18n/phonenumbers/phonenumberutil_test.js",
  "javascript/i18n/phonenumbers/asyoutypeformatter.js",
  "javascript/i18n/phonenumbers/asyoutypeformatter_test.js",
  "javascript/i18n/phonenumbers/shortnumberinfo.js",
  "javascript/i18n/phonenumbers/shortnumberinfo_test.js",
  "javascript/i18n/phonenumbers/metadata.js",
  "javascript/i18n/phonenumbers/metadatafortesting.js",
  "javascript/i18n/phonenumbers/shortnumbermetadata.js",
  "resources/PhoneNumberMetadata.xml",
  "resources/PhoneNumberMetadataForTesting.xml",
  "resources/ShortNumberMetadata.xml",
  "resources/geocoding",
  "resources/carrier",
  "resources/timezones",
]

let scriptURL = absoluteURL(forPath: CommandLine.arguments[0])
let scriptsDirectory = scriptURL.deletingLastPathComponent()
let repositoryRoot = scriptsDirectory.deletingLastPathComponent()

func usage() -> String {
  """
  Usage:
    swift scripts/checkUpstreamSourceDrift.swift [--current-ref <ref>] [--upstream-ref <ref>] [--output <dir>] [--fail-on-drift]

  Examples:
    swift scripts/checkUpstreamSourceDrift.swift
    swift scripts/checkUpstreamSourceDrift.swift --current-ref v9.0.30 --upstream-ref master
    swift scripts/checkUpstreamSourceDrift.swift --output .build/upstream-source-drift --fail-on-drift

  Notes:
    - Without --current-ref, the script reads the newest vX.Y.Z entry from docs/METADATA_UPDATE_LOG.md.
    - The script compares tracked Google libphonenumber source and resource paths against --upstream-ref.
    - The script writes a Markdown summary, name-status file, diff stat, and patch artifact.
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
    case "--upstream-ref":
      index += 1
      guard index < arguments.count else {
        throw ScriptError.invalidArguments("--upstream-ref requires a value")
      }
      options.upstreamRef = normalizedGitRef(arguments[index])
    case "--output", "-o":
      index += 1
      guard index < arguments.count else {
        throw ScriptError.invalidArguments("\(argument) requires a path")
      }
      options.outputDirectory = absoluteURL(forPath: arguments[index])
    case "--fail-on-drift":
      options.failOnDrift = true
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

@discardableResult
func runProcess(_ executable: String, _ arguments: [String], workingDirectory: URL? = nil) throws -> String {
  let process = Process()
  process.executableURL = URL(fileURLWithPath: executable)
  process.arguments = arguments
  process.currentDirectoryURL = workingDirectory

  let standardOutput = Pipe()
  let standardError = Pipe()
  process.standardOutput = standardOutput
  process.standardError = standardError

  try process.run()
  let output = standardOutput.fileHandleForReading.readDataToEndOfFile()
  let errorOutput = standardError.fileHandleForReading.readDataToEndOfFile()
  process.waitUntilExit()

  let outputText = String(data: output, encoding: .utf8) ?? ""
  let errorText = String(data: errorOutput, encoding: .utf8) ?? ""

  guard process.terminationStatus == 0 else {
    let command = ([executable] + arguments).joined(separator: " ")
    throw ScriptError.processFailed("\(command) failed with exit code \(process.terminationStatus): \(errorText)")
  }

  return outputText
}

@discardableResult
func runGit(_ arguments: [String], workingDirectory: URL) throws -> String {
  try runProcess("/usr/bin/git", arguments, workingDirectory: workingDirectory)
}

func fetchRemoteRef(_ ref: String, into localRef: String, repository: URL) throws {
  let candidates = [
    "+refs/heads/\(ref):\(localRef)",
    "+refs/tags/\(ref):\(localRef)",
    "+\(ref):\(localRef)",
  ]

  var errors: [String] = []
  for candidate in candidates {
    do {
      try runGit(["fetch", "--depth=1", "origin", candidate], workingDirectory: repository)
      return
    } catch {
      errors.append(String(describing: error))
    }
  }

  throw ScriptError.processFailed("Unable to fetch upstream ref \(ref):\n\(errors.joined(separator: "\n"))")
}

func markdownEscaped(_ value: String) -> String {
  value
    .replacingOccurrences(of: "\\", with: "\\\\")
    .replacingOccurrences(of: "|", with: "\\|")
}

func changedFileCount(from nameStatus: String) -> Int {
  nameStatus
    .split(separator: "\n")
    .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    .count
}

func changedFilesTable(from nameStatus: String) -> String {
  let lines = nameStatus
    .split(separator: "\n")
    .map(String.init)
    .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

  guard !lines.isEmpty else {
    return "No tracked source or resource drift was detected."
  }

  let rows = lines.map { line -> String in
    let parts = line.split(separator: "\t", omittingEmptySubsequences: false).map(String.init)
    let status = parts.first ?? ""
    let paths = parts.dropFirst().map { "`\(markdownEscaped($0))`" }.joined(separator: " -> ")
    return "| `\(markdownEscaped(status))` | \(paths) |"
  }

  return """
  | Status | Path |
  | --- | --- |
  \(rows.joined(separator: "\n"))
  """
}

func trackedPathList() -> String {
  trackedPaths.map { "- `\($0)`" }.joined(separator: "\n")
}

func writeArtifacts(
  currentRef: String,
  currentCommit: String,
  upstreamRef: String,
  upstreamCommit: String,
  nameStatus: String,
  diffStat: String,
  patch: String,
  outputDirectory: URL
) throws {
  try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

  let driftCount = changedFileCount(from: nameStatus)
  let status = driftCount == 0 ? "no drift" : "drift detected"
  let summary = """
  # Upstream Source Drift Summary

  - Current baseline ref: `\(currentRef)` (`\(currentCommit.prefix(12))`)
  - Compared upstream ref: `\(upstreamRef)` (`\(upstreamCommit.prefix(12))`)
  - Status: \(status)
  - Changed tracked files: \(driftCount)

  ## Changed Files

  \(changedFilesTable(from: nameStatus))

  ## Diff Stat

  ```text
  \(diffStat.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "No changes." : diffStat.trimmingCharacters(in: .whitespacesAndNewlines))
  ```

  ## Tracked Paths

  \(trackedPathList())
  """

  try summary.write(to: outputDirectory.appendingPathComponent("upstream-source-drift-summary.md"), atomically: true, encoding: .utf8)
  try nameStatus.write(to: outputDirectory.appendingPathComponent("upstream-source-drift-name-status.txt"), atomically: true, encoding: .utf8)
  try diffStat.write(to: outputDirectory.appendingPathComponent("upstream-source-drift-stat.txt"), atomically: true, encoding: .utf8)
  try patch.write(to: outputDirectory.appendingPathComponent("upstream-source-drift.diff"), atomically: true, encoding: .utf8)
}

do {
  let options = try parseArguments(CommandLine.arguments)
  let currentRef = try options.currentRef ?? latestRecordedMetadataRef()
  let upstreamRef = options.upstreamRef
  let outputDirectory = options.outputDirectory ?? repositoryRoot.appendingPathComponent(".build/upstream-source-drift")
  let temporaryDirectory = FileManager.default.temporaryDirectory
    .appendingPathComponent("libphonenumber-upstream-drift-\(UUID().uuidString)")

  try FileManager.default.createDirectory(at: temporaryDirectory, withIntermediateDirectories: true)
  defer {
    try? FileManager.default.removeItem(at: temporaryDirectory)
  }

  try runGit(["init", "-q"], workingDirectory: temporaryDirectory)
  try runGit(["remote", "add", "origin", "https://github.com/google/libphonenumber.git"], workingDirectory: temporaryDirectory)
  try fetchRemoteRef(currentRef, into: "refs/drift/current", repository: temporaryDirectory)
  try fetchRemoteRef(upstreamRef, into: "refs/drift/upstream", repository: temporaryDirectory)

  let currentCommit = try runGit(["rev-parse", "refs/drift/current^{commit}"], workingDirectory: temporaryDirectory)
    .trimmingCharacters(in: .whitespacesAndNewlines)
  let upstreamCommit = try runGit(["rev-parse", "refs/drift/upstream^{commit}"], workingDirectory: temporaryDirectory)
    .trimmingCharacters(in: .whitespacesAndNewlines)
  let diffArguments = [currentCommit, upstreamCommit, "--"] + trackedPaths
  let nameStatus = try runGit(["diff", "--name-status", "--find-renames"] + diffArguments, workingDirectory: temporaryDirectory)
  let diffStat = try runGit(["diff", "--stat"] + diffArguments, workingDirectory: temporaryDirectory)
  let patch = try runGit(["diff", "--no-ext-diff", "--find-renames"] + diffArguments, workingDirectory: temporaryDirectory)

  try writeArtifacts(
    currentRef: currentRef,
    currentCommit: currentCommit,
    upstreamRef: upstreamRef,
    upstreamCommit: upstreamCommit,
    nameStatus: nameStatus,
    diffStat: diffStat,
    patch: patch,
    outputDirectory: outputDirectory
  )

  let driftCount = changedFileCount(from: nameStatus)
  print("Current baseline ref: \(currentRef) (\(currentCommit.prefix(12)))")
  print("Compared upstream ref: \(upstreamRef) (\(upstreamCommit.prefix(12)))")
  print("Output: \(outputDirectory.path)")
  print("Changed tracked files: \(driftCount)")
  print(driftCount == 0 ? "No tracked upstream source/resource drift detected." : "Tracked upstream source/resource drift detected.")

  if options.failOnDrift && driftCount > 0 {
    exit(2)
  }
} catch {
  fputs("checkUpstreamSourceDrift failed: \(error)\n", stderr)
  exit(1)
}
