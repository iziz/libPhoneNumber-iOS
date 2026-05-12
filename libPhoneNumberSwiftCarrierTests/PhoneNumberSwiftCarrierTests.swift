import XCTest
import libPhoneNumberSwiftCarrier
import libPhoneNumberSwiftCore

final class PhoneNumberSwiftCarrierTests: XCTestCase {
    func testCarrierNameForNumber() throws {
        let number = try PhoneNumberUtility.shared.parse("+447387654321", defaultRegion: nil)

        XCTAssertEqual("Vodafone", PhoneNumberCarrierMapper.shared.name(for: number, localeCode: "en"))
    }

    func testEmptyCarrierNameMapsToNil() throws {
        let number = try PhoneNumberUtility.shared.parse("+442071234567", defaultRegion: nil)

        XCTAssertNil(PhoneNumberCarrierMapper.shared.name(for: number, localeCode: "en"))
    }

    func testSafeDisplayNameMapsPortableRegionToNil() throws {
        let number = try PhoneNumberUtility.shared.parse("+447387654321", defaultRegion: nil)

        XCTAssertNil(PhoneNumberCarrierMapper.shared.safeDisplayName(for: number, localeCode: "en"))
    }
}
