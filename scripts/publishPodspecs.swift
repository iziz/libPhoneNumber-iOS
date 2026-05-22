#!/usr/bin/env swift

import Foundation

struct Options {
  var shouldPublish = false
  var shouldLint = false
  var skipExisting = true
  var retries = 2
  var waitTimeout = 120
  var podspecPaths: [String] = []
}

struct CommandResult {
  let exitCode: Int32
  let output: String
}

struct Podspec {
  let path: String
  let name: String
  let version: String
  let dependencies: [String]
}

enum ScriptError: Error, CustomStringConvertible {
  case invalidArgument(String)
  case commandFailed(String)
  case invalidPodspec(String)
  case cyclicDependencies([String])

  var description: String {
    switch self {
    case .invalidArgument(let message),
         .commandFailed(let message),
         .invalidPodspec(let message):
      return message
    case .cyclicDependencies(let names):
      return "Cyclic local podspec dependencies detected: \(names.sorted().joined(separator: ", "))"
    }
  }
}

let repoRoot = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)

func usage() -> String {
  """
  Usage:
    swift scripts/publishPodspecs.swift [options] [podspec ...]

  Options:
    --lint                Lint podspecs in dependency order without publishing.
    --publish             Push missing podspec versions to CocoaPods trunk.
    --no-skip-existing    Attempt to push versions even when trunk already has them.
    --retries <count>     Retry failed trunk pushes. Default: 2.
    --wait-timeout <sec>  Wait for trunk visibility after each push. Default: 120.
    --help                Print this help.

  Without --lint or --publish, the script only prints dependency order and trunk status.
  """
}

func parseOptions(_ arguments: [String]) throws -> Options {
  var options = Options()
  var index = 0

  while index < arguments.count {
    let argument = arguments[index]

    switch argument {
    case "--lint":
      options.shouldLint = true
    case "--publish":
      options.shouldPublish = true
    case "--no-skip-existing":
      options.skipExisting = false
    case "--retries":
      index += 1
      guard index < arguments.count, let value = Int(arguments[index]), value >= 0 else {
        throw ScriptError.invalidArgument("--retries requires a non-negative integer")
      }
      options.retries = value
    case "--wait-timeout":
      index += 1
      guard index < arguments.count, let value = Int(arguments[index]), value >= 0 else {
        throw ScriptError.invalidArgument("--wait-timeout requires a non-negative integer")
      }
      options.waitTimeout = value
    case "--help", "-h":
      print(usage())
      exit(0)
    default:
      if argument.hasPrefix("-") {
        throw ScriptError.invalidArgument("Unknown option: \(argument)")
      }
      options.podspecPaths.append(argument)
    }

    index += 1
  }

  return options
}

func runCapturing(_ command: String, _ arguments: [String]) throws -> CommandResult {
  let process = Process()
  process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
  process.arguments = [command] + arguments

  let outputPipe = Pipe()
  process.standardOutput = outputPipe
  process.standardError = outputPipe

  try process.run()
  process.waitUntilExit()

  let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
  let output = String(data: data, encoding: .utf8) ?? ""
  return CommandResult(exitCode: process.terminationStatus, output: output)
}

func runStreaming(_ command: String, _ arguments: [String]) throws -> Int32 {
  let process = Process()
  process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
  process.arguments = [command] + arguments
  process.standardInput = FileHandle.standardInput
  process.standardOutput = FileHandle.standardOutput
  process.standardError = FileHandle.standardError

  try process.run()
  process.waitUntilExit()
  return process.terminationStatus
}

func discoverPodspecPaths(from explicitPaths: [String]) throws -> [String] {
  if !explicitPaths.isEmpty {
    return explicitPaths.sorted()
  }

  let contents = try FileManager.default.contentsOfDirectory(atPath: repoRoot.path)
  return contents
    .filter { $0.hasSuffix(".podspec") }
    .sorted()
}

func parsePodspec(at path: String) throws -> Podspec {
  let result = try runCapturing("pod", ["ipc", "spec", path])
  guard result.exitCode == 0 else {
    throw ScriptError.commandFailed("pod ipc spec failed for \(path):\n\(result.output)")
  }
  guard let data = result.output.data(using: .utf8),
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
        let name = json["name"] as? String,
        let version = json["version"] as? String else {
    throw ScriptError.invalidPodspec("Unable to parse name/version from \(path)")
  }

  let dependencyMap = json["dependencies"] as? [String: Any] ?? [:]
  return Podspec(
    path: path,
    name: name,
    version: version,
    dependencies: dependencyMap.keys.sorted()
  )
}

func sortedForPublish(_ podspecs: [Podspec]) throws -> [Podspec] {
  let podspecsByName = Dictionary(uniqueKeysWithValues: podspecs.map { ($0.name, $0) })
  var incomingCount = Dictionary(uniqueKeysWithValues: podspecs.map { ($0.name, 0) })
  var dependents: [String: [String]] = [:]

  for podspec in podspecs {
    let localDependencies = podspec.dependencies.filter { podspecsByName[$0] != nil }
    incomingCount[podspec.name] = localDependencies.count

    for dependency in localDependencies {
      dependents[dependency, default: []].append(podspec.name)
    }
  }

  var ready = incomingCount
    .filter { $0.value == 0 }
    .map(\.key)
    .sorted()
  var orderedNames: [String] = []

  while let next = ready.first {
    ready.removeFirst()
    orderedNames.append(next)

    for dependent in dependents[next, default: []].sorted() {
      incomingCount[dependent, default: 0] -= 1
      if incomingCount[dependent] == 0 {
        ready.append(dependent)
        ready.sort()
      }
    }
  }

  guard orderedNames.count == podspecs.count else {
    let unresolved = incomingCount
      .filter { $0.value > 0 }
      .map(\.key)
    throw ScriptError.cyclicDependencies(unresolved)
  }

  return orderedNames.compactMap { podspecsByName[$0] }
}

