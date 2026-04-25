#!/usr/bin/env swift

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

struct UpstreamMethod: Comparable {
  let component: String
  let name: String
  let file: String

  static func < (lhs: UpstreamMethod, rhs: UpstreamMethod) -> Bool {
    if lhs.component != rhs.component {
      return lhs.component < rhs.component
    }
    return lhs.name < rhs.name
  }
}

struct LocalMethod {
  let component: String
  let selector: String
}

let upstreamSourceFiles = [
  "javascript/i18n/phonenumbers/phonenumberutil.js",
  "javascript/i18n/phonenumbers/asyoutypeformatter.js",
  "javascript/i18n/phonenumbers/shortnumberinfo.js",
]

let localHeaderFiles = [
  "PhoneNumberUtil": "libPhoneNumber/NBPhoneNumberUtil.h",
  "AsYouTypeFormatter": "libPhoneNumber/NBAsYouTypeFormatter.h",
  "ShortNumberInfo": "libPhoneNumberShortNumber/NBShortNumberUtil.h",
]

let acceptedObjCSelectors: [String: [String]] = [
  "PhoneNumberUtil.canBeInternationallyDialled": ["canBeInternationallyDiallederror"],
  "PhoneNumberUtil.extractCountryCode": ["extractCountryCodenationalNumber"],
  "PhoneNumberUtil.format": ["formatnumberFormaterror"],
  "PhoneNumberUtil.formatByPattern": ["formatByPatternnumberFormatuserDefinedFormatserror"],
  "PhoneNumberUtil.formatInOriginalFormat": ["formatInOriginalFormatregionCallingFromerror"],
  "PhoneNumberUtil.formatNationalNumberWithCarrierCode": ["formatNationalNumberWithCarrierCodecarrierCodeerror"],
  "PhoneNumberUtil.formatNationalNumberWithPreferredCarrierCode": ["formatNationalNumberWithPreferredCarrierCodefallbackCarrierCodeerror"],
  "PhoneNumberUtil.formatNumberForMobileDialing": ["formatNumberForMobileDialingregionCallingFromwithFormattingerror"],
  "PhoneNumberUtil.formatOutOfCountryCallingNumber": ["formatOutOfCountryCallingNumberregionCallingFromerror"],
  "PhoneNumberUtil.formatOutOfCountryKeepingAlphaChars": ["formatOutOfCountryKeepingAlphaCharsregionCallingFromerror"],
  "PhoneNumberUtil.getExampleNumber": ["getExampleNumbererror"],
  "PhoneNumberUtil.getExampleNumberForNonGeoEntity": ["getExampleNumberForNonGeoEntityerror"],
  "PhoneNumberUtil.getExampleNumberForType": ["getExampleNumberForTypetypeerror"],
  "PhoneNumberUtil.getLengthOfGeographicalAreaCode": ["getLengthOfGeographicalAreaCodeerror"],
  "PhoneNumberUtil.getLengthOfNationalDestinationCode": ["getLengthOfNationalDestinationCodeerror"],
  "PhoneNumberUtil.getNddPrefixForRegion": ["getNddPrefixForRegionstripNonDigits"],
  "PhoneNumberUtil.isNumberMatch": ["isNumberMatchseconderror"],
  "PhoneNumberUtil.isPossibleNumberForTypeWithReason": ["isPossibleNumberWithReasonforType"],
  "PhoneNumberUtil.isPossibleNumberString": ["isPossibleNumberStringregionDialingFromerror"],
  "PhoneNumberUtil.isPossibleNumberWithReason": ["isPossibleNumberWithReasonerror"],
  "PhoneNumberUtil.isValidNumberForRegion": ["isValidNumberForRegionregionCode"],
  "PhoneNumberUtil.maybeExtractCountryCode": ["maybeExtractCountryCodemetadatanationalNumberkeepRawInputphoneNumbererror"],
  "PhoneNumberUtil.maybeStripInternationalPrefixAndNormalize": ["maybeStripInternationalPrefixAndNormalizepossibleIddPrefix"],
  "PhoneNumberUtil.maybeStripNationalPrefixAndCarrierCode": ["maybeStripNationalPrefixAndCarrierCodemetadatacarrierCode"],
  "PhoneNumberUtil.parse": ["parsedefaultRegionerror"],
  "PhoneNumberUtil.parseAndKeepRawInput": ["parseAndKeepRawInputdefaultRegionerror"],
  "ShortNumberInfo.connectsToEmergencyNumber": ["connectsToEmergencyNumberFromStringforRegion"],
  "ShortNumberInfo.getExampleShortNumberForCost": ["getExampleShortNumberForRegioncost"],
  "ShortNumberInfo.getExpectedCost": ["expectedCostOfPhoneNumber"],
  "ShortNumberInfo.getExpectedCostForRegion": ["expectedCostOfPhoneNumberforRegion"],
  "ShortNumberInfo.isCarrierSpecific": ["isPhoneNumberCarrierSpecific"],
  "ShortNumberInfo.isCarrierSpecificForRegion": ["isPhoneNumberCarrierSpecificforRegion"],
  "ShortNumberInfo.isEmergencyNumber": ["isEmergencyNumberforRegion"],
  "ShortNumberInfo.isPossibleShortNumberForRegion": ["isPossibleShortNumberforRegion"],
  "ShortNumberInfo.isSmsServiceForRegion": ["isPhoneNumberSMSServiceforRegion"],
  "ShortNumberInfo.isValidShortNumberForRegion": ["isValidShortNumberforRegion"],
]

