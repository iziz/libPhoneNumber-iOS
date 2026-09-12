import Testing
import libPhoneNumber
import libPhoneNumberSwiftCore

/// The Swift facade mirrors the Objective-C enums by raw value rather than by
/// an exhaustive switch, so a case added or renumbered upstream would silently
/// map to the wrong Swift case. These tests pin every pairing.
@Suite("Objective-C enum bridging")
struct PhoneNumberBridgingTests {
    @Test("Phone number formats map to their Objective-C raw values")
    func formatRawValues() {
        #expect(PhoneNumberFormat.e164.rawValue == NBEPhoneNumberFormat.E164.rawValue)
        #expect(PhoneNumberFormat.international.rawValue == NBEPhoneNumberFormat.INTERNATIONAL.rawValue)
        #expect(PhoneNumberFormat.national.rawValue == NBEPhoneNumberFormat.NATIONAL.rawValue)
        #expect(PhoneNumberFormat.rfc3966.rawValue == NBEPhoneNumberFormat.RFC3966.rawValue)
    }

    @Test("Phone number types map to their Objective-C raw values")
    func typeRawValues() {
        let pairs: [(PhoneNumberType, NBEPhoneNumberType)] = [
            (.fixedLine, .FIXED_LINE),
            (.mobile, .MOBILE),
            (.fixedLineOrMobile, .FIXED_LINE_OR_MOBILE),
            (.tollFree, .TOLL_FREE),
            (.premiumRate, .PREMIUM_RATE),
            (.sharedCost, .SHARED_COST),
            (.voip, .VOIP),
            (.personalNumber, .PERSONAL_NUMBER),
            (.pager, .PAGER),
            (.uan, .UAN),
            (.voicemail, .VOICEMAIL),
            (.unknown, .UNKNOWN),
        ]

        for (swift, objc) in pairs {
            #expect(swift.rawValue == objc.rawValue, "\(swift) should mirror \(objc.rawValue)")
        }
    }

    @Test("Validation results map to their Objective-C raw values")
    func validationResultRawValues() {
        let pairs: [(ValidationResult, NBEValidationResult)] = [
            (.isPossible, .IS_POSSIBLE),
            (.invalidCountryCode, .INVALID_COUNTRY_CODE),
            (.tooShort, .TOO_SHORT),
            (.tooLong, .TOO_LONG),
            (.isPossibleLocalOnly, .IS_POSSIBLE_LOCAL_ONLY),
            (.invalidLength, .INVALID_LENGTH),
            (.unknown, .UNKNOWN),
        ]

        for (swift, objc) in pairs {
            #expect(swift.rawValue == objc.rawValue, "\(swift) should mirror \(objc.rawValue)")
        }
    }

    @Test("Match types map to their Objective-C raw values")
    func matchTypeRawValues() {
        let pairs: [(MatchType, NBEMatchType)] = [
            (.notANumber, .NOT_A_NUMBER),
            (.noMatch, .NO_MATCH),
            (.shortNSNMatch, .SHORT_NSN_MATCH),
            (.nsnMatch, .NSN_MATCH),
            (.exactMatch, .EXACT_MATCH),
        ]

        for (swift, objc) in pairs {
            #expect(swift.rawValue == objc.rawValue, "\(swift) should mirror \(objc.rawValue)")
        }
    }

    @Test("Country code sources map to their Objective-C raw values")
    func countryCodeSourceRawValues() {
        let pairs: [(CountryCodeSource, NBECountryCodeSource)] = [
            (.fromNumberWithPlusSign, .FROM_NUMBER_WITH_PLUS_SIGN),
            (.fromNumberWithIDD, .FROM_NUMBER_WITH_IDD),
            (.fromNumberWithoutPlusSign, .FROM_NUMBER_WITHOUT_PLUS_SIGN),
            (.fromDefaultCountry, .FROM_DEFAULT_COUNTRY),
        ]

        for (swift, objc) in pairs {
            #expect(swift.rawValue == objc.rawValue, "\(swift) should mirror \(objc.rawValue)")
        }
    }

    /// `objcValue` force-unwraps the Objective-C initializer, so a Swift case
    /// without a matching Objective-C case would trap at runtime instead of
    /// failing to compile.
    @Test("Every Swift format and type survives a round trip through Objective-C")
    func roundTripThroughObjectiveC() throws {
        let util = PhoneNumberUtility.shared
        let number = try util.parse("6502530000", defaultRegion: "US")

        for format in [PhoneNumberFormat.e164, .international, .national, .rfc3966] {
            #expect(throws: Never.self) { try util.format(number, as: format) }
        }

        for type in [PhoneNumberType.fixedLine, .mobile, .fixedLineOrMobile, .tollFree,
                     .premiumRate, .sharedCost, .voip, .personalNumber, .pager, .uan,
                     .voicemail, .unknown] {
            _ = util.isPossibleNumber(number, for: type)
        }
    }
}

@Suite("Error reporting")
struct PhoneNumberErrorTests {
    @Test("Unparseable text is reported as invalidInput")
    func invalidInput() {
        let result = PhoneNumberUtility.shared.value(from: "not a number", defaultRegion: "US")

        guard case let .failure(error) = result else {
            Issue.record("Expected a failure for unparseable text")
            return
        }
        guard case .invalidInput = error else {
            Issue.record("Expected .invalidInput, got \(error)")
            return
        }
        #expect(error.errorDescription?.isEmpty == false)
    }

    @Test("Errors from the Objective-C core are wrapped as underlying")
    func underlyingWrapping() {
        let objcError = NSError(
            domain: "NBPhoneNumberUtil",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "NOT_A_NUMBER"]
        )

        #expect(PhoneNumberValueError(objcError) == .underlying("NOT_A_NUMBER"))
    }

    @Test("A value that cannot round-trip reports the failure instead of trapping")
    func brokenRoundTrip() {
        let value = PhoneNumberValue(
            e164: "+0",
            regionCode: nil,
            nationalSignificantNumber: "0",
            type: .unknown
        )

        guard case .failure = PhoneNumberUtility.shared.phoneNumber(from: value) else {
            Issue.record("Expected a failure for an unparseable E.164 value")
            return
        }
    }
}
