#!/usr/bin/env swift

import Foundation

let defaultSchemes = [
  "libPhoneNumber",
  "libPhoneNumberGeocoding",
  "libPhoneNumberShortNumber",
]

struct Options {
  var destination = "platform=iOS Simulator,name=iPhone 16"
  var derivedDataRoot: URL?
  var schemes: [String] = []
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
    swift scripts/testXcodeSchemes.swift [options] [scheme ...]

  Options:
    --destination <value>        xcodebuild destination. Default: platform=iOS Simulator,name=iPhone 16.
    --derived-data-root <dir>    Use a separate derived data directory per scheme.
    --help                      Print this help.

  Examples:
    swift scripts/testXcodeSchemes.swift
    swift scripts/testXcodeSchemes.swift --destination 'id=<simulator-udid>'
    swift scripts/testXcodeSchemes.swift libPhoneNumberShortNumber
  """
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
    case "--destination":
      index += 1
      guard index < arguments.count else {
        throw ScriptError.invalidArguments("--destination requires a value")
      }
      options.destination = arguments[index]
    case "--derived-data-root":
      index += 1
      guard index < arguments.count else {
        throw ScriptError.invalidArguments("--derived-data-root requires a path")
      }
      options.derivedDataRoot = absoluteURL(forPath: arguments[index])
    default:
      if argument.hasPrefix("-") {
        throw ScriptError.invalidArguments("Unknown option: \(argument)")
      }
      options.schemes.append(argument)
    }

    index += 1
  }

  if options.schemes.isEmpty {
    options.schemes = defaultSchemes
  }

  return options
}

func shellEscaped(_ value: String) -> String {
  if value.range(of: #"^[A-Za-z0-9_./:=@%+,\-]+$"#, options: .regularExpression) != nil {
    return value
  }
  return "'\(value.replacingOccurrences(of: "'", with: "'\\''"))'"
}

func commandLine(_ command: String, _ arguments: [String]) -> String {
  ([command] + arguments).map(shellEscaped).joined(separator: " ")
}

func sanitizedPathComponent(_ value: String) -> String {
  let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "._-"))
  return String(
    value.unicodeScalars.map { allowed.contains($0) ? Character($0) : "_" }
  )
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

func testScheme(_ scheme: String, options: Options) throws {
  var arguments = [
    "test",
    "-scheme",
    scheme,
    "-destination",
    options.destination,
  ]

  if let derivedDataRoot = options.derivedDataRoot {
    let derivedDataPath = derivedDataRoot
      .appendingPathComponent(sanitizedPathComponent(scheme))
      .path
    arguments += ["-derivedDataPath", derivedDataPath]
  }

  try run("xcodebuild", arguments)
}

do {
  let options = try parseOptions(Array(CommandLine.arguments.dropFirst()))

  print("Destination: \(options.destination)")
  print("Schemes: \(options.schemes.joined(separator: ", "))")
  if let derivedDataRoot = options.derivedDataRoot {
    print("Derived data root: \(derivedDataRoot.path)")
  }

  for scheme in options.schemes {
    try testScheme(scheme, options: options)
  }

  print("\nAll Xcode schemes passed.")
} catch {
  fputs("error: \(error)\n", stderr)
  fputs("\n\(usage())\n", stderr)
  exit(1)
}
