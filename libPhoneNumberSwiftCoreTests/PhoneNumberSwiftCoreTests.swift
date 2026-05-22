import XCTest
import libPhoneNumberSwiftCore

final class PhoneNumberSwiftCoreTests: XCTestCase {
    func testPhoneNumberUtilityParsesAndFormatsWithoutOptionalModules() throws {
        let util = PhoneNumberUtility.shared
        let number = try util.parse("6502530000", defaultRegion: "US")

        XCTAssertTrue(util.isValidNumber(number))
        XCTAssertEqual(.fixedLineOrMobile, util.type(of: number))
        XCTAssertEqual("+16502530000", try util.format(number, as: .e164))
        XCTAssertEqual("6502530000", util.nationalSignificantNumber(for: number))
        XCTAssertEqual("US", util.regionCode(for: number))
    }

    func testUganda794MobileRangeFromIssue447() throws {
        let util = PhoneNumberUtility.shared
        let number = try util.parse("+25679(4)123456", defaultRegion: nil)

        XCTAssertEqual("UG", util.regionCode(for: number))
        XCTAssertTrue(util.isValidNumber(number))
        XCTAssertTrue(util.isValidNumber(number, forRegion: "UG"))
        XCTAssertEqual(.mobile, util.type(of: number))
        XCTAssertEqual("794123456", util.nationalSignificantNumber(for: number))
        XCTAssertEqual("+256794123456", try util.format(number, as: .e164))
    }

    func testAsYouTypeFormatterFacade() {
        let formatter = AsYouTypeFormatter(regionCode: "US")

        XCTAssertEqual("6", formatter.inputDigit("6"))
        XCTAssertEqual("65", formatter.inputDigit("5"))
        XCTAssertEqual("650", formatter.inputDigit("0"))
        XCTAssertEqual("650-2", formatter.inputDigit("2"))
    }

    func testPhoneNumberValueIsCodableAndRoundTripsThroughCore() throws {
        let util = PhoneNumberUtility.shared
        let result = util.value(from: "6502530000", defaultRegion: "US")
        let value = try XCTUnwrap(result.get())

        XCTAssertEqual("+16502530000", value.e164)
        XCTAssertEqual("US", value.regionCode)
        XCTAssertEqual("6502530000", value.nationalSignificantNumber)
        XCTAssertEqual(.fixedLineOrMobile, value.type)

        let encoded = try JSONEncoder().encode(value)
        let decoded = try JSONDecoder().decode(PhoneNumberValue.self, from: encoded)
        let number = try XCTUnwrap(util.phoneNumber(from: decoded).get())

        XCTAssertEqual("+16502530000", try util.format(number, as: .e164))
    }

    func testPhoneNumberValueReportsInvalidInputWithoutThrowing() {
        let util = PhoneNumberUtility.shared

        guard case .failure(.invalidInput) = util.value(from: "abc", defaultRegion: "US") else {
            return XCTFail("Expected invalidInput failure")
        }
    }
}
