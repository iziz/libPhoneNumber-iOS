import Testing
import libPhoneNumberSwiftCore

/// `PhoneNumberUtility` is declared `@unchecked Sendable` on the strength of the
/// Objective-C core's internal locking. These tests exercise the shared
/// instance from many tasks at once so that claim is checked rather than merely
/// asserted. Run them under the thread sanitizer (`swift test --sanitize=thread`)
/// to catch races the assertions alone would miss.
@Suite("Concurrent use of the shared utility")
struct PhoneNumberConcurrencyTests {
    private static let samples: [(text: String, region: String, e164: String)] = [
        ("6502530000", "US", "+16502530000"),
        ("01065431234", "KR", "+821065431234"),
        ("2071234567", "GB", "+442071234567"),
        ("0301234567", "DE", "+49301234567"),
        ("0612345678", "FR", "+33612345678"),
        ("0312345678", "JP", "+81312345678"),
        ("1112345678", "CN", "+861112345678"),
        ("0412345678", "AU", "+61412345678"),
    ]

    @Test("Parsing and formatting concurrently produces the same results as serially")
    func concurrentParsing() async {
        let samples = Self.samples

        let results = await withTaskGroup(of: [String].self) { group in
            for _ in 0..<32 {
                group.addTask {
                    // NBPhoneNumber is a mutable reference type, so it stays
                    // inside the task. Only the formatted strings escape.
                    samples.compactMap { sample in
                        let util = PhoneNumberUtility.shared
                        guard let number = try? util.parse(sample.text, defaultRegion: sample.region),
                              let e164 = try? util.format(number, as: .e164) else {
                            return nil
                        }
                        return e164
                    }
                }
            }

            var collected: [[String]] = []
            for await result in group {
                collected.append(result)
            }
            return collected
        }

        let expected = samples.map(\.e164)
        #expect(results.count == 32)
        for result in results {
            #expect(result == expected)
        }
    }

    @Test("Region metadata lookups are consistent under concurrent first use")
    func concurrentMetadataLookup() async {
        let results = await withTaskGroup(of: Int.self) { group in
            for _ in 0..<32 {
                group.addTask {
                    // countryCode(forRegion:) is backed by a lazily built table
                    // in NBMetadataHelper; racing threads must all observe the
                    // same fully built table.
                    PhoneNumberUtility.shared.countryCode(forRegion: "KR")
                }
            }

            var collected: [Int] = []
            for await result in group {
                collected.append(result)
            }
            return collected
        }

        #expect(results.count == 32)
        #expect(results.allSatisfy { $0 == 82 })
    }

    @Test("Validation and typing are stable across concurrent callers")
    func concurrentValidation() async {
        let results = await withTaskGroup(of: PhoneNumberValue?.self) { group in
            for _ in 0..<32 {
                group.addTask {
                    try? PhoneNumberUtility.shared
                        .value(from: "6502530000", defaultRegion: "US")
                        .get()
                }
            }

            var collected: [PhoneNumberValue?] = []
            for await result in group {
                collected.append(result)
            }
            return collected
        }

        let expected = PhoneNumberValue(
            e164: "+16502530000",
            regionCode: "US",
            nationalSignificantNumber: "6502530000",
            type: .fixedLineOrMobile
        )
        #expect(results.count == 32)
        #expect(results.allSatisfy { $0 == expected })
    }

    @Test("As-you-type formatters are independent per instance")
    func independentFormatters() async {
        let results = await withTaskGroup(of: String.self) { group in
            for index in 0..<16 {
                group.addTask {
                    let formatter = AsYouTypeFormatter(regionCode: index.isMultiple(of: 2) ? "US" : "KR")
                    var output = ""
                    for digit in "6502530000" {
                        output = formatter.inputDigit(String(digit))
                    }
                    return output
                }
            }

            var collected: [String] = []
            for await result in group {
                collected.append(result)
            }
            return collected
        }

        #expect(results.count == 16)
        #expect(Set(results).count == 2, "US and KR formatters should disagree, and agree among themselves")
    }
}
