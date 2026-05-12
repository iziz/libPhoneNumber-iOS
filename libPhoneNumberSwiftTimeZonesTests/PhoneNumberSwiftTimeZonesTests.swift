import XCTest
import libPhoneNumberSwiftCore
import libPhoneNumberSwiftTimeZones

final class PhoneNumberSwiftTimeZonesTests: XCTestCase {
    func testTimeZonesForNumber() throws {
        let number = try PhoneNumberUtility.shared.parse("6509600000", defaultRegion: "US")

        XCTAssertEqual(["America/Los_Angeles"], PhoneNumberTimeZonesMapper.shared.timeZones(for: number))
    }

    func testInvalidNumberReturnsUnknown() throws {
        let number = PhoneNumber()
        number.countryCode = 999
        number.nationalNumber = 2_423_651_234

        XCTAssertEqual(
            [PhoneNumberTimeZonesMapper.unknownTimeZone],
            PhoneNumberTimeZonesMapper.shared.timeZones(for: number)
        )
    }
}
