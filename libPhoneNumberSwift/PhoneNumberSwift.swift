import Foundation
#if canImport(libPhoneNumber)
import libPhoneNumber
#elseif canImport(libPhoneNumber_iOS)
import libPhoneNumber_iOS
#endif

#if canImport(libPhoneNumberGeocoding)
import libPhoneNumberGeocoding
#endif

#if canImport(libPhoneNumberShortNumber)
import libPhoneNumberShortNumber
#endif

public typealias PhoneNumber = NBPhoneNumber

public enum PhoneNumberError: Error {
    case operationFailed(String)

    static func fallback(_ operation: String) -> PhoneNumberError {
        .operationFailed("\(operation) failed without an NSError.")
    }
}

public enum PhoneNumberFormat: Int {
    case e164 = 0
    case international = 1
    case national = 2
    case rfc3966 = 3

    var objcValue: NBEPhoneNumberFormat {
        NBEPhoneNumberFormat(rawValue: rawValue)!
    }
}

public enum PhoneNumberType: Int, Equatable {
    case fixedLine = 0
    case mobile = 1
    case fixedLineOrMobile = 2
    case tollFree = 3
    case premiumRate = 4
    case sharedCost = 5
    case voip = 6
    case personalNumber = 7
    case pager = 8
    case uan = 9
    case voicemail = 10
    case unknown = -1

    init(_ objcValue: NBEPhoneNumberType) {
        self = PhoneNumberType(rawValue: objcValue.rawValue) ?? .unknown
    }

    var objcValue: NBEPhoneNumberType {
        NBEPhoneNumberType(rawValue: rawValue)!
    }
}

public enum ValidationResult: Int, Equatable {
    case isPossible = 0
    case invalidCountryCode = 1
    case tooShort = 2
    case tooLong = 3
    case isPossibleLocalOnly = 4
    case invalidLength = 5
    case unknown = 6

    init(_ objcValue: NBEValidationResult) {
        self = ValidationResult(rawValue: objcValue.rawValue) ?? .unknown
    }
}

public enum MatchType: Int, Equatable {
    case notANumber = 0
    case noMatch = 1
    case shortNSNMatch = 2
    case nsnMatch = 3
    case exactMatch = 4

    init(_ objcValue: NBEMatchType) {
        self = MatchType(rawValue: objcValue.rawValue) ?? .notANumber
    }
}

public enum CountryCodeSource: Int, Equatable {
    case fromNumberWithPlusSign = 1
    case fromNumberWithIDD = 5
    case fromNumberWithoutPlusSign = 10
    case fromDefaultCountry = 20

    init(_ objcValue: NBECountryCodeSource) {
        self = CountryCodeSource(rawValue: objcValue.rawValue) ?? .fromNumberWithPlusSign
    }
}

public enum ShortNumberCost: UInt, Equatable {
    case unknown = 0
    case tollFree = 1
    case standardRate = 2
    case premiumRate = 3

    init(_ objcValue: NBEShortNumberCost) {
        self = ShortNumberCost(rawValue: objcValue.rawValue) ?? .unknown
    }
}

public final class PhoneNumberUtility {
    public static let shared = PhoneNumberUtility()

    public let objc: NBPhoneNumberUtil

    public init(objc: NBPhoneNumberUtil = NBPhoneNumberUtil.sharedInstance()) {
        self.objc = objc
    }

    public var supportedRegions: [String] {
        (objc.getSupportedRegions() as? [String]) ?? []
    }

    public var supportedCallingCodes: [Int] {
        objc.getSupportedCallingCodes().map(\.intValue)
    }

    public var supportedGlobalNetworkCallingCodes: [Int] {
        objc.getSupportedGlobalNetworkCallingCodes().map(\.intValue)
    }

    public func parse(_ number: String?, defaultRegion: String?) throws -> PhoneNumber {
        try objc.parse(number, defaultRegion: defaultRegion)
    }

    public func parseAndKeepRawInput(_ number: String, defaultRegion: String?) throws -> PhoneNumber {
        try objc.parseAndKeepRawInput(number, defaultRegion: defaultRegion)
    }

    public func parseWithCarrierRegion(_ number: String?) throws -> PhoneNumber {
        try objc.parse(withPhoneCarrierRegion: number)
    }

    public func format(_ number: PhoneNumber, as format: PhoneNumberFormat) throws -> String {
        try objc.format(number, numberFormat: format.objcValue)
    }

