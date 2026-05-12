import XCTest
import libPhoneNumberSwiftCore
import libPhoneNumberSwiftShortNumber

final class PhoneNumberSwiftShortNumberTests: XCTestCase {
    func testShortNumberUtilityFacade() throws {
        let phoneUtil = PhoneNumberUtility.shared
        let shortUtil = ShortNumberUtility.shared
        let number = try phoneUtil.parse("911", defaultRegion: "US")

        XCTAssertTrue(shortUtil.isPossibleShortNumber(number))
        XCTAssertTrue(shortUtil.isValidShortNumber(number, forRegion: "US"))
        XCTAssertTrue(shortUtil.connectsToEmergencyNumber("911", forRegion: "US"))
        XCTAssertEqual(.tollFree, shortUtil.expectedCost(of: number, forRegion: "US"))
    }
}
