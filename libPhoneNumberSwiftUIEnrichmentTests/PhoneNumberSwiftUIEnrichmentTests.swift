import XCTest
import libPhoneNumberSwiftCore
import libPhoneNumberSwiftUI
import libPhoneNumberSwiftUIEnrichment

final class PhoneNumberSwiftUIEnrichmentTests: XCTestCase {
    func testFormatterStateIncludesCarrierAndTimeZones() {
        let formatter = PhoneNumberFieldFormatter(
            enricher: CarrierTimeZonesPhoneNumberEnricher(localeCode: "en")
        )

        let state = formatter.state(for: "+244 917 654 321", defaultRegion: "AO")

        XCTAssertEqual("+244917654321", state.e164)
        XCTAssertEqual("AO", state.regionCode)
        XCTAssertEqual("Movicel", state.enrichment?.carrierName)
        XCTAssertEqual(["Africa/Luanda"], state.enrichment?.timeZones)
    }

    func testPortableRegionCarrierNameIsNotDisplayed() {
        let formatter = PhoneNumberFieldFormatter(
            enricher: CarrierTimeZonesPhoneNumberEnricher(localeCode: "en")
        )

        let state = formatter.state(for: "+44 7387 654321", defaultRegion: "GB")

        XCTAssertEqual("GB", state.regionCode)
        XCTAssertNil(state.enrichment?.carrierName)
        XCTAssertEqual(
            ["Europe/Guernsey", "Europe/Isle_of_Man", "Europe/Jersey", "Europe/London"],
            state.enrichment?.timeZones
        )
    }
}
