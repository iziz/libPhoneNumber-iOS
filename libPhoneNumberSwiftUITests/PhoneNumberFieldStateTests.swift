import Foundation
import Testing
import libPhoneNumberSwiftCore
import libPhoneNumberSwiftUI

@Suite("Phone number field state")
struct PhoneNumberFieldStateTests {
    private let formatter = PhoneNumberFieldFormatter()

    @Test("A valid number produces a complete state with no error")
    func validNumber() {
        let state = formatter.state(for: "6502530000", defaultRegion: "US")

        #expect(state.e164 == "+16502530000")
        #expect(state.regionCode == "US")
        #expect(state.type == .fixedLineOrMobile)
        #expect(state.isValid)
        #expect(state.isPossible)
        #expect(state.validationResult == .isPossible)
        #expect(state.error == nil)
    }

    /// The state carries the error raised by the Objective-C core, so callers
    /// keep access to its domain and code.
    @Test("An unparseable entry reports the underlying error")
    func underlyingError() {
        let state = formatter.state(for: "abc", defaultRegion: "US")

        #expect(state.e164 == nil)
        #expect(!state.isValid)

        let error = state.error as NSError?
        #expect(error != nil)
        #expect(error?.localizedDescription.isEmpty == false)
    }

    @Test("States compare equal when their contents match")
    func equatable() {
        let first = formatter.state(for: "6502530000", defaultRegion: "US")
        let second = formatter.state(for: "6502530000", defaultRegion: "US")
        let third = formatter.state(for: "2125551234", defaultRegion: "US")

        #expect(first == second)
        #expect(first != third)
    }

    @Test("Errors compare equal too, so a repeated bad entry does not churn state")
    func equatableErrors() {
        #expect(formatter.state(for: "abc", defaultRegion: "US") == formatter.state(for: "abc", defaultRegion: "US"))
    }

    @Test("As-you-type formatting is applied progressively")
    func progressiveFormatting() {
        #expect(formatter.formattedText(for: "650", defaultRegion: "US") == "650")
        #expect(formatter.formattedText(for: "6502", defaultRegion: "US") == "650-2")
        #expect(formatter.formattedText(for: "6502530000", defaultRegion: "US") == "(650) 253-0000")
    }

    /// PhoneNumberFieldState holds an existential Error and is deliberately not
    /// Sendable. Use PhoneNumberValue, which is, for anything that leaves the
    /// field's concurrency domain.
    @Test("The value derived from a state crosses concurrency domains")
    func valueIsSendable() async throws {
        let state = formatter.state(for: "6502530000", defaultRegion: "US")
        let e164 = try #require(state.e164)
        let value = try PhoneNumberUtility.shared
            .value(from: e164, defaultRegion: state.regionCode)
            .get()

        let echoed = await Task { value }.value

        #expect(echoed == value)
    }
}
