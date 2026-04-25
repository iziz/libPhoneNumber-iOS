#!/usr/bin/swift

//
//  metadataGenerator.swift
//  libPhoneNumber-iOS
//
//  Downloads libphonenumber JavaScript metadata from google/libphonenumber,
//  converts it to JSON, and regenerates the embedded gzip byte arrays used by
//  the Objective-C targets.
//

import Darwin
import Foundation
import JavaScriptCore

enum ScriptError: Error, CustomStringConvertible {
  case invalidArguments(String)
  case downloadFailed(URL, String)
  case invalidResponse(URL)
  case invalidUTF8(URL)
  case javascriptException(String)
  case missingJavaScriptValue(String)
  case invalidJSON(String)
  case processFailed(String)

  var description: String {
    switch self {
    case .invalidArguments(let message):
      return message
    case .downloadFailed(let url, let message):
      return "Failed to download \(url.absoluteString): \(message)"
    case .invalidResponse(let url):
      return "Unexpected response while downloading \(url.absoluteString)"
    case .invalidUTF8(let url):
      return "Downloaded data is not UTF-8: \(url.absoluteString)"
    case .javascriptException(let message):
      return "JavaScript evaluation failed: \(message)"
    case .missingJavaScriptValue(let variable):
      return "JavaScript metadata variable was not produced: \(variable)"
    case .invalidJSON(let message):
      return "Invalid generated JSON: \(message)"
    case .processFailed(let message):
      return message
    }
  }
}

struct Options {
  var ref: String?
  var prettyPrintJSON = false
  var jsonOnly = false
  var packOnly = false
  var dryRun = false
}

struct MetadataSource: CaseIterable {
  let displayName: String
  let remoteFileName: String
  let jsonFileName: String
  let jsVariable: String

  static let phoneNumber = MetadataSource(
    displayName: "PhoneNumber metadata",
    remoteFileName: "metadata.js",
    jsonFileName: "PhoneNumberMetaData.json",
    jsVariable: "i18n.phonenumbers.metadata"
  )

  static let phoneNumberForTesting = MetadataSource(
    displayName: "PhoneNumber testing metadata",
    remoteFileName: "metadatafortesting.js",
    jsonFileName: "PhoneNumberMetaDataForTesting.json",
    jsVariable: "i18n.phonenumbers.metadata"
  )

  static let shortNumber = MetadataSource(
    displayName: "ShortNumber metadata",
    remoteFileName: "shortnumbermetadata.js",
    jsonFileName: "ShortNumberMetadata.json",
    jsVariable: "i18n.phonenumbers.shortnumbermetadata"
  )

  static let allCases: [MetadataSource] = [
    .phoneNumber,
    .phoneNumberForTesting,
    .shortNumber
  ]
}

let ANSIReset = "\u{001B}[0m"
let ANSIRed = "\u{001B}[31m"
let ANSIYellow = "\u{001B}[33m"

func printWarning(_ message: String) {
  fputs("\(ANSIYellow)\(message)\n\(ANSIReset)", stderr)
}

func printError(_ message: String) {
  fputs("\(ANSIRed)\(message)\n\(ANSIReset)", stderr)
}

