#!/usr/bin/env swift

//
//  updateProjectVersions.swift
//  libPhoneNumber
//
//  Created by Kris Kline on 12/3/25.
//  Copyright © 2025. All rights reserved.
//

import Foundation
#if os(Linux)
import Glibc
#else
import Darwin
#endif

struct Version: CustomStringConvertible {
  let major: Int
  let minor: Int
  let patch: Int

  var description: String {
    "\(major).\(minor).\(patch)"
  }

  var minorRange: String {
    "\(major).\(minor)"
  }

  init?(_ rawValue: String) {
    let parts = rawValue.split(separator: ".").map(String.init)
    guard parts.count == 3,
          let major = Int(parts[0]),
          let minor = Int(parts[1]),
          let patch = Int(parts[2]) else {
      return nil
    }

    self.major = major
    self.minor = minor
    self.patch = patch
  }
}

let scriptVersion = "1.1.0"
let scriptName = URL(fileURLWithPath: CommandLine.arguments.first ?? "updateProjectVersions.swift").lastPathComponent
let repoRoot = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)

enum LogMode {
  case verbose
  case quiet
}

var mode: LogMode = .verbose
var shouldRunConsistencyCheck = true
var newVersion: Version?

func usage() -> Never {
  print("""
  Usage:
    \(scriptName) [--no-status] [--skip-consistency-check] <new_version>

  Updates Xcode project versions, podspec versions, podspec dependency ranges,
  and README CocoaPods examples. The version must use X.Y.Z format.
  """)
  exit(2)
}

var arguments = Array(CommandLine.arguments.dropFirst())
while !arguments.isEmpty {
  let argument = arguments.removeFirst()
  switch argument {
  case "-n", "--no-status":
    mode = .quiet
  case "--skip-consistency-check":
    shouldRunConsistencyCheck = false
  case "-h", "--help":
    usage()
  default:
    guard newVersion == nil, let version = Version(argument) else {
      print("Unknown argument or invalid version: \(argument)")
      usage()
    }
    newVersion = version
  }
}

guard let version = newVersion else {
  usage()
}

func logStatus(_ message: String) {
  guard mode == .verbose else {
    return
  }

  print(message)
}

func relativePath(for url: URL) -> String {
  url.path.replacingOccurrences(of: repoRoot.path + "/", with: "")
}

func readUTF8(_ url: URL) -> String? {
  try? String(contentsOf: url, encoding: .utf8)
}

func writeUTF8(_ text: String, to url: URL) -> Bool {
  do {
    try text.write(to: url, atomically: true, encoding: .utf8)
    return true
  } catch {
    fputs("Failed to write \(relativePath(for: url)): \(error)\n", stderr)
    return false
  }
}

func replacingMatches(in text: String, pattern: String, template: String, options: NSRegularExpression.Options = []) -> String {
  guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else {
    return text
  }
  let range = NSRange(text.startIndex..., in: text)
  return regex.stringByReplacingMatches(in: text, range: range, withTemplate: template)
}

func findFiles(suffixes: [String], in directory: URL) -> [URL] {
  let fileManager = FileManager.default
  var found: [URL] = []
  let resourceKeys = [URLResourceKey.isDirectoryKey]

  guard let enumerator = fileManager.enumerator(
    at: directory,
    includingPropertiesForKeys: resourceKeys,
    options: [.skipsHiddenFiles]
  ) else {
    return []
  }

  for case let fileURL as URL in enumerator {
    if fileURL.pathComponents.contains("Pods") || fileURL.pathComponents.contains(".build") {
      continue
    }

    let fileExtension = fileURL.pathExtension.lowercased()
    let fileName = fileURL.lastPathComponent.lowercased()
    if suffixes.contains(fileExtension) || suffixes.contains(where: { fileName.hasSuffix($0) }) {
      found.append(fileURL)
    }
  }

  return found
}

@discardableResult
func updatePBXProj(at url: URL, toVersion version: Version) -> Bool {
  guard let text = readUTF8(url) else {
    return false
  }

  var updated = text
  for variableName in ["MARKETING_VERSION", "CURRENT_PROJECT_VERSION"] {
    updated = replacingMatches(
      in: updated,
      pattern: #"(\b\#(variableName)\s*=\s*)[^;]+(;)"#,
      template: "$1\(version)$2"
    )
  }

  guard updated != text else {
    return false
  }

  return writeUTF8(updated, to: url)
}

