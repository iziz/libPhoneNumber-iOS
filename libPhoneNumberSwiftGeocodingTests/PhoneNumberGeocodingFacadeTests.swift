import Testing
import libPhoneNumberSwiftCore
import libPhoneNumberSwiftGeocoding

@Suite("Geocoder facade")
struct PhoneNumberGeocodingFacadeTests {
    private let util = PhoneNumberUtility.shared
    private let geocoder = PhoneNumberGeocoder.shared

    @Test("A geographical number resolves to a locality, not just the country")
    func localityForGeographicalNumber() throws {
        let number = try util.parse("6502530000", defaultRegion: "US")
        let description = geocoder.description(forValidNumber: number, languageCode: "en")

        #expect(description == "Mountain View, CA")
    }

    /// Only `en.db` carries worldwide coverage; the other databases hold their
    /// own country. A language without an entry falls back to the country name,
    /// which is correct behaviour, not a missing lookup.
    @Test("Descriptions are localized by language code", arguments: [
        ("en", "Seoul"),
        ("ko", "서울"),
    ])
    func localizedDescriptions(languageCode: String, expected: String) throws {
        let number = try util.parse("+8221234567", defaultRegion: nil)

        #expect(geocoder.description(forValidNumber: number, languageCode: languageCode) == expected)
    }

    @Test("A language without locality data falls back to the country name")
    func localizedFallback() throws {
        let number = try util.parse("6502530000", defaultRegion: "US")

        #expect(geocoder.description(forValidNumber: number, languageCode: "ko") == "미국")
    }

    @Test("A caller in the same region sees the locality; a caller abroad sees the country")
    func userRegionChangesGranularity() throws {
        let number = try util.parse("6502530000", defaultRegion: "US")

        #expect(geocoder.description(for: number, languageCode: "en", userRegion: "US") == "Mountain View, CA")
        #expect(geocoder.description(for: number, languageCode: "en", userRegion: "KR") == "United States")
    }

    /// Regression test: a lookup for a country the language's database does not
    /// carry used to finalize the prepared statement and leave the helper
    /// unusable, so every later lookup in that language returned a country name.
    @Test("An uncovered country does not disable later lookups in the same language")
    func uncoveredCountryDoesNotPoisonTheLanguage() throws {
        let geocoder = PhoneNumberGeocoder()
        let unitedStates = try util.parse("6502530000", defaultRegion: "US")
        let korea = try util.parse("+8221234567", defaultRegion: nil)

        // The Korean database carries only Korea, so this falls back.
        #expect(geocoder.description(forValidNumber: unitedStates, languageCode: "ko") == "미국")
        // The same helper must still answer for a country it does carry.
        #expect(geocoder.description(forValidNumber: korea, languageCode: "ko") == "서울")
        // And it must keep working when the country alternates.
        #expect(geocoder.description(forValidNumber: unitedStates, languageCode: "ko") == "미국")
        #expect(geocoder.description(forValidNumber: korea, languageCode: "ko") == "서울")
    }

    @Test("An unparseable number yields no description")
    func unknownNumber() {
        let number = PhoneNumber()
        number.countryCode = 999
        number.nationalNumber = 1

        #expect(geocoder.description(for: number, languageCode: "en") == nil)
    }

    @Test("Concurrent lookups share one database connection safely")
    func concurrentLookups() async throws {
        let results = await withTaskGroup(of: String?.self) { group in
            for _ in 0..<16 {
                group.addTask {
                    let util = PhoneNumberUtility.shared
                    guard let number = try? util.parse("6502530000", defaultRegion: "US") else {
                        return nil
                    }
                    return PhoneNumberGeocoder.shared.description(forValidNumber: number, languageCode: "en")
                }
            }

            var collected: [String?] = []
            for await result in group {
                collected.append(result)
            }
            return collected
        }

        #expect(results.count == 16)
        #expect(results.allSatisfy { $0 == "Mountain View, CA" })
    }
}
