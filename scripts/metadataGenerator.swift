#!/usr/bin/swift

//
//  metadataGenerator.swift
//  libPhoneNumber-iOS
//
//  Created by Paween Itthipalkul on 2/16/18.
//  Copyright © 2018 Google LLC. All rights reserved.
//

import Darwin
import Foundation
import JavaScriptCore

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

  /**
   Removes any occurrence of the specific strings from this string and returns the new string
   - parameter substrings: The strings to remove from this string
   
   - returns: The new string without any occurrences of the specified strings
   */
  func removeAnyOccurrences(of substrings: [String]) -> String {
    var returnString = self
    for str in substrings {
      returnString = returnString.replacingOccurrences(of: str, with: "")
    }
    return returnString
  }
}

/// The ANSI code for resetting output text formatting
let ANSI_RESET = "\u{001B}[0m"

/// The ANSI code for making the text foreground color RED
let ANSI_RED = "\u{001B}[31m"

/// The ANSI code for making the text foreground color YELLOW
let ANSI_YELLOW = "\u{001B}[33m"

/**
 Prints the specified warning out to the console's standard error output
 - parameter warnString: The warning string to print out
 */
func printWarning(_ warnString: String) {
    fputs("\(ANSI_YELLOW)\(warnString)\n\(ANSI_RESET)", __stderrp)
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
 */
func printErrorAndExit(_ errorString: String) -> Never {
  printError(errorString)
  exit(1)
}

/**
 Executes the specified "section" of the script by printing out a status to the console, running the block, and then printing out "Done" to indicate the section has completed.
 - note: This is intended to help identify if/when certain areas of the script are running slow or having issues
 
 - parameter sectionName: The "name" of the section to execute
 - parameter block: The block of code to execute for the section
 */
func runSection(_ sectionName: String, block: () -> Void) {
  print("\(sectionName)... ", terminator: "")
  block()
  print(" (Done)")
}

/**
 Possible errors from loading strings remotely
 */
enum GeneratorError: Error {
    /// The data from the remote URL is not a string
    case dataNotString
    
    /// Generic catch-all error type
    case genericError
}

/**
 Synchronously loads a string from the specified URL and returns the loaded string
 
 - parameter url: The URL to load the string representation of
 
 - returns: The string loaded from the specified URL
 
 - throws any error encountered loading the URL, and if the data at the specified URL could not be convereted into a String value
 */
func synchronouslyLoadStringResource(from url: URL) throws -> String {
  let session = URLSession(configuration: .default)
  var resultData: Data?
  var resultError: Error?
  let semaphore = DispatchSemaphore(value: 0)

  let dataTask = session.dataTask(with: url) { data, _, error in
    resultData = data
    resultError = error
    semaphore.signal()
  }
  dataTask.resume()

  semaphore.wait()

  if let error = resultError {
    throw error
  }

  if let data = resultData {
    guard let string = String(data: data, encoding: .utf8) else {
      throw GeneratorError.dataNotString
    }

    return string
  }

  throw GeneratorError.genericError
}

/**
 Loads JavaScript from the specified URL into the specified JavaScript Context
 - note: This function will exit the script if it there is an error encountered trying to load the specifid URL
 
 - parameter url: The URL to load JavaScript data from
 - parameter context: The context to load the JavaScript data into
 */
func loadJS(from url: URL, to context: JSContext) {
  guard let script = try? synchronouslyLoadStringResource(from: url) else {
    printErrorAndExit("Cannot load dependency at \(url)")
  }

  context.evaluateScript(script)
}

/**
 Process MetaData from the specified URL into the JavaScript Context, and output the resulting MetaData to the specified Output URL
 
 - parameter context: The JavaScript context to process the MetaData within
 - parameter url: The URL to load the MetaData from
 - parameter jsVariable: The JavaScript variable to extract the MetaData of
 - parameter output: The file URL to output the MetaData to
 - parameter prettyPrint: Whether to 'pretty print' the resulting MetaData
 
 - throws Any errors encournted while loading and coverting MetaData
 */
func processMetaData(_ context: JSContext, _ url: URL, jsVariable: String, output: URL, prettyPrint: Bool) throws {
    let metadata = try synchronouslyLoadStringResource(from: url)
    context.evaluateScript(metadata)
    var result = context.evaluateScript("JSON.stringify(\(jsVariable))")!.toString()!
    
    if prettyPrint {
        let jsonData = result.data(using: .utf8)!
        let jsonObject = try? JSONSerialization.jsonObject(with: jsonData, options: [])
        let prettyJsonData = try? JSONSerialization.data(withJSONObject: jsonObject!, options: [.prettyPrinted, .sortedKeys])
        result = String(data: prettyJsonData!, encoding: .utf8)!
    }
    
    result.append("\n")
    try result.write(
        to: output,
        atomically: true,
        encoding: .utf8)
    // Clean up
    context.evaluateScript("\(jsVariable) = null")
}

/**
 Processes the arguments passed into this script
 
 - returns A tuple with the version of libPhoneNumber metadata to download & whether to "pretty print" the data
 */
func processArguments() -> (String, Bool) {
    var prettyPrint = false
    var version: String?
    for i in 1..<CommandLine.arguments.count {
        let arg = CommandLine.arguments[i].lowercased()
        if arg.starts(with: "-p") || arg.starts(with: "--p") || arg.starts(with: "p") {
            prettyPrint = true
        } else if arg.starts(with: "v") || arg.starts(with: "-v") || arg.starts(with: "--v") {
            let tempString = arg.removeAnyOccurrences(of: ["--v", "-v", "v"])
            if tempString.isVersion {
              version = tempString
            }
        } else if arg.isVersion {
            version = arg
        } else if arg == "master" || arg == "-master" || arg == "--master" {
            version = "master"
        }
    }
    
    guard let versionString = version else {
        printErrorAndExit("No version was specified in the arguments. Must be in the format: \"X.X.X\" or \"vX.X.X\".")
    }

    return (versionString, prettyPrint)
}


guard CommandLine.arguments.count > 1 else {
  printErrorAndExit("Must specify the version of metadata to load as an argument to this script")
}

let (metaDataVersion, prettyPrintFlag) = processArguments()

// Create JavaScript context.
let context = JSContext()!
context.exceptionHandler = { _, exception in
  printWarning("Javascript exception thrown: \(exception!)")
//  exit(1)
}


runSection("Loading Google Closure") {
  // Load required dependencies.
  let googleClosure = URL(string: "http://cdn.rawgit.com/google/closure-library/master/closure/goog/base.js")!
  loadJS(from: googleClosure, to: context)
}


runSection("Loading JQuery") {
  let jQuery = URL(string: "http://code.jquery.com/jquery-1.8.3.min.js")!
  loadJS(from: jQuery, to: context)
}


runSection("Processing Required JS Elements") {
  // Evaluate requires.
  let requires = """
    goog.require('goog.proto2.Message');
    goog.require('goog.dom');
    goog.require('goog.json');
    goog.require('goog.array');
    goog.require('goog.proto2.ObjectSerializer');
    goog.require('goog.string.StringBuffer');
    goog.require('i18n.phonenumbers.metadata');
    """
  context.evaluateScript(requires)
}

let branch: String = metaDataVersion.isVersion ? "v\(metaDataVersion)" : metaDataVersion

// Load metadata files from GitHub.
let phoneMetadata = URL(string: "https://raw.githubusercontent.com/google/libphonenumber/\(branch)/javascript/i18n/phonenumbers/metadata.js")!
let phoneMetadataForTesting = URL(string: "https://raw.githubusercontent.com/google/libphonenumber/\(branch)/javascript/i18n/phonenumbers/metadatafortesting.js")!
let shortNumberMetadata = URL(string: "https://raw.githubusercontent.com/google/libphonenumber/\(branch)/javascript/i18n/phonenumbers/shortnumbermetadata.js")!

let currentDir = FileManager.default.currentDirectoryPath
let baseURL = URL(fileURLWithPath: currentDir).deletingLastPathComponent().appendingPathComponent("generatedJSON")
try? FileManager.default.createDirectory(at: baseURL, withIntermediateDirectories: true)


runSection("Downloading PhoneNumber MetaData") {
  do {
    let url = baseURL.appendingPathComponent("PhoneNumberMetaData.json")
    try processMetaData(context, phoneMetadata, jsVariable: "i18n.phonenumbers.metadata", output: url, prettyPrint: prettyPrintFlag)
  } catch (let error) {
    printErrorAndExit("Error loading phone number metadata \(error)")
  }
}


runSection("Downloading PhoneNumber MetaData for testing... ") {
  do {
    let url = baseURL.appendingPathComponent("PhoneNumberMetaDataForTesting.json")
    try processMetaData(context, phoneMetadataForTesting, jsVariable: "i18n.phonenumbers.metadata", output: url, prettyPrint: prettyPrintFlag)
  } catch (let error) {
    printErrorAndExit("Error loading phone number metadata for testing \(error)")
  }
}


runSection("Downloading Short Number MetaData") {
  do {
    let url = baseURL.appendingPathComponent("ShortNumberMetadata.json")
    try processMetaData(context, shortNumberMetadata, jsVariable: "i18n.phonenumbers.shortnumbermetadata", output: url, prettyPrint: prettyPrintFlag)
  } catch (let error) {
    printErrorAndExit("Error loading short number metadata \(error)")
  }
}


print("\nSuccessfully updated files at: \(baseURL.path)\n")