    public func formatForMobileDialing(
        _ number: PhoneNumber,
        regionCallingFrom: String,
        withFormatting: Bool
    ) throws -> String {
        try objc.formatNumber(
            forMobileDialing: number,
            regionCallingFrom: regionCallingFrom,
            withFormatting: withFormatting
        )
    }

    public func formatOutOfCountryCallingNumber(
        _ number: PhoneNumber,
        regionCallingFrom: String
    ) throws -> String {
        try objc.formatOut(
            ofCountryCalling: number,
            regionCallingFrom: regionCallingFrom
        )
    }

    public func isValidNumber(_ number: PhoneNumber) -> Bool {
        objc.isValidNumber(number)
    }

    public func isValidNumber(_ number: PhoneNumber, forRegion regionCode: String) -> Bool {
        objc.isValidNumber(forRegion: number, regionCode: regionCode)
    }

    public func isPossibleNumber(_ number: PhoneNumber) -> Bool {
        objc.isPossibleNumber(number)
    }

    public func isPossibleNumber(_ number: PhoneNumber, for type: PhoneNumberType) -> Bool {
        objc.isPossibleNumber(number, for: type.objcValue)
    }

    public func possibleNumberReason(_ number: PhoneNumber) throws -> ValidationResult {
        var error: NSError?
        let result = objc.isPossibleNumber(withReason: number, error: &error)
        if let error {
            throw error
        }
        return ValidationResult(result)
    }

    public func possibleNumberReason(_ number: PhoneNumber, for type: PhoneNumberType) -> ValidationResult {
        ValidationResult(objc.isPossibleNumber(withReason: number, for: type.objcValue))
    }

    public func type(of number: PhoneNumber) -> PhoneNumberType {
        PhoneNumberType(objc.getNumberType(number))
    }

    public func nationalSignificantNumber(for number: PhoneNumber) -> String {
        objc.getNationalSignificantNumber(number)
    }

    public func regionCode(for number: PhoneNumber) -> String? {
        objc.getRegionCode(for: number)
    }

    public func countryCode(forRegion regionCode: String?) -> Int {
        objc.getCountryCode(forRegion: regionCode).intValue
    }

    public func regionCode(forCountryCode countryCallingCode: Int) -> String {
        objc.getRegionCode(forCountryCode: NSNumber(value: countryCallingCode))
    }

    public func regionCodes(forCountryCode countryCallingCode: Int) -> [String] {
        (objc.getRegionCodes(forCountryCode: NSNumber(value: countryCallingCode)) as? [String]) ?? []
    }

    public func exampleNumber(forRegion regionCode: String) throws -> PhoneNumber {
        try objc.getExampleNumber(regionCode)
    }

    public func exampleNumber(forRegion regionCode: String, type: PhoneNumberType) throws -> PhoneNumber {
        try objc.getExampleNumber(forType: regionCode, type: type.objcValue)
    }

    public func exampleNumber(forNonGeographicalEntity countryCallingCode: Int) throws -> PhoneNumber {
        try objc.getExampleNumber(forNonGeoEntity: NSNumber(value: countryCallingCode))
    }

    public func numberMatch(_ first: Any, _ second: Any) throws -> MatchType {
        var error: NSError?
        let match = objc.isNumberMatch(first, second: second, error: &error)
        if let error {
            throw error
        }
        return MatchType(match)
    }

    public func truncateIfTooLong(_ number: PhoneNumber) -> Bool {
        objc.truncateTooLong(number)
    }

    public func normalized(_ number: String) -> String {
        objc.normalize(number)
    }

    public func digitsOnly(_ number: String) -> String {
        objc.normalizeDigitsOnly(number)
    }

    public func diallableCharactersOnly(_ number: String) -> String {
        objc.normalizeDiallableCharsOnly(number)
    }
}

public final class AsYouTypeFormatter {
    public let objc: NBAsYouTypeFormatter

    public init(regionCode: String) {
        self.objc = NBAsYouTypeFormatter(regionCode: regionCode)
    }

    public var rememberedPosition: Int {
        objc.getRememberedPosition()
    }

    public var isSuccessfulFormatting: Bool {
        objc.isSuccessfulFormatting
    }

    public func input(_ string: String) -> String {
        objc.inputString(string)
    }

    public func inputAndRememberPosition(_ string: String) -> String {
        objc.inputStringAndRememberPosition(string)
    }

