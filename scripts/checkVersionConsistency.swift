#!/usr/bin/env swift

import Foundation

struct Version: Comparable, Hashable, CustomStringConvertible {
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

  static func < (lhs: Version, rhs: Version) -> Bool {
    if lhs.major != rhs.major {
      return lhs.major < rhs.major
    }
    if lhs.minor != rhs.minor {
      return lhs.minor < rhs.minor
    }
    return lhs.patch < rhs.patch
  }
}

struct Dependency {
  let name: String
  let requirement: String
}

struct Podspec {
  let fileName: String
  let name: String
  let version: Version
  let dependencies: [Dependency]
}

let expectedPodspecFiles = [
  "libPhoneNumber-iOS.podspec",
  "libPhoneNumberGeocoding.podspec",
  "libPhoneNumberShortNumber.podspec",
  "libPhoneNumber-iOS-SwiftCore.podspec",
  "libPhoneNumber-iOS-SwiftGeocoding.podspec",
  "libPhoneNumber-iOS-SwiftShortNumber.podspec",
  "libPhoneNumber-iOS-SwiftUI.podspec",
  "libPhoneNumber-iOS-Swift.podspec",
]

let expectedPackageProducts = [
  "libPhoneNumber": "libPhoneNumber",
  "libPhoneNumberGeocoding": "libPhoneNumberGeocoding",
  "libPhoneNumberShortNumber": "libPhoneNumberShortNumber",
  "libPhoneNumberSwiftCore": "libPhoneNumberSwiftCore",
  "libPhoneNumberSwiftGeocoding": "libPhoneNumberSwiftGeocoding",
  "libPhoneNumberSwiftShortNumber": "libPhoneNumberSwiftShortNumber",
  "libPhoneNumberSwiftUI": "libPhoneNumberSwiftUI",
  "libPhoneNumberIOSSwift": "libPhoneNumberIOSSwift",
]

let expectedInternalDependencies = [
  "libPhoneNumberGeocoding": ["libPhoneNumber-iOS"],
  "libPhoneNumberShortNumber": ["libPhoneNumber-iOS"],
  "libPhoneNumber-iOS-Swift": [
    "libPhoneNumber-iOS-SwiftCore",
    "libPhoneNumber-iOS-SwiftGeocoding",
    "libPhoneNumber-iOS-SwiftShortNumber",
  ],
  "libPhoneNumber-iOS-SwiftCore": ["libPhoneNumber-iOS"],
  "libPhoneNumber-iOS-SwiftGeocoding": [
    "libPhoneNumber-iOS-SwiftCore",
    "libPhoneNumberGeocoding",
  ],
  "libPhoneNumber-iOS-SwiftShortNumber": [
    "libPhoneNumber-iOS-SwiftCore",
    "libPhoneNumberShortNumber",
  ],
  "libPhoneNumber-iOS-SwiftUI": ["libPhoneNumber-iOS-SwiftCore"],
]

let repoRoot = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
var failures: [String] = []

func readUTF8(_ relativePath: String) -> String? {
  let url = repoRoot.appendingPathComponent(relativePath)
  return try? String(contentsOf: url, encoding: .utf8)
}

func firstCapture(in text: String, pattern: String) -> String? {
  guard let regex = try? NSRegularExpression(pattern: pattern, options: [.anchorsMatchLines]) else {
    return nil
  }
  let range = NSRange(text.startIndex..., in: text)
  guard let match = regex.firstMatch(in: text, range: range),
        match.numberOfRanges > 1,
        let captureRange = Range(match.range(at: 1), in: text) else {
    return nil
  }
  return String(text[captureRange])
}

func captures(in text: String, pattern: String) -> [[String]] {
  guard let regex = try? NSRegularExpression(pattern: pattern, options: [.anchorsMatchLines]) else {
    return []
  }
  let range = NSRange(text.startIndex..., in: text)
  return regex.matches(in: text, range: range).map { match in
    (1..<match.numberOfRanges).compactMap { index in
      guard let captureRange = Range(match.range(at: index), in: text) else {
        return nil
      }
      return String(text[captureRange])
    }
  }
}

