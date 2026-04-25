import XCTest
import libPhoneNumberSwift

final class PhoneNumberSwiftTests: XCTestCase {
    func testPhoneNumberUtilityParsesAndFormats() throws {
        let util = PhoneNumberUtility.shared
        let number = try util.parse("6502530000", defaultRegion: "US")

        XCTAssertTrue(util.isValidNumber(number))
        XCTAssertEqual(.fixedLineOrMobile, util.type(of: number))
        XCTAssertEqual("+16502530000", try util.format(number, as: .e164))
        XCTAssertEqual("6502530000", util.nationalSignificantNumber(for: number))
        XCTAssertEqual("US", util.regionCode(for: number))
    }

    func testAsYouTypeFormatterFacade() {
        let formatter = AsYouTypeFormatter(regionCode: "US")

        XCTAssertEqual("6", formatter.inputDigit("6"))
        XCTAssertEqual("65", formatter.inputDigit("5"))
        XCTAssertEqual("650", formatter.inputDigit("0"))
        XCTAssertEqual("650-2", formatter.inputDigit("2"))
    }

    func testShortNumberUtilityFacade() throws {
        let phoneUtil = PhoneNumberUtility.shared
        let shortUtil = ShortNumberUtility.shared
        let number = try phoneUtil.parse("911", defaultRegion: "US")

        XCTAssertTrue(shortUtil.isPossibleShortNumber(number))
        XCTAssertTrue(shortUtil.isValidShortNumber(number, forRegion: "US"))
        XCTAssertTrue(shortUtil.connectsToEmergencyNumber("911", forRegion: "US"))
        XCTAssertEqual(.tollFree, shortUtil.expectedCost(of: number, forRegion: "US"))
    }

    func testGeocoderFacade() throws {
        let util = PhoneNumberUtility.shared
        let geocoder = PhoneNumberGeocoder.shared
        let number = try util.parse("16502530000", defaultRegion: "US")

        XCTAssertEqual("United States", geocoder.description(for: number, languageCode: "en"))
    }
}
