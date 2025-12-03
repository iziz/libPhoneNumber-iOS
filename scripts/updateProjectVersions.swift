#!/usr/bin/env swift

//
//  updateProjectVersions.swift
//  libPhoneNumber
//
//  Created by Kris Kline on 12/3/25.
//  Copyright © 2025. All rights reserved.
//

import Foundation

// MARK: - Script Configuration

let scriptVersion = "1.0.0"

let scriptName = URL(fileURLWithPath: (CommandLine.arguments.first)!).lastPathComponent

let dividingLine = "-----------------------------------------------------"
let header =
"""
\(dividingLine)
\(scriptName) v\(scriptVersion)
"""
let footer =
"""
\(dividingLine)
"""

// MARK: - String Extension

extension String {
  /// Whether this string represents a numbered version: X.Y.Z, X.Y, or Z
  var isVersion: Bool {
    // Regex to match a common version format (e.g., X.Y.Z, X.Y, X)
    // where X, Y, Z are one or more digits.
    let versionPattern = #"^\d+(\.\d+){0,2}$"#
    
    do {
      let regex = try Regex(versionPattern)
      return self.wholeMatch(of: regex) != nil
    } catch {
      return false
    }
  }
}

// MARK: - Argument Parsing

enum LogMode {
    case verbose
    case quiet
}

var mode: LogMode = .verbose
var newVersion: String?

var argIter: IndexingIterator<Array<String>.SubSequence> = CommandLine.arguments.dropFirst().makeIterator()

while let arg: String = argIter.next() {
    switch arg {
    case "-n", "--no-status":
        mode = .quiet
    default:
        if newVersion == nil, arg.isVersion {
            newVersion = arg
        } else {
            print("Unknown argument: \(arg)")
            exit(1)
        }
    }
}

guard let ver = newVersion else {
    print("Usage: \(scriptName) [-n|--no-status] <new_version>")
    exit(1)
}

/**
 Logs out the specified status message, if logging is enabled
 
 - parameter message: The status message to log out
 */
func logStatus(_ message: String) {
    guard mode == .verbose else {
        return
    }

    print(message)
}

// MARK: - File Search Utilities

/**
 Finds all the files in the directory (and any subdirectories) with the specified suffixes
 
 - parameter suffixes: The file suffixes to look for
 - parameter directory: The directory to search in
 
 - returns The array of files with the specified suffixes
 */
func findFiles(suffixes: [String], in directory: URL) -> [URL] {
    let fm = FileManager.default
    var found = [URL]()
    let resourceKeys = [URLResourceKey.isDirectoryKey]
    let enumerator = fm.enumerator(at: directory, includingPropertiesForKeys: resourceKeys, options: [.skipsHiddenFiles])!
    for case let fileURL as URL in enumerator {
        // Ignore files within the cocoapods sub-project
        if fileURL.pathComponents.contains("Pods") {
            continue
        }

        let ext = fileURL.pathExtension.lowercased()
        let name = fileURL.lastPathComponent.lowercased()
        if suffixes.contains(ext) {
            found.append(fileURL)
        } else if suffixes.contains(where: { name.hasSuffix($0) }) {
            found.append(fileURL)
        }
    }
    return found
}

// MARK: - Version Updating

/**
 Updates the specified pbxproj file to use the specfiied project version
 
 - parameter url: The location of the pbxproj file to update
 - parameter version: The new project version to use in the file
 
 - returns Whether the file was modified
 */
@discardableResult
func updatePBXProj(at url: URL, toVersion version: String) -> Bool {
    guard let text = try? String(contentsOf: url, encoding: .utf8) else {
        return false
    }
    var modified = text
    let pattern = #"\s*=\s*[^;]+;"#
    let variableNames = ["MARKETING_VERSION", "CURRENT_PROJECT_VERSION"]
    var changed = false
    
    for name in variableNames {
        guard let regex = try? NSRegularExpression(pattern: name + pattern) else { continue }
        let results = regex.matches(in: modified, range: NSRange(modified.startIndex..., in: modified))
        if !results.isEmpty {
            modified = regex.stringByReplacingMatches(in: modified, range: NSRange(modified.startIndex..., in: modified), withTemplate: "\(name) = \(version);")
            changed = true
        }
    }
    
    if changed, modified != text {
        try? modified.write(to: url, atomically: true, encoding: .utf8)
        return true
    }
    return false
}

/**
 Updates the `version` field in a `.podspec` file at the specified URL to the given version string.
 
 - parameter url: The file URL pointing to the `.podspec` file to update.
 - parameter version:  The new version string to set for the `*.version` field.
 
 - returns Whether the file was modified
 */
@discardableResult
func updatePodspec(at url: URL, toVersion version: String) -> Bool {
    guard let text = try? String(contentsOf: url, encoding: .utf8) else {
        return false
    }

    let podspecVersionPattern = #"(^\s*.*\.version\s*=\s*['\"])([^'\"]+)(['\"])"#
    let regex = try! NSRegularExpression(pattern: podspecVersionPattern, options: [.anchorsMatchLines])

    let newText = regex.stringByReplacingMatches(in: text, range: NSRange(text.startIndex..., in: text), withTemplate: "$1\(version)$3")
    
    if text != newText {
        try? newText.write(to: url, atomically: true, encoding: .utf8)
        return true
    }
    return false
}

// MARK: - Script Execution

let repoRoot = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
var modifiedFiles = [String]()

logStatus(header + "\n")

let pbxprojFiles = findFiles(suffixes: ["pbxproj"], in: repoRoot)
let podspecFiles = findFiles(suffixes: ["podspec"], in: repoRoot)

logStatus("Found \(pbxprojFiles.count) *.pbxproj files")
logStatus("Found \(podspecFiles.count) *.podspec files")

logStatus("\nUpdating versions to: \(ver)\n")

for file in pbxprojFiles {
    if updatePBXProj(at: file, toVersion: ver) {
        let relPath = file.path.replacingOccurrences(of: repoRoot.path + "/", with: "")
        modifiedFiles.append(relPath)
        logStatus("[UPDATED] \(relPath)")
    }
}

for file in podspecFiles {
    if updatePodspec(at: file, toVersion: ver) {
        let relPath = file.path.replacingOccurrences(of: repoRoot.path + "/", with: "")
        modifiedFiles.append(relPath)
        logStatus("[UPDATED] \(relPath)")
    }
}

logStatus("\nModified \(modifiedFiles.count) file(s):")

if mode == .verbose {
    for path in modifiedFiles { print(path) }
} else {
    modifiedFiles.forEach { print($0) }
}

logStatus(footer)
