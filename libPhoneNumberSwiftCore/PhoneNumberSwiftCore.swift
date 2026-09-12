import Foundation
#if canImport(libPhoneNumber)
import libPhoneNumber
#elseif canImport(libPhoneNumber_iOS)
import libPhoneNumber_iOS
#endif

/// A parsed phone number.
///
/// This is the Objective-C model object. It is a mutable reference type and is
/// therefore not `Sendable`: do not share one instance across concurrency
/// domains. Use ``PhoneNumberValue`` for anything that crosses an actor
/// boundary, gets stored, or is sent over the wire.
public typealias PhoneNumber = NBPhoneNumber

@available(*, deprecated, message: "Unused. Every throwing API reports failures as PhoneNumberValueError or the underlying NSError. This type will be removed in the next major version.")
public enum PhoneNumberError: Error {
    case operationFailed(String)

    static func fallback(_ operation: String) -> PhoneNumberError {
        .operationFailed("\(operation) failed without an NSError.")
    }
}

/// The error reported by every non-throwing `Result`-returning API on
/// ``PhoneNumberUtility``.
public enum PhoneNumberValueError: Error, Equatable, Sendable {
    /// The text could not be parsed as a phone number.
    case invalidInput(String)
    /// The number parsed, but could not be rendered in the requested format.
    case formattingFailed(String)
    /// An error raised by the Objective-C core, flattened to its description.
    case underlying(String)

    /// Wraps an arbitrary error thrown by the Objective-C core.
    public init(_ error: Error) {
        self = .underlying(error.localizedDescription)
    }
}

extension PhoneNumberValueError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case let .invalidInput(message),
             let .formattingFailed(message),
             let .underlying(message):
            return message
        }
    }
}

public struct PhoneNumberValue: Codable, Hashable, Sendable {
    public let e164: String
    public let regionCode: String?
    public let nationalSignificantNumber: String
    public let type: PhoneNumberType

    public init(
        e164: String,
        regionCode: String?,
        nationalSignificantNumber: String,
        type: PhoneNumberType
    ) {
        self.e164 = e164
        self.regionCode = regionCode
        self.nationalSignificantNumber = nationalSignificantNumber
        self.type = type
    }
}

public enum PhoneNumberFormat: Int, Codable, Sendable {
    case e164 = 0
    case international = 1
    case national = 2
    case rfc3966 = 3

    var objcValue: NBEPhoneNumberFormat {
        NBEPhoneNumberFormat(rawValue: rawValue)!
    }
}

public enum PhoneNumberType: Int, Codable, Sendable {
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

public enum ValidationResult: Int, Codable, Sendable {
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

public enum MatchType: Int, Codable, Sendable {
    case notANumber = 0
    case noMatch = 1
    case shortNSNMatch = 2
    case nsnMatch = 3
    case exactMatch = 4

    init(_ objcValue: NBEMatchType) {
        self = MatchType(rawValue: objcValue.rawValue) ?? .notANumber
    }
}

public enum CountryCodeSource: Int, Codable, Sendable {
    case fromNumberWithPlusSign = 1
    case fromNumberWithIDD = 5
    case fromNumberWithoutPlusSign = 10
    case fromDefaultCountry = 20

    init(_ objcValue: NBECountryCodeSource) {
        self = CountryCodeSource(rawValue: objcValue.rawValue) ?? .fromNumberWithPlusSign
    }
}

/// The Objective-C core this facade wraps is safe to share across threads: its
/// regular-expression caches are lock-protected, its derived metadata tables are
/// built under a lock, and every table it reads is immutable after
/// initialization. Sendable is therefore asserted rather than checked, because
/// the compiler cannot see the Objective-C side's locking.
public final class PhoneNumberUtility: @unchecked Sendable {
    public static let shared = PhoneNumberUtility()

    /// The wrapped Objective-C utility.
    ///
    /// Exposed as an escape hatch for APIs this facade does not surface yet.
    /// Prefer the Swift methods on this type; anything reachable only through
    /// `objc` is not covered by the facade's source-stability guarantees.
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

    public func parseResult(_ number: String?, defaultRegion: String?) -> Result<PhoneNumber, Error> {
        Result {
            try parse(number, defaultRegion: defaultRegion)
        }
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

    public func value(from number: PhoneNumber) -> Result<PhoneNumberValue, PhoneNumberValueError> {
        guard let e164 = try? format(number, as: .e164) else {
            return .failure(.formattingFailed("Unable to format phone number as E.164."))
        }

        return .success(
            PhoneNumberValue(
                e164: e164,
                regionCode: regionCode(for: number),
                nationalSignificantNumber: nationalSignificantNumber(for: number),
                type: type(of: number)
            )
        )
    }

    public func value(from text: String, defaultRegion: String?) -> Result<PhoneNumberValue, PhoneNumberValueError> {
        do {
            let number = try parse(text, defaultRegion: defaultRegion)
            return value(from: number)
        } catch {
            return .failure(.invalidInput(error.localizedDescription))
        }
    }

    public func phoneNumber(from value: PhoneNumberValue) -> Result<PhoneNumber, PhoneNumberValueError> {
        do {
            return .success(try parse(value.e164, defaultRegion: nil))
        } catch {
            return .failure(PhoneNumberValueError(error))
        }
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

/// Formats a number as the user types it.
///
/// Each formatter carries the digits entered so far, so it is a stateful object
/// and deliberately not `Sendable`. Create one per input field and keep its use
/// on a single concurrency domain.
public final class AsYouTypeFormatter {
    /// The wrapped Objective-C formatter. See ``PhoneNumberUtility/objc`` for
    /// how this escape hatch is meant to be used.
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