func stripANSI(_ text: String) -> String {
  text.replacingOccurrences(
    of: "\u{001B}\\[[0-9;]*m",
    with: "",
    options: .regularExpression
  )
}

func trunkHasVersion(name: String, version: String) throws -> Bool {
  let result = try runCapturing("pod", ["trunk", "info", name])
  guard result.exitCode == 0 else {
    return false
  }

  let cleanOutput = stripANSI(result.output)
  let escapedVersion = NSRegularExpression.escapedPattern(for: version)
  let pattern = #"(?m)^\s*-\s+\#(escapedVersion)\s+\("#
  return cleanOutput.range(of: pattern, options: .regularExpression) != nil
}

func waitForTrunkVersion(name: String, version: String, timeout: Int) throws -> Bool {
  let deadline = Date().addingTimeInterval(TimeInterval(timeout))

  repeat {
    if try trunkHasVersion(name: name, version: version) {
      return true
    }

    if timeout == 0 || Date() >= deadline {
      return false
    }

    Thread.sleep(forTimeInterval: 5)
  } while true
}

func printPlan(_ podspecs: [Podspec]) {
  print("Dependency-aware CocoaPods podspec order:")
  for (index, podspec) in podspecs.enumerated() {
    let localDependencies = podspec.dependencies.filter { dependencyName in
      podspecs.contains { $0.name == dependencyName }
    }
    let dependencyText = localDependencies.isEmpty
      ? "none"
      : localDependencies.sorted().joined(separator: ", ")
    print("\(index + 1). \(podspec.name) \(podspec.version) (\(podspec.path))")
    print("   local dependencies: \(dependencyText)")
  }
}

func lint(_ podspec: Podspec) throws -> Bool {
  print("[lint] \(podspec.path)")
  let exitCode = try runStreaming(
    "pod",
    [
      "lib",
      "lint",
      podspec.path,
      "--allow-warnings",
      "--include-podspecs=*.podspec",
    ]
  )

  if exitCode == 0 {
    print("[ok] \(podspec.name) \(podspec.version) passed lint")
    return true
  }

  print("[warn] \(podspec.name) \(podspec.version) lint failed with exit code \(exitCode)")
  return false
}

func publish(_ podspec: Podspec, options: Options) throws -> Bool {
  let isPublished = try trunkHasVersion(name: podspec.name, version: podspec.version)

  if !options.shouldPublish {
    let status = isPublished ? "present" : "missing"
    print("[check] \(podspec.name) \(podspec.version): \(status)")
    return isPublished
  }

  if options.skipExisting, isPublished {
    print("[skip] \(podspec.name) \(podspec.version) already exists on trunk")
    return true
  }

  for attempt in 1...(options.retries + 1) {
    print("[push] \(podspec.path) attempt \(attempt)/\(options.retries + 1)")
    let exitCode = try runStreaming(
      "pod",
      [
        "trunk",
        "push",
        podspec.path,
        "--allow-warnings",
        "--synchronous",
      ]
    )

    if exitCode == 0 {
      if try waitForTrunkVersion(
        name: podspec.name,
        version: podspec.version,
        timeout: options.waitTimeout
      ) {
        print("[ok] \(podspec.name) \(podspec.version) is visible on trunk")
        return true
      }

      print("[warn] \(podspec.name) \(podspec.version) push exited 0 but is not visible on trunk yet")
    } else if try waitForTrunkVersion(
      name: podspec.name,
      version: podspec.version,
      timeout: min(options.waitTimeout, 30)
    ) {
      print("[ok] \(podspec.name) \(podspec.version) is visible on trunk after a non-zero push exit")
      return true
    } else {
      print("[warn] \(podspec.name) \(podspec.version) push failed with exit code \(exitCode)")
    }

    if attempt <= options.retries {
      Thread.sleep(forTimeInterval: TimeInterval(attempt * 5))
    }
  }

  return false
}

do {
  let options = try parseOptions(Array(CommandLine.arguments.dropFirst()))
  let paths = try discoverPodspecPaths(from: options.podspecPaths)
  let podspecs = try paths.map(parsePodspec)
  let orderedPodspecs = try sortedForPublish(podspecs)

  printPlan(orderedPodspecs)

  if options.shouldLint {
    var failedLintPodspecs: [String] = []
    for podspec in orderedPodspecs {
      if !(try lint(podspec)) {
        failedLintPodspecs.append("\(podspec.name) \(podspec.version)")
      }
    }

    if !failedLintPodspecs.isEmpty {
      print("Failed podspec lint validations:")
      for failedPodspec in failedLintPodspecs {
        print("- \(failedPodspec)")
      }
      exit(1)
    }

    print("All podspecs passed lint.")
    if !options.shouldPublish {
      exit(0)
    }
  }

  var failedPodspecs: [String] = []
  for podspec in orderedPodspecs {
    if !(try publish(podspec, options: options)) {
      failedPodspecs.append("\(podspec.name) \(podspec.version)")
    }
  }

  if failedPodspecs.isEmpty {
    print("All podspec versions are accounted for.")
  } else {
    print("Missing or failed podspec versions:")
    for failedPodspec in failedPodspecs {
      print("- \(failedPodspec)")
    }
    exit(1)
  }
} catch {
  fputs("error: \(error)\n", stderr)
  fputs("\n\(usage())\n", stderr)
  exit(1)
}