func usage() -> String {
  return """
  Usage:
    ./metadataGenerator.swift <version|master|ref> [--pretty|-p] [--json-only] [--dry-run]
    ./metadataGenerator.swift --pack-only [--dry-run]

  Examples:
    ./metadataGenerator.swift 9.0.29 --pretty
    ./metadataGenerator.swift v9.0.29 --pretty
    ./metadataGenerator.swift master --dry-run
    ./metadataGenerator.swift --pack-only

  Notes:
    - Numeric versions are normalized to GitHub tags, e.g. 9.0.29 -> v9.0.29.
    - By default, generated Objective-C metadata files are built from compact JSON.
    - When --pretty is passed, generatedJSON files are written pretty-printed after
      the compact JSON has been used for the embedded gzip payloads.
    - --pack-only regenerates Objective-C metadata files from existing generatedJSON.
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
    case "-p", "--pretty":
      options.prettyPrintJSON = true
    case "--json-only":
      options.jsonOnly = true
    case "--pack-only":
      options.packOnly = true
    case "--dry-run":
      options.dryRun = true
    case "-v", "--version":
      index += 1
      guard index < arguments.count else {
        throw ScriptError.invalidArguments("\(argument) requires a version value")
      }
      options.ref = arguments[index]
    default:
      if argument.hasPrefix("-v"), argument.count > 2 {
        options.ref = String(argument.dropFirst(2))
      } else if argument.hasPrefix("--version=") {
        options.ref = String(argument.dropFirst("--version=".count))
      } else if argument.hasPrefix("-") {
        throw ScriptError.invalidArguments("Unknown argument: \(argument)\n\n\(usage())")
      } else if options.ref == nil {
        options.ref = argument
      } else {
        throw ScriptError.invalidArguments("Unexpected extra argument: \(argument)\n\n\(usage())")
      }
    }

    index += 1
  }

  if options.packOnly {
    return options
  }

  guard options.ref != nil else {
    throw ScriptError.invalidArguments("Must specify a metadata version, branch, commit, or 'master'.\n\n\(usage())")
  }

  return options
}

func isNumericVersion(_ value: String) -> Bool {
  let pattern = #"^\d+(\.\d+){0,2}$"#
  return value.range(of: pattern, options: .regularExpression) != nil
}

func normalizedGitRef(_ value: String) -> String {
  let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
  if isNumericVersion(trimmed) {
    return "v\(trimmed)"
  }

  if trimmed.hasPrefix("v") {
    let version = String(trimmed.dropFirst())
    if isNumericVersion(version) {
      return trimmed
    }
  }

  return trimmed
}

func absoluteURL(forPath path: String) -> URL {
  if path.hasPrefix("/") {
    return URL(fileURLWithPath: path)
  }

  return URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    .appendingPathComponent(path)
    .standardizedFileURL
}

let scriptURL = absoluteURL(forPath: CommandLine.arguments[0])
let scriptsDirectory = scriptURL.deletingLastPathComponent()
let repositoryRoot = scriptsDirectory.deletingLastPathComponent()
let generatedJSONDirectory = repositoryRoot.appendingPathComponent("generatedJSON")

func rawMetadataURL(ref: String, fileName: String) -> URL {
  return URL(string: "https://raw.githubusercontent.com/google/libphonenumber/\(ref)/javascript/i18n/phonenumbers/\(fileName)")!
}

func runSection<T>(_ name: String, block: () throws -> T) rethrows -> T {
  print("\(name)... ", terminator: "")
  let result = try block()
  print("Done")
  return result
}

func downloadString(from url: URL, attempts: Int = 3) throws -> String {
  var lastError: Error?

  for attempt in 1...attempts {
    let semaphore = DispatchSemaphore(value: 0)
    var resultData: Data?
    var resultResponse: URLResponse?
    var resultError: Error?

    var request = URLRequest(url: url)
    request.timeoutInterval = 60
    request.setValue("libPhoneNumber-iOS metadataGenerator", forHTTPHeaderField: "User-Agent")

    let task = URLSession.shared.dataTask(with: request) { data, response, error in
      resultData = data
      resultResponse = response
      resultError = error
      semaphore.signal()
    }
    task.resume()
    semaphore.wait()

    if let error = resultError {
      lastError = error
    } else if let httpResponse = resultResponse as? HTTPURLResponse {
      guard (200...299).contains(httpResponse.statusCode) else {
        lastError = ScriptError.downloadFailed(url, "HTTP \(httpResponse.statusCode)")
        if httpResponse.statusCode == 404 {
          break
        }
        sleep(UInt32(attempt))
        continue
      }

      guard let data = resultData else {
        throw ScriptError.invalidResponse(url)
      }

      guard let string = String(data: data, encoding: .utf8) else {
        throw ScriptError.invalidUTF8(url)
      }

      return string
    } else {
      throw ScriptError.invalidResponse(url)
    }

    if attempt < attempts {
      sleep(UInt32(attempt))
    }
  }

  throw ScriptError.downloadFailed(url, lastError?.localizedDescription ?? "unknown error")
}

func metadataJSONString(from javaScript: String, variable: String) throws -> String {
  let context = JSContext()!
  var exceptionMessage: String?

  context.exceptionHandler = { _, exception in
    exceptionMessage = exception?.toString() ?? "unknown JavaScript exception"
  }

  context.evaluateScript("""
    var __metadataGlobal = this;
    var goog = {
      provide: function(name) {
        var parts = name.split('.');
        var cursor = __metadataGlobal;
        for (var i = 0; i < parts.length; i++) {
          if (typeof cursor[parts[i]] !== 'object' || cursor[parts[i]] === null) {
            cursor[parts[i]] = {};
          }
          cursor = cursor[parts[i]];
        }
      },
      require: function(_) {}
    };
    var i18n = { phonenumbers: {} };
  """)

  if let exceptionMessage {
    throw ScriptError.javascriptException(exceptionMessage)
  }

  context.evaluateScript(javaScript)

  if let exceptionMessage {
    throw ScriptError.javascriptException(exceptionMessage)
  }

  guard let value = context.evaluateScript("JSON.stringify(\(variable))"),
        !value.isUndefined,
        !value.isNull,
        let result = value.toString(),
        result != "undefined" else {
    throw ScriptError.missingJavaScriptValue(variable)
  }

  return result + "\n"
}

func jsonData(from jsonString: String) throws -> Data {
  guard let data = jsonString.data(using: .utf8) else {
    throw ScriptError.invalidJSON("Could not encode JSON string as UTF-8")
  }

  try validateMetadataJSON(data)
  return data
}

func validateMetadataJSON(_ data: Data) throws {
  let object = try JSONSerialization.jsonObject(with: data, options: [])
  guard let dictionary = object as? [String: Any] else {
    throw ScriptError.invalidJSON("top-level object is not a dictionary")
  }

  guard dictionary["countryCodeToRegionCodeMap"] is [String: Any] else {
    throw ScriptError.invalidJSON("missing countryCodeToRegionCodeMap")
  }

  guard dictionary["countryToMetadata"] is [String: Any] else {
    throw ScriptError.invalidJSON("missing countryToMetadata")
  }
}

func prettyPrintedJSONData(from compactJSONData: Data) throws -> Data {
  let object = try JSONSerialization.jsonObject(with: compactJSONData, options: [])
  return try JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys])
    + Data("\n".utf8)
}

func write(_ data: Data, to url: URL, dryRun: Bool) throws {
  if dryRun {
    print("  would write \(url.path) (\(data.count) bytes)")
    return
  }

  try FileManager.default.createDirectory(
    at: url.deletingLastPathComponent(),
    withIntermediateDirectories: true
  )
  try data.write(to: url, options: .atomic)
  print("  wrote \(url.path) (\(data.count) bytes)")
}

func readExistingJSONFiles() throws -> [String: Data] {
  var result: [String: Data] = [:]

  for source in MetadataSource.allCases {
    let url = generatedJSONDirectory.appendingPathComponent(source.jsonFileName)
    let data = try Data(contentsOf: url)
    try validateMetadataJSON(data)
    result[source.jsonFileName] = data
  }

  return result
}

func gzipData(_ data: Data) throws -> Data {
  let tempDirectory = FileManager.default.temporaryDirectory
    .appendingPathComponent("libPhoneNumber-metadata-\(UUID().uuidString)", isDirectory: true)
  try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
  defer { try? FileManager.default.removeItem(at: tempDirectory) }

  let inputURL = tempDirectory.appendingPathComponent("metadata.json")
  try data.write(to: inputURL, options: .atomic)

  let process = Process()
  process.executableURL = URL(fileURLWithPath: "/usr/bin/gzip")
  process.arguments = ["-n", "-c", inputURL.path]

  let standardOutput = Pipe()
  let standardError = Pipe()
  process.standardOutput = standardOutput
  process.standardError = standardError

  try process.run()
  let compressedData = standardOutput.fileHandleForReading.readDataToEndOfFile()
  let errorData = standardError.fileHandleForReading.readDataToEndOfFile()
  process.waitUntilExit()

  guard process.terminationStatus == 0 else {
    let errorText = String(data: errorData, encoding: .utf8) ?? "unknown gzip error"
    throw ScriptError.processFailed("gzip failed: \(errorText)")
  }

  return compressedData
}

func cByteArray(name: String, data: Data) -> String {
  let bytes = [UInt8](data)
  var lines: [String] = ["z_const Bytef \(name)[] = {"]

  for start in stride(from: 0, to: bytes.count, by: 12) {
    let end = min(start + 12, bytes.count)
    let values = bytes[start..<end].map { String(format: "0x%02x", $0) }.joined(separator: ", ")
    lines.append("  \(values),")
  }

  lines.append("};")
  return lines.joined(separator: "\n")
}

func generatedHeader(jsonFileName: String, byteArrayName: String, compressedLengthName: String, expandedLengthName: String) -> Data {
  return Data("""
  /*****
   * Data generated by scripts/metadataGenerator.swift
   * From \(jsonFileName)
   */

  #include <zlib.h>

  // z_const is not defined in some versions of zlib, so define it here
  // in case it has not been defined.
  #if defined(ZLIB_CONST) && !defined(z_const)
  #  define z_const const
  #else
  #  define z_const
  #endif

  extern z_const Bytef \(byteArrayName)[];
  extern z_const size_t \(compressedLengthName);
  extern z_const size_t \(expandedLengthName);
  """.utf8)
}

func generatedImplementation(
  headerName: String,
  jsonFileName: String,
  byteArrayName: String,
  compressedLengthName: String,
  expandedLengthName: String,
  jsonData: Data
) throws -> Data {
  let compressedData = try gzipData(jsonData)
  return Data("""
  /*****
   * Data generated by scripts/metadataGenerator.swift
   * From \(jsonFileName)
   */

  #include "\(headerName)"

  \(cByteArray(name: byteArrayName, data: compressedData))
  z_const size_t \(compressedLengthName) = sizeof(\(byteArrayName));
  z_const size_t \(expandedLengthName) = \(jsonData.count);
  """.utf8)
}

func generateObjectiveCMetadataFiles(from jsonFiles: [String: Data], dryRun: Bool) throws {
  let phoneJSON = jsonFiles[MetadataSource.phoneNumber.jsonFileName]!
  let testingJSON = jsonFiles[MetadataSource.phoneNumberForTesting.jsonFileName]!
  let shortJSON = jsonFiles[MetadataSource.shortNumber.jsonFileName]!

  try write(
    generatedHeader(
      jsonFileName: MetadataSource.phoneNumber.jsonFileName,
      byteArrayName: "kPhoneNumberMetaData",
      compressedLengthName: "kPhoneNumberMetaDataCompressedLength",
      expandedLengthName: "kPhoneNumberMetaDataExpandedLength"
    ),
    to: repositoryRoot.appendingPathComponent("libPhoneNumberInternal/NBGeneratedPhoneNumberMetaData.h"),
    dryRun: dryRun
  )

  try write(
    generatedImplementation(
      headerName: "NBGeneratedPhoneNumberMetaData.h",
      jsonFileName: MetadataSource.phoneNumber.jsonFileName,
      byteArrayName: "kPhoneNumberMetaData",
      compressedLengthName: "kPhoneNumberMetaDataCompressedLength",
      expandedLengthName: "kPhoneNumberMetaDataExpandedLength",
      jsonData: phoneJSON
    ),
    to: repositoryRoot.appendingPathComponent("libPhoneNumber/NBGeneratedPhoneNumberMetaData.m"),
    dryRun: dryRun
  )

  try write(
    generatedHeader(
      jsonFileName: MetadataSource.shortNumber.jsonFileName,
      byteArrayName: "kShortNumberMetaData",
      compressedLengthName: "kShortNumberMetaDataCompressedLength",
      expandedLengthName: "kShortNumberMetaDataExpandedLength"
    ),
    to: repositoryRoot.appendingPathComponent("libPhoneNumberShortNumberInternal/NBGeneratedShortNumberMetaData.h"),
    dryRun: dryRun
  )

  try write(
    generatedImplementation(
      headerName: "NBGeneratedShortNumberMetaData.h",
      jsonFileName: MetadataSource.shortNumber.jsonFileName,
      byteArrayName: "kShortNumberMetaData",
      compressedLengthName: "kShortNumberMetaDataCompressedLength",
      expandedLengthName: "kShortNumberMetaDataExpandedLength",
      jsonData: shortJSON
    ),
    to: repositoryRoot.appendingPathComponent("libPhoneNumberShortNumber/NBGeneratedShortNumberMetaData.m"),
    dryRun: dryRun
  )

  try write(
    gzipData(testingJSON),
    to: repositoryRoot.appendingPathComponent("libPhoneNumberTestsCommon/libPhoneNumberMetaDataForTesting.zip"),
    dryRun: dryRun
  )

  try write(
    Data("""
    /*****
     * Data generated by scripts/metadataGenerator.swift
     * From \(MetadataSource.phoneNumberForTesting.jsonFileName)
     */

    #include <zlib.h>

    // z_const is not defined in some versions of zlib, so define it here
    // in case it has not been defined.
    #if defined(ZLIB_CONST) && !defined(z_const)
    #  define z_const const
    #else
    #  define z_const
    #endif

    extern z_const size_t kPhoneNumberMetaDataForTestingExpandedLength;
    """.utf8),
    to: repositoryRoot.appendingPathComponent("libPhoneNumberTestsCommon/NBTestingMetaData.h"),
    dryRun: dryRun
  )

  try write(
    Data("""
    #include "NBTestingMetaData.h"

    z_const size_t kPhoneNumberMetaDataForTestingExpandedLength = \(testingJSON.count);
    """.utf8),
    to: repositoryRoot.appendingPathComponent("libPhoneNumberTestsCommon/NBTestingMetaData.m"),
    dryRun: dryRun
  )
}

func downloadMetadataJSONFiles(ref: String) throws -> [String: Data] {
  var result: [String: Data] = [:]

  for source in MetadataSource.allCases {
    let url = rawMetadataURL(ref: ref, fileName: source.remoteFileName)
    let script = try runSection("Downloading \(source.displayName)") {
      try downloadString(from: url)
    }

    let jsonString = try runSection("Processing \(source.displayName)") {
      try metadataJSONString(from: script, variable: source.jsVariable)
    }

    result[source.jsonFileName] = try jsonData(from: jsonString)
  }

  return result
}

func writeJSONFiles(_ jsonFiles: [String: Data], prettyPrint: Bool, dryRun: Bool) throws {
  for source in MetadataSource.allCases {
    let compactData = jsonFiles[source.jsonFileName]!
    let outputData = prettyPrint ? try prettyPrintedJSONData(from: compactData) : compactData
    let url = generatedJSONDirectory.appendingPathComponent(source.jsonFileName)
    try write(outputData, to: url, dryRun: dryRun)
  }
}

func main() throws {
  let options = try parseArguments(CommandLine.arguments)

  if options.packOnly {
    let jsonFiles = try runSection("Reading existing generatedJSON files") {
      try readExistingJSONFiles()
    }
    try runSection(options.dryRun ? "Validating generated Objective-C metadata outputs" : "Generating Objective-C metadata outputs") {
      try generateObjectiveCMetadataFiles(from: jsonFiles, dryRun: options.dryRun)
    }
    print("\nMetadata packing completed successfully.\n")
    return
  }

  let ref = normalizedGitRef(options.ref!)
  print("Using google/libphonenumber ref: \(ref)")

  let jsonFiles = try downloadMetadataJSONFiles(ref: ref)

  if !options.jsonOnly {
    try runSection(options.dryRun ? "Validating generated Objective-C metadata outputs" : "Generating Objective-C metadata outputs") {
      try generateObjectiveCMetadataFiles(from: jsonFiles, dryRun: options.dryRun)
    }
  }

  try runSection(options.dryRun ? "Validating generatedJSON outputs" : "Writing generatedJSON outputs") {
    try writeJSONFiles(jsonFiles, prettyPrint: options.prettyPrintJSON, dryRun: options.dryRun)
  }

  if options.prettyPrintJSON && !options.jsonOnly {
    printWarning("generatedJSON was written pretty-printed after embedded metadata was generated from compact JSON.")
  }

  print("\nMetadata update completed successfully.\n")
}

do {
  try main()
} catch {
  printError("\(error)")
  exit(1)
}