@discardableResult
func updatePodspec(at url: URL, toVersion version: Version) -> Bool {
  guard let text = readUTF8(url) else {
    return false
  }

  var updated = replacingMatches(
    in: text,
    pattern: #"(^\s*.*\.version\s*=\s*['"])([^'"]+)(['"])"#,
    template: "$1\(version)$3",
    options: [.anchorsMatchLines]
  )

  updated = replacingMatches(
    in: updated,
    pattern: #"(^\s*s\.dependency\s+['"][^'"]+['"]\s*,\s*['"]~>\s*)([^'"]+)(['"])"#,
    template: "$1\(version)$3",
    options: [.anchorsMatchLines]
  )

  guard updated != text else {
    return false
  }

  return writeUTF8(updated, to: url)
}

@discardableResult
func updateREADME(at url: URL, toVersion version: Version) -> Bool {
  guard let text = readUTF8(url) else {
    return false
  }

  let podNames = [
    "libPhoneNumber-iOS",
    "libPhoneNumberSwift",
    "libPhoneNumberGeocoding",
    "libPhoneNumberShortNumber",
  ].joined(separator: "|")

  let updated = replacingMatches(
    in: text,
    pattern: #"(pod\s+['"](?:\#(podNames))['"]\s*,\s*['"]~>\s*)([^'"]+)(['"])"#,
    template: "$1\(version.minorRange)$3"
  )

  guard updated != text else {
    return false
  }

  return writeUTF8(updated, to: url)
}

func runConsistencyCheck() -> Bool {
  let checker = repoRoot.appendingPathComponent("scripts/checkVersionConsistency.swift")
  guard FileManager.default.fileExists(atPath: checker.path) else {
    fputs("Skipping consistency check because scripts/checkVersionConsistency.swift is missing.\n", stderr)
    return true
  }

  let process = Process()
  process.currentDirectoryURL = repoRoot
  process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
  process.arguments = ["swift", "scripts/checkVersionConsistency.swift"]
  fflush(stdout)

  do {
    try process.run()
    process.waitUntilExit()
    return process.terminationStatus == 0
  } catch {
    fputs("Failed to run version consistency check: \(error)\n", stderr)
    return false
  }
}

var modifiedFiles: [String] = []

logStatus("""
-----------------------------------------------------
\(scriptName) v\(scriptVersion)
-----------------------------------------------------

Updating project versions to: \(version)
README CocoaPods examples will use: ~> \(version.minorRange)

""")

let pbxprojFiles = findFiles(suffixes: ["pbxproj"], in: repoRoot)
let podspecFiles = findFiles(suffixes: ["podspec"], in: repoRoot)

logStatus("Found \(pbxprojFiles.count) *.pbxproj files")
logStatus("Found \(podspecFiles.count) *.podspec files")

for file in pbxprojFiles.sorted(by: { $0.path < $1.path }) {
  if updatePBXProj(at: file, toVersion: version) {
    let path = relativePath(for: file)
    modifiedFiles.append(path)
    logStatus("[UPDATED] \(path)")
  }
}

for file in podspecFiles.sorted(by: { $0.path < $1.path }) {
  if updatePodspec(at: file, toVersion: version) {
    let path = relativePath(for: file)
    modifiedFiles.append(path)
    logStatus("[UPDATED] \(path)")
  }
}

let readme = repoRoot.appendingPathComponent("README.md")
if updateREADME(at: readme, toVersion: version) {
  let path = relativePath(for: readme)
  modifiedFiles.append(path)
  logStatus("[UPDATED] \(path)")
}

logStatus("\nModified \(modifiedFiles.count) file(s):")
if mode == .verbose {
  for path in modifiedFiles {
    print(path)
  }
} else {
  modifiedFiles.forEach { print($0) }
}

if shouldRunConsistencyCheck {
  logStatus("\nRunning version consistency check...")
  guard runConsistencyCheck() else {
    exit(1)
  }
}

logStatus("-----------------------------------------------------")
