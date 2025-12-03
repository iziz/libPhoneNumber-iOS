#!/usr/bin/env swift

//
//  versionCommitter.swift
//  libPhoneNumber
//
//  Created by Kris Kline on 12/3/25.
//  Copyright © 2025 Google. All rights reserved.
//

import Foundation

// MARK: - Script Configuration

let scriptVersion = "1.0.0"

let scriptName = URL(fileURLWithPath: (CommandLine.arguments.first)!).lastPathComponent
let scriptPath = URL(fileURLWithPath: (CommandLine.arguments.first)!).deletingLastPathComponent().path

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

/// The ANSI code for resetting output text formatting
let ANSI_RESET = "\u{001B}[0m"

/// The ANSI code for making the text foreground color RED
let ANSI_RED = "\u{001B}[31m"

/**
 Prints out the usage information for this script to the console
 */
func printUsage() {
    print(
    """
    Usage: \(scriptName) <new_version> [-p|--push] [-r|--remote <remote>]
    Example: \(scriptName) 1.2.3 -p -r original
    """
    )
}

/**
 Prints the specified error out to the console's standard error output

 - parameter errorString: The error string to print out
 */
func printError(_ errorString: String) {
    fputs("\(ANSI_RED)\(errorString)\n\(ANSI_RESET)", __stderrp)
}

/**
 Prints the specified error out to the console and exists the script

 - parameter exitCode: The exit code for ending the program
 - parameter errorString: The error string to print out
 */
func printErrorAndExit(_ exitCode: Int32, _ errorString: String) -> Never {
    printError(errorString)
    exit(exitCode)
}

var argVersion: String?
var pushBranch = false
var remoteName = "origin"

var argIter: IndexingIterator<Array<String>.SubSequence> = CommandLine.arguments.dropFirst().makeIterator()

while let arg: String = argIter.next() {
    switch arg {
    case "-p", "--push":
        pushBranch = true
    case "-r", "--remote":
        guard let tempName = argIter.next() else {
            printErrorAndExit(1, "ERROR: '--remote' or '-r' flag must be followed by the name of the remote to use")
        }
        remoteName = tempName
    default:
        if argVersion == nil, arg.isVersion {
            argVersion = arg
        } else {
            printErrorAndExit(1, "Unknown argument: \(arg)")
        }
    }
}

guard let newVersion = argVersion else {
    printUsage()
    printErrorAndExit(1, "ERROR: Version string is required.")
}

// MARK: - Helper Functions

/**
 Runs the specified shell command and returns the output as a String, along with the exit code
 
 - parameter printOutput: Whether to print the output from the shell command (primarily used for debugging)
 - parameter args: The list of arguments to run in the shell
 
 - returns A tuple of the output as a string, and the exit code
 */
@discardableResult
func shell(printOutput: Bool = false, _ args: String...) -> (output: String, exitCode: Int32) {
    let task = Process()
    let pipe = Pipe()
    
    task.standardOutput = pipe
    task.standardError = pipe
    task.arguments = ["-c", args.joined(separator: " ")]
    task.launchPath = "/bin/bash"
    task.launch()
    if printOutput {
        print("\n\n\(args.joined(separator: " "))")
    }
    print("", terminator: "") // helps with the 'git add' command failing sometimes for no reason
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    task.waitUntilExit()
    let output = String(data: data, encoding: .utf8) ?? ""
    if printOutput {
        print("==> Exit Code: \(task.terminationStatus)\n==>\n\(output)\n\n")
    }
    return (output, task.terminationStatus)
}

/**
 Exits the app after doing any necessary clean up
 
 - parameter exitCode: The exit code to use when exiting the application
 */
func exitApp(_ exitCode: Int32) -> Never {
    print(footer)
    exit(exitCode)
}

/**
 Exits the app after doing any necessary clean up
 
 - parameter exitCode: The exit code to use when exiting the application
 - parameter errorString: The error string to print when exiting
 */
func exitAppWithError(_ exitCode: Int32, _ errorString: String) -> Never {
    printError(errorString)
    exitApp(exitCode)
}

// MARK: - Script Execution

print(header)

print("New Version: \(newVersion)\n")

let scriptToCall = "\(scriptPath)/updateProjectVersions.swift"

print("Calling update script: \(scriptToCall) \(newVersion)")
let (result, exitCode) = shell(scriptToCall, newVersion, "-n")

if exitCode != 0 {
    exitAppWithError(2, "ERROR: Script \(scriptToCall) exited with status \(exitCode).")
}

let files = result
    .split(separator: "\n")
    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
    .filter { !$0.isEmpty }

if files.isEmpty {
    print("No files to commit. Exiting.\n")
    exitApp(0)
}

print("Files to commit:")
files.forEach { print("  \($0)") }

// Create branch
let branchName = "Version-\(newVersion)"
print("\nCreating branch: \(branchName)")
let (branchOutput, branchExit) = shell("git checkout -b \(branchName)")
guard branchExit == 0 else {
    exitAppWithError(3, "ERROR: Failed to create branch \(branchName).\n==>\(branchExit)\n==>\(branchOutput)")
}

// Stage files
print("\nAdding files to git staging area...")
let addCommand = "git add \(files.map { "'\($0)'" }.joined(separator: " "))"
let (addOutput, addExit) = shell(addCommand)
guard addExit == 0 else {
    exitAppWithError(4, "ERROR: Failed to add files to git.\n==>\(addExit)\n==>\(addOutput)")
}

// Commit
let commitMessage = "Update version to \(newVersion)"
print("\nCommitting with message: \"\(commitMessage)\"")
let (commitOutput, commitExit) = shell("git commit -m '\(commitMessage)'")
guard commitExit == 0 else {
    exitAppWithError(5, "ERROR: Failed to commit files.\n==>\(commitExit)\n==>\(commitOutput)")
}

// Push
if pushBranch {
    print("\nPushing branch to remote: \"\(remoteName)\"")
    let (pushOutput, pushExit) = shell("git push -u \(remoteName) \(branchName) -f")
    guard pushExit == 0 else {
        exitAppWithError(6, "ERROR: Failed to push branch.\n==>\(pushExit)\n==>\(pushOutput)")
    }
}

if pushBranch {
    print("\nSuccess! Branch \(branchName) created, committed, and pushed to remote: \(remoteName)")
} else {
    print("\nSuccess! Branch \(branchName) created and committed.")
}

print(footer)
