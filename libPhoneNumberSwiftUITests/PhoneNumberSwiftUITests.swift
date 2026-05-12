import XCTest
import libPhoneNumberSwiftCore
import libPhoneNumberSwiftUI

final class PhoneNumberSwiftUITests: XCTestCase {
    private struct StubEnricher: PhoneNumberEnriching {
        func enrichment(for number: PhoneNumber, regionCode: String?) -> PhoneNumberEnrichment {
            PhoneNumberEnrichment(carrierName: "Test Carrier", timeZones: ["Etc/Test"])
        }
    }

    func testFormatterUsesAsYouTypeFormatting() {
        let formatter = PhoneNumberFieldFormatter()

        XCTAssertEqual("(650) 253-0000", formatter.formattedText(for: "6502530000", defaultRegion: "US"))
    }

    func testFormatterReturnsE164ValidationState() {
        let formatter = PhoneNumberFieldFormatter()
        let state = formatter.state(for: "(650) 253-0000", defaultRegion: "US")

        XCTAssertEqual("+16502530000", state.e164)
        XCTAssertEqual("US", state.regionCode)
        XCTAssertEqual(.fixedLineOrMobile, state.type)
        XCTAssertEqual(.isPossible, state.validationResult)
        XCTAssertNil(state.enrichment)
        XCTAssertTrue(state.isPossible)
        XCTAssertTrue(state.isValid)
        XCTAssertNil(state.error)
    }

    func testFormatterReportsInvalidInput() {
        let formatter = PhoneNumberFieldFormatter()
        let state = formatter.state(for: "abc", defaultRegion: "US")

        XCTAssertNil(state.e164)
        XCTAssertNil(state.enrichment)
        XCTAssertFalse(state.isPossible)
        XCTAssertFalse(state.isValid)
        XCTAssertNotNil(state.error)
    }

    func testFormatterUsesOptionalEnricher() {
        let formatter = PhoneNumberFieldFormatter(enricher: StubEnricher())
        let state = formatter.state(for: "(650) 253-0000", defaultRegion: "US")

        XCTAssertEqual("Test Carrier", state.enrichment?.carrierName)
        XCTAssertEqual(["Etc/Test"], state.enrichment?.timeZones)
    }
}