    public func inputDigit(_ digit: String) -> String {
        objc.inputDigit(digit)
    }

    public func inputDigitAndRememberPosition(_ digit: String) -> String {
        objc.inputDigitAndRememberPosition(digit)
    }

    public func removeLastDigit() -> String {
        objc.removeLastDigit()
    }

    public func removeLastDigitAndRememberPosition() -> String {
        objc.removeLastDigitAndRememberPosition()
    }

    public func clear() {
        objc.clear()
    }
}

public final class ShortNumberUtility {
    public static let shared = ShortNumberUtility()

    public let objc: NBShortNumberUtil

    public init(objc: NBShortNumberUtil = NBShortNumberUtil.sharedInstance()) {
        self.objc = objc
    }

    public var supportedRegions: [String] {
        objc.getSupportedRegions()
    }

    public func exampleShortNumber(forRegion regionCode: String?) -> String {
        objc.getExampleShortNumber(regionCode)
    }

    public func exampleShortNumber(forRegion regionCode: String, cost: ShortNumberCost) -> String {
        objc.getExampleShortNumber(forRegion: regionCode, cost: NBEShortNumberCost(rawValue: cost.rawValue)!)
    }

    public func isPossibleShortNumber(_ number: PhoneNumber) -> Bool {
        objc.isPossibleShortNumber(number)
    }

    public func isPossibleShortNumber(_ number: PhoneNumber, forRegion regionCode: String) -> Bool {
        objc.isPossibleShortNumber(number, forRegion: regionCode)
    }

    public func isValidShortNumber(_ number: PhoneNumber) -> Bool {
        objc.isValidShortNumber(number)
    }

    public func isValidShortNumber(_ number: PhoneNumber, forRegion regionCode: String) -> Bool {
        objc.isValidShortNumber(number, forRegion: regionCode)
    }

    public func expectedCost(of number: PhoneNumber) -> ShortNumberCost {
        ShortNumberCost(objc.expectedCost(of: number))
    }

    public func expectedCost(of number: PhoneNumber, forRegion regionCode: String) -> ShortNumberCost {
        ShortNumberCost(objc.expectedCost(of: number, forRegion: regionCode))
    }

    public func isCarrierSpecific(_ number: PhoneNumber) -> Bool {
        objc.isPhoneNumberCarrierSpecific(number)
    }

    public func isCarrierSpecific(_ number: PhoneNumber, forRegion regionCode: String) -> Bool {
        objc.isPhoneNumberCarrierSpecific(number, forRegion: regionCode)
    }

    public func isSMSService(_ number: PhoneNumber, forRegion regionCode: String) -> Bool {
        objc.isPhoneNumberSMSService(number, forRegion: regionCode)
    }

    public func connectsToEmergencyNumber(_ number: String, forRegion regionCode: String) -> Bool {
        objc.connectsToEmergencyNumber(from: number, forRegion: regionCode)
    }

    public func isEmergencyNumber(_ number: String, forRegion regionCode: String) -> Bool {
        objc.isEmergencyNumber(number, forRegion: regionCode)
    }
}

public final class PhoneNumberGeocoder {
    public static let shared = PhoneNumberGeocoder()

    public let objc: NBPhoneNumberOfflineGeocoder

    public init(objc: NBPhoneNumberOfflineGeocoder = NBPhoneNumberOfflineGeocoder.sharedInstance()) {
        self.objc = objc
    }

    public func description(forValidNumber number: PhoneNumber, languageCode: String) -> String? {
        objc.description(forValidNumber: number, withLanguageCode: languageCode)
    }

    public func description(forValidNumber number: PhoneNumber, languageCode: String, userRegion: String) -> String? {
        objc.description(forValidNumber: number, withLanguageCode: languageCode, withUserRegion: userRegion)
    }

    public func description(for number: PhoneNumber, languageCode: String) -> String? {
        objc.description(for: number, withLanguageCode: languageCode)
    }

    public func description(for number: PhoneNumber, languageCode: String, userRegion: String) -> String? {
        objc.description(for: number, withLanguageCode: languageCode, withUserRegion: userRegion)
    }

    public func description(for number: PhoneNumber) -> String? {
        objc.description(for: number)
    }

    public func description(for number: PhoneNumber, userRegion: String) -> String? {
        objc.description(for: number, withUserRegion: userRegion)
    }
}
