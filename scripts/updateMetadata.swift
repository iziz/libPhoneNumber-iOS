#!/usr/bin/env swift

import Foundation

enum MetadataTask: String, CaseIterable, Comparable {
  case main
  case geocoding
  case carrier
  case timezones

  static func < (lhs: MetadataTask, rhs: MetadataTask) -> Bool {
    lhs.sortOrder < rhs.sortOrder
  }

  var sortOrder: Int {
    switch self {
    case .main:
      return 0
    case .geocoding:
      return 1
    case .carrier:
      return 2
    case .timezones:
      return 3
    }
  }
}

struct Options {
  var ref: String?
  var selectedTasks = Set(MetadataTask.allCases)
  var dryRun = false
  var pretty = true
  var outputRoot: URL?
  var skipFreshnessCheck = false
}

enum ScriptError: Error, CustomStringConvertible {
  case invalidArguments(String)
  case commandFailed(String, Int32)

  var description: String {
    switch self {
    case .invalidArguments(let message):
      return message
    case .commandFailed(let command, let exitCode):
      return "Command failed with exit code \(exitCode): \(command)"
    }
  }
}

let scriptURL = URL(fileURLWithPath: CommandLine.arguments[0])
let scriptsDirectory = scriptURL.deletingLastPathComponent()
let repositoryRoot = scriptsDirectory.deletingLastPathComponent()

func usage() -> String {
  """
  Usage:
    swift scripts/updateMetadata.swift <version|master|ref> [options]

  Options:
    --dry-run                  Validate updates without changing checked-in metadata.
    --only <task[,task]>       Run only selected tasks. Valid tasks: main, geocoding, carrier, timezones.
    --skip <task[,task]>       Skip selected tasks.
    --output-root <dir>        Review output root. Default: .build/metadata-update/<ref>.
    --no-pretty                Do not pretty-print generatedJSON for main metadata.
    --skip-freshness-check     Do not re-run metadata freshness after checked-in updates.
    --help                     Print this help.

  Examples:
    swift scripts/updateMetadata.swift v9.0.31 --dry-run
    swift scripts/updateMetadata.swift v9.0.31
    swift scripts/updateMetadata.swift v9.0.31 --only main,geocoding
    swift scripts/updateMetadata.swift v9.0.31 --skip carrier,timezones
  """
}

func parseTaskList(_ rawValue: String) throws -> Set<MetadataTask> {
  let names = rawValue
    .split(separator: ",")
    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
    .filter { !$0.isEmpty }

  guard !names.isEmpty else {
    throw ScriptError.invalidArguments("Task list must not be empty")
  }

  var tasks = Set<MetadataTask>()
  for name in names {
    guard let task = MetadataTask(rawValue: name) else {
      let validTasks = MetadataTask.allCases.map(\.rawValue).joined(separator: ", ")
      throw ScriptError.invalidArguments("Unknown metadata task: \(name). Valid tasks: \(validTasks)")
    }
    tasks.insert(task)
  }
  return tasks
}

func absoluteURL(forPath path: String) -> URL {
  let url = URL(fileURLWithPath: path)
  if url.path.hasPrefix("/") {
    return url
  }
  return repositoryRoot.appendingPathComponent(path)
}

func parseOptions(_ arguments: [String]) throws -> Options {
  var options = Options()
  var index = 0

  while index < arguments.count {
    let argument = arguments[index]

    switch argument {
    case "-h", "--help":
      print(usage())
      exit(0)
    case "--dry-run":
      options.dryRun = true
    case "--only":
      index += 1
      guard index < arguments.count else {
        throw ScriptError.invalidArguments("--only requires a task list")
      }
      options.selectedTasks = try parseTaskList(arguments[index])
    case "--skip":
      index += 1
      guard index < arguments.count else {
        throw ScriptError.invalidArguments("--skip requires a task list")
      }
      options.selectedTasks.subtract(try parseTaskList(arguments[index]))
    case "--output-root":
      index += 1
      guard index < arguments.count else {
        throw ScriptError.invalidArguments("--output-root requires a path")
      }
      options.outputRoot = absoluteURL(forPath: arguments[index])
    case "--no-pretty":
      options.pretty = false
    case "--skip-freshness-check":
      options.skipFreshnessCheck = true
    default:
      if argument.hasPrefix("-") {
        throw ScriptError.invalidArguments("Unknown option: \(argument)")
      }
      guard options.ref == nil else {
        throw ScriptError.invalidArguments("Only one metadata ref may be specified")
      }
      options.ref = argument
    }

    index += 1
  }

  guard options.ref != nil else {
    throw ScriptError.invalidArguments("Missing metadata ref")
  }
  guard !options.selectedTasks.isEmpty else {
    throw ScriptError.invalidArguments("No metadata tasks selected")
  }

  return options
}

