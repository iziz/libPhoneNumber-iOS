import Testing
import libPhoneNumberSwiftCarrier
import libPhoneNumberSwiftCore

@Suite("Carrier facade")
struct CarrierFacadeTests {
    private let util = PhoneNumberUtility.shared
    private let mapper = PhoneNumberCarrierMapper.shared

    @Test("Carrier lookup answers for mobile numbers in non-portable regions")
    func mobileCarrier() throws {
        let number = try util.parse("+244917654321", defaultRegion: nil)

        #expect(mapper.name(for: number, localeCode: "en") == "Movicel")
        #expect(mapper.safeDisplayName(for: number, localeCode: "en") == "Movicel")
    }

    @Test("Carrier names fall back to English for locales without a translation")
    func englishFallback() throws {
        let number = try util.parse("+244917654321", defaultRegion: nil)

        // de has no carrier translations, so the English name is used.
        #expect(mapper.name(for: number, localeCode: "de") == "Movicel")
        // Regional variants resolve to their base language.
        #expect(mapper.name(for: number, localeCode: "en-GB") == "Movicel")
    }

    @Test("Fixed-line numbers have no carrier")
    func fixedLineHasNoCarrier() throws {
        let number = try util.parse("+442071234567", defaultRegion: nil)

        #expect(util.type(of: number) == .fixedLine)
        #expect(mapper.name(for: number, localeCode: "en") == nil)
    }

    /// In regions with mobile number portability the original assignment is not
    /// a reliable indicator of the current carrier, so the safe API withholds it
    /// while the raw API still reports it.
    @Test("Portable regions expose the raw name but suppress the safe display name")
    func portableRegionSuppression() throws {
        let number = try util.parse("+447387654321", defaultRegion: nil)

        #expect(mapper.name(for: number, localeCode: "en") == "Vodafone")
        #expect(mapper.safeDisplayName(for: number, localeCode: "en") == nil)
    }

    @Test("Empty carrier names are reported as nil rather than an empty string")
    func emptyNameIsNil() throws {
        let number = try util.parse("+12125551234", defaultRegion: nil)

        #expect(mapper.name(for: number, localeCode: "en") == nil)
    }

    @Test("Concurrent lookups share one database connection safely")
    func concurrentLookups() async {
        let results = await withTaskGroup(of: String?.self) { group in
            for _ in 0..<16 {
                group.addTask {
                    guard let number = try? PhoneNumberUtility.shared
                        .parse("+244917654321", defaultRegion: nil) else {
                        return nil
                    }
                    return PhoneNumberCarrierMapper.shared.name(for: number, localeCode: "en")
                }
            }

            var collected: [String?] = []
            for await result in group {
                collected.append(result)
            }
            return collected
        }

        #expect(results.count == 16)
        #expect(results.allSatisfy { $0 == "Movicel" })
    }
}