func usage() -> Never {
  fputs("""
  Usage:
    scripts/checkUpstreamAPIParity.swift [--upstream-ref <ref>] [--upstream-dir <path>]

  Compares Google libphonenumber JS public prototype methods with local ObjC public headers.
  By default it reads upstream sources from google/libphonenumber master.

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

func readUTF8(_ path: String) throws -> String {
  if path.hasPrefix("libPhoneNumber") {
    return try String(contentsOf: repoRoot.appendingPathComponent(path), encoding: .utf8)
  }

  if let upstreamDir {
    let fileName = URL(fileURLWithPath: path).lastPathComponent
    let url = URL(fileURLWithPath: upstreamDir).appendingPathComponent(fileName)
    return try String(contentsOf: url, encoding: .utf8)
  }

  let escapedRef = upstreamRef.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? upstreamRef
  let url = URL(string: "https://raw.githubusercontent.com/google/libphonenumber/\(escapedRef)/\(path)")!
  return try String(contentsOf: url, encoding: .utf8)
}

func normalized(_ value: String) -> String {
  value
    .lowercased()
    .replacingOccurrences(of: "_", with: "")
    .replacingOccurrences(of: "geographical", with: "geographic")
    .replacingOccurrences(of: "dialling", with: "dialing")
}

func upstreamMethods(in text: String, file: String) throws -> [UpstreamMethod] {
  let regex = try NSRegularExpression(
    pattern: #"i18n\.phonenumbers\.(PhoneNumberUtil|AsYouTypeFormatter|ShortNumberInfo)\.prototype\s*\.\s*([A-Za-z0-9_]+)\s*=\s*function"#,
    options: [.dotMatchesLineSeparators]
  )
  let range = NSRange(text.startIndex..<text.endIndex, in: text)
  return regex.matches(in: text, range: range).compactMap { match in
    guard
      let componentRange = Range(match.range(at: 1), in: text),
      let nameRange = Range(match.range(at: 2), in: text)
    else {
      return nil
    }

    let name = String(text[nameRange])
    if name.hasSuffix("_") {
      return nil
    }

    return UpstreamMethod(component: String(text[componentRange]), name: name, file: file)
  }
}

func stripComments(_ text: String) throws -> String {
  let blockComments = try NSRegularExpression(pattern: #"/\*.*?\*/"#, options: [.dotMatchesLineSeparators])
  let withoutBlockComments = blockComments.stringByReplacingMatches(
    in: text,
    range: NSRange(text.startIndex..<text.endIndex, in: text),
    withTemplate: ""
  )
  let lineComments = try NSRegularExpression(pattern: #"//.*"#)
  return lineComments.stringByReplacingMatches(
    in: withoutBlockComments,
    range: NSRange(withoutBlockComments.startIndex..<withoutBlockComments.endIndex, in: withoutBlockComments),
    withTemplate: ""
  )
}

func selectorName(from declaration: String) throws -> String? {
  let compact = declaration
    .replacingOccurrences(of: "\n", with: " ")
    .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)

  let labelRegex = try NSRegularExpression(pattern: #"([A-Za-z_][A-Za-z0-9_]*)\s*:"#)
  let range = NSRange(compact.startIndex..<compact.endIndex, in: compact)
  let labels = labelRegex.matches(in: compact, range: range).compactMap { match -> String? in
    guard let labelRange = Range(match.range(at: 1), in: compact) else { return nil }
    return String(compact[labelRange])
  }
  if !labels.isEmpty {
    return labels.joined()
  }

  let noArgRegex = try NSRegularExpression(pattern: #"[-+]\s*\([^)]*\)\s*([A-Za-z_][A-Za-z0-9_]*)"#)
  guard
    let match = noArgRegex.firstMatch(in: compact, range: range),
    let nameRange = Range(match.range(at: 1), in: compact)
  else {
    return nil
  }
  return String(compact[nameRange])
}

func localMethods(component: String, headerPath: String) throws -> [LocalMethod] {
  let text = try stripComments(readUTF8(headerPath))
  let regex = try NSRegularExpression(pattern: #"[-+]\s*\([^)]*\)\s*[^;]+;"#, options: [.dotMatchesLineSeparators])
  let range = NSRange(text.startIndex..<text.endIndex, in: text)
  return try regex.matches(in: text, range: range).compactMap { match in
    guard let declarationRange = Range(match.range, in: text) else { return nil }
    guard let selector = try selectorName(from: String(text[declarationRange])) else { return nil }
    return LocalMethod(component: component, selector: selector)
  }
}

do {
  let upstream = try upstreamSourceFiles
    .flatMap { file in try upstreamMethods(in: readUTF8(file), file: file) }
    .sorted()

  let localByComponent = try Dictionary(uniqueKeysWithValues: localHeaderFiles.map { component, header in
    let methods = try localMethods(component: component, headerPath: header)
    return (component, Set(methods.map { normalized($0.selector) }))
  })

  let missing = upstream.filter { method in
    let localNames = localByComponent[method.component, default: []]
    let key = "\(method.component).\(method.name)"
    let acceptedNames = [method.name] + (acceptedObjCSelectors[key] ?? [])
    return !acceptedNames.map(normalized).contains { localNames.contains($0) }
  }

  let localCount = localByComponent.values.reduce(0) { $0 + $1.count }
  print("Upstream JS public prototype methods: \(upstream.count)")
  print("Local ObjC public selectors: \(localCount)")

  if missing.isEmpty {
    print("API parity check passed: no tracked upstream JS public methods are missing locally.")
    exit(0)
  }

  print("Missing upstream JS public methods:")
  for method in missing {
    print("- \(method.component).\(method.name) (\(URL(fileURLWithPath: method.file).lastPathComponent))")
  }
  exit(1)
} catch {
  fputs("API parity check failed: \(error)\n", stderr)
  exit(1)
}