func shellEscaped(_ value: String) -> String {
  if value.range(of: #"^[A-Za-z0-9_./:=@%+-]+$"#, options: .regularExpression) != nil {
    return value
  }
  return "'\(value.replacingOccurrences(of: "'", with: "'\\''"))'"
}

func commandLine(_ command: String, _ arguments: [String]) -> String {
  ([command] + arguments).map(shellEscaped).joined(separator: " ")
}

func run(_ command: String, _ arguments: [String]) throws {
  let commandDescription = commandLine(command, arguments)
  print("\n$ \(commandDescription)")

  let process = Process()
  process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
  process.arguments = [command] + arguments
  process.currentDirectoryURL = repositoryRoot
  process.standardInput = FileHandle.standardInput
  process.standardOutput = FileHandle.standardOutput
  process.standardError = FileHandle.standardError

  try process.run()
  process.waitUntilExit()

  if process.terminationStatus != 0 {
    throw ScriptError.commandFailed(commandDescription, process.terminationStatus)
  }
}

func sanitizedPathComponent(_ value: String) -> String {
  let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "._-"))
  return String(
    value.unicodeScalars.map { allowed.contains($0) ? Character($0) : "_" }
  )
}

func defaultOutputRoot(for ref: String) -> URL {
  repositoryRoot
    .appendingPathComponent(".build/metadata-update")
    .appendingPathComponent(sanitizedPathComponent(ref))
}

func runMainMetadata(ref: String, options: Options) throws {
  var arguments = ["scripts/metadataGenerator.swift", ref]
  if options.pretty {
    arguments.append("--pretty")
  }
  if options.dryRun {
    arguments.append("--dry-run")
  }
  try run("swift", arguments)
}

func runGeocodingMetadata(ref: String, outputRoot: URL, options: Options) throws {
  var arguments = [
    "scripts/updateGeocodingMetadata.swift",
    ref,
    "--output",
    outputRoot.appendingPathComponent("geocoding").path,
  ]
  if options.dryRun {
    arguments.append("--dry-run")
  } else {
    arguments.append("--replace-bundle")
  }
  try run("swift", arguments)
}

func runCarrierMetadata(ref: String, outputRoot: URL, options: Options) throws {
  var arguments = [
    "scripts/updateCarrierMetadata.swift",
    ref,
    "--output",
    outputRoot.appendingPathComponent("carrier").path,
  ]
  if options.dryRun {
    arguments.append("--dry-run")
  } else {
    arguments.append("--replace-bundle")
  }
  try run("swift", arguments)
}

func runTimeZonesMetadata(ref: String, outputRoot: URL, options: Options) throws {
  var arguments = [
    "scripts/updateTimeZonesMetadata.swift",
    ref,
    "--output",
    outputRoot.appendingPathComponent("timezones").path,
  ]
  if options.dryRun {
    arguments.append("--dry-run")
  } else {
    arguments.append("--replace-bundle")
  }
  try run("swift", arguments)
}

func runFreshnessCheck(ref: String, outputRoot: URL) throws {
  try run(
    "swift",
    [
      "scripts/checkMetadataFreshness.swift",
      "--current-ref",
      ref,
      "--output",
      outputRoot.appendingPathComponent("freshness").path,
    ]
  )
}

do {
  let options = try parseOptions(Array(CommandLine.arguments.dropFirst()))
  let ref = options.ref!
  let outputRoot = options.outputRoot ?? defaultOutputRoot(for: ref)
  let selectedTasks = options.selectedTasks.sorted()

  print("Metadata ref: \(ref)")
  print("Mode: \(options.dryRun ? "dry-run" : "replace checked-in metadata")")
  print("Output root: \(outputRoot.path)")
  print("Tasks: \(selectedTasks.map(\.rawValue).joined(separator: ", "))")

  for task in selectedTasks {
    switch task {
    case .main:
      try runMainMetadata(ref: ref, options: options)
    case .geocoding:
      try runGeocodingMetadata(ref: ref, outputRoot: outputRoot, options: options)
    case .carrier:
      try runCarrierMetadata(ref: ref, outputRoot: outputRoot, options: options)
    case .timezones:
      try runTimeZonesMetadata(ref: ref, outputRoot: outputRoot, options: options)
    }
  }

  if !options.dryRun && !options.skipFreshnessCheck {
    try runFreshnessCheck(ref: ref, outputRoot: outputRoot)
  }

  print("\nMetadata update workflow completed.")
} catch {
  fputs("error: \(error)\n", stderr)
  fputs("\n\(usage())\n", stderr)
  exit(1)
}
