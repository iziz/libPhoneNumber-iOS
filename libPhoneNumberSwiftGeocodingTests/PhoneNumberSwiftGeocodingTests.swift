import XCTest
import libPhoneNumberSwiftCore
import libPhoneNumberSwiftGeocoding

final class PhoneNumberSwiftGeocodingTests: XCTestCase {
    func testGeocoderFacade() throws {
        let util = PhoneNumberUtility.shared
        let geocoder = PhoneNumberGeocoder.shared
        let number = try util.parse("16502530000", defaultRegion: "US")

        XCTAssertEqual("United States", geocoder.description(for: number, languageCode: "en"))
    }
}
