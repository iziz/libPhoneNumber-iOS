import XCTest
import libPhoneNumberSwiftUI

final class PhoneNumberSwiftUITests: XCTestCase {
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
        XCTAssertTrue(state.isPossible)
        XCTAssertTrue(state.isValid)
        XCTAssertNil(state.error)
    }

    func testFormatterReportsInvalidInput() {
        let formatter = PhoneNumberFieldFormatter()
        let state = formatter.state(for: "abc", defaultRegion: "US")

        XCTAssertNil(state.e164)
        XCTAssertFalse(state.isPossible)
        XCTAssertFalse(state.isValid)
        XCTAssertNotNil(state.error)
    }
}