func parsePodspec(_ fileName: String) -> Podspec? {
  guard let text = readUTF8(fileName) else {
    failures.append("Missing podspec: \(fileName)")
    return nil
  }

  guard let name = firstCapture(in: text, pattern: #"^\s*s\.name\s*=\s*["']([^"']+)["']"#) else {
    failures.append("\(fileName): missing s.name")
    return nil
  }

  guard let rawVersion = firstCapture(in: text, pattern: #"^\s*s\.version\s*=\s*["']([^"']+)["']"#),
        let version = Version(rawVersion) else {
    failures.append("\(fileName): missing or invalid semantic s.version")
    return nil
  }

  let dependencies = captures(
    in: text,
    pattern: #"^\s*s\.dependency\s+["']([^"']+)["']\s*,\s*["']~>\s*([^"']+)["']"#
  ).compactMap { capture -> Dependency? in
    guard capture.count == 2 else {
      return nil
    }
    return Dependency(name: capture[0], requirement: capture[1])
  }

  return Podspec(fileName: fileName, name: name, version: version, dependencies: dependencies)
}

func packageProducts() -> [String: String] {
  guard let text = readUTF8("Package.swift"),
        let regex = try? NSRegularExpression(
          pattern: #"\.library\(\s*name:\s*"([^"]+)"\s*,\s*targets:\s*\[\s*"([^"]+)"\s*\]"#,
          options: [.dotMatchesLineSeparators]
        ) else {
    failures.append("Package.swift: unable to parse library products")
    return [:]
  }

  let range = NSRange(text.startIndex..., in: text)
  var products: [String: String] = [:]
  for match in regex.matches(in: text, range: range) {
    guard let productRange = Range(match.range(at: 1), in: text),
          let targetRange = Range(match.range(at: 2), in: text) else {
      continue
    }
    products[String(text[productRange])] = String(text[targetRange])
  }
  return products
}

func readmePodRequirements() -> [String: String] {
  guard let text = readUTF8("README.md") else {
    failures.append("README.md: missing")
    return [:]
  }

  var requirements: [String: String] = [:]
  for capture in captures(in: text, pattern: #"pod\s+["']([^"']+)["']\s*,\s*["']~>\s*([^"']+)["']"#) {
    guard capture.count == 2 else {
      continue
    }
    requirements[capture[0]] = capture[1]
  }
  return requirements
}

let podspecs = expectedPodspecFiles.compactMap(parsePodspec)
let podspecsByName = Dictionary(uniqueKeysWithValues: podspecs.map { ($0.name, $0) })

if podspecs.count == expectedPodspecFiles.count {
  let versions = Set(podspecs.map(\.version))
  if versions.count != 1 {
    let formatted = podspecs.map { "\($0.name)=\($0.version)" }.sorted().joined(separator: ", ")
    failures.append("Podspec versions are not aligned: \(formatted)")
  }

  let canonicalVersion = podspecs[0].version
  for podspec in podspecs {
    guard let expectedDependencies = expectedInternalDependencies[podspec.name] else {
      continue
    }

    let actualDependencies = Dictionary(uniqueKeysWithValues: podspec.dependencies.map { ($0.name, $0.requirement) })
    for dependencyName in expectedDependencies {
      guard let requirement = actualDependencies[dependencyName] else {
        failures.append("\(podspec.fileName): missing dependency on \(dependencyName)")
        continue
      }

      guard let dependencyVersion = Version(requirement), dependencyVersion == canonicalVersion else {
        failures.append("\(podspec.fileName): dependency \(dependencyName) uses ~> \(requirement), expected ~> \(canonicalVersion)")
        continue
      }
    }
  }

  let readmeRequirements = readmePodRequirements()
  for podspec in podspecs {
    guard let readmeRequirement = readmeRequirements[podspec.name] else {
      failures.append("README.md: missing CocoaPods example for \(podspec.name)")
      continue
    }

    if readmeRequirement != canonicalVersion.minorRange {
      failures.append("README.md: \(podspec.name) uses ~> \(readmeRequirement), expected ~> \(canonicalVersion.minorRange)")
    }
  }
}

let products = packageProducts()
for (product, target) in expectedPackageProducts.sorted(by: { $0.key < $1.key }) {
  guard let actualTarget = products[product] else {
    failures.append("Package.swift: missing library product \(product)")
    continue
  }
  if actualTarget != target {
    failures.append("Package.swift: product \(product) targets \(actualTarget), expected \(target)")
  }
}

for fileName in expectedPodspecFiles {
  let expectedName = fileName.replacingOccurrences(of: ".podspec", with: "")
  if podspecsByName[expectedName] == nil {
    failures.append("\(fileName): expected s.name to be \(expectedName)")
  }
}

if failures.isEmpty {
  let version = podspecs.first?.version.description ?? "unknown"
  print("Version consistency check passed for \(version).")
  exit(0)
}

fputs("Version consistency check failed:\n", stderr)
for failure in failures {
  fputs("- \(failure)\n", stderr)
}
exit(1)
