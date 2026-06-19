#!/usr/bin/env swift

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

struct TestFunction {
  let file: String
  let name: String
}

let upstreamTestFiles = [
  "javascript/i18n/phonenumbers/phonenumberutil_test.js",
  "javascript/i18n/phonenumbers/asyoutypeformatter_test.js",
  "javascript/i18n/phonenumbers/shortnumberinfo_test.js",
]

let localTestFiles = [
  "libPhoneNumberTests/NBPhoneNumberUtilTest.m",
  "libPhoneNumberTests/NBAsYouTypeFormatterTest.m",
  "libPhoneNumberShortNumberTests/NBShortNumberInfoTest.m",
]

func usage() -> Never {
  fputs("""
  Usage:
    scripts/checkUpstreamTestParity.swift [--upstream-ref <ref>] [--upstream-dir <path>]

  Compares Google libphonenumber JS test function names with the local ObjC test methods.
  By default it reads upstream tests from google/libphonenumber master.

  """, stderr)
  exit(2)
}

var upstreamRef = "master"
var upstreamDir: String?
var args = Array(CommandLine.arguments.dropFirst())
while !args.isEmpty {
  let arg = args.removeFirst()
  switch arg {
  case "--upstream-ref":
    guard !args.isEmpty else { usage() }
    upstreamRef = args.removeFirst()
  case "--upstream-dir":
    guard !args.isEmpty else { usage() }
    upstreamDir = args.removeFirst()
  case "--help", "-h":
    usage()
  default:
    fputs("Unknown argument: \(arg)\n", stderr)
    usage()
  }
}

let repoRoot = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
var cachedRawUpstreamRef: String?

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

func downloadData(from url: URL) throws -> Data {
  var request = URLRequest(url: url)
  request.timeoutInterval = 60
  request.setValue("libPhoneNumber-iOS checkUpstreamTestParity", forHTTPHeaderField: "User-Agent")
  if url.host == "api.github.com" {
    request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
    request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
    if let token = githubAPIToken() {
      request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }
  }

  let semaphore = DispatchSemaphore(value: 0)
  var resultData: Data?
  var resultResponse: URLResponse?
  var resultError: Error?

  URLSession.shared.dataTask(with: request) { data, response, error in
    resultData = data
    resultResponse = response
    resultError = error
    semaphore.signal()
  }.resume()
  semaphore.wait()

  if let resultError {
    throw resultError
  }
  guard let httpResponse = resultResponse as? HTTPURLResponse,
        (200..<300).contains(httpResponse.statusCode),
        let resultData else {
    throw URLError(.badServerResponse)
  }
  return resultData
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
  let refResponse = try JSONDecoder().decode(GitHubRefResponse.self, from: downloadData(from: refURL))

  guard refResponse.object.type == "tag",
        let tagURLString = refResponse.object.url,
        let tagURL = URL(string: tagURLString) else {
    return refResponse.object.sha
  }

  let tagResponse = try JSONDecoder().decode(GitHubTagResponse.self, from: downloadData(from: tagURL))
  return tagResponse.object.type == "commit" ? tagResponse.object.sha : refResponse.object.sha
}

func rawUpstreamRef() throws -> String {
  if let cachedRawUpstreamRef {
    return cachedRawUpstreamRef
  }
  let resolved = try resolvedRawGitRef(upstreamRef)
  cachedRawUpstreamRef = resolved
  return resolved
}

func readUTF8(_ path: String) throws -> String {
  if path.hasPrefix("libPhoneNumber") {
    return try String(contentsOf: repoRoot.appendingPathComponent(path), encoding: .utf8)
  }

  if let upstreamDir {
    let fileName = URL(fileURLWithPath: path).lastPathComponent
    let url = URL(fileURLWithPath: upstreamDir).appendingPathComponent(fileName)
    return try String(contentsOf: url, encoding: .utf8)
  }

  let rawRef = try rawUpstreamRef()
  let escapedRef = rawRef.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? rawRef
  let url = URL(string: "https://raw.githubusercontent.com/google/libphonenumber/\(escapedRef)/\(path)")!
  return try String(contentsOf: url, encoding: .utf8)
}

func matches(in text: String, pattern: String, file: String) throws -> [TestFunction] {
  let regex = try NSRegularExpression(pattern: pattern)
  let range = NSRange(text.startIndex..<text.endIndex, in: text)
  return regex.matches(in: text, range: range).compactMap { match in
    guard let nameRange = Range(match.range(at: 1), in: text) else { return nil }
    return TestFunction(file: file, name: String(text[nameRange]))
  }
}

func normalized(_ testName: String) -> String {
  var value = testName
  if value.hasPrefix("test") {
    value.removeFirst(4)
  }
  return value
    .lowercased()
    .replacingOccurrences(of: "_", with: "")
    .replacingOccurrences(of: "normalise", with: "normalize")
    .replacingOccurrences(of: "geographical", with: "geographic")
    .replacingOccurrences(of: "dialling", with: "dialing")
}

do {
  let upstreamTests = try upstreamTestFiles.flatMap { file in
    try matches(in: readUTF8(file), pattern: #"function\s+(test[A-Za-z0-9_]+)"#, file: file)
  }
  let localTests = try localTestFiles.flatMap { file in
    try matches(in: readUTF8(file), pattern: #"-\s*\(void\)\s*(test[A-Za-z0-9_]+)"#, file: file)
  }

  let localNames = Set(localTests.map { normalized($0.name) })
  let missing = upstreamTests.filter { !localNames.contains(normalized($0.name)) }

  print("Upstream JS tests: \(upstreamTests.count)")
  print("Local ObjC tests: \(localTests.count)")

  if missing.isEmpty {
    print("Parity check passed: no upstream JS test names are missing locally.")
    exit(0)
  }

  print("Missing upstream JS tests:")
  for test in missing {
    print("- \(URL(fileURLWithPath: test.file).lastPathComponent): \(test.name)")
  }
  exit(1)
} catch {
  fputs("Parity check failed: \(error)\n", stderr)
  exit(1)
}
