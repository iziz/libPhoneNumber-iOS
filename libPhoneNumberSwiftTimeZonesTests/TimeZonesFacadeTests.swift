import Testing
import libPhoneNumberSwiftCore
import libPhoneNumberSwiftTimeZones

@Suite("Time zones facade")
struct TimeZonesFacadeTests {
    private let util = PhoneNumberUtility.shared
    private let mapper = PhoneNumberTimeZonesMapper.shared

    @Test("Prefix lookup returns CLDR identifiers", arguments: [
        ("6509600000", "US", ["America/Los_Angeles"]),
        ("+8221234567", nil, ["Asia/Seoul"]),
        ("+81312345678", nil, ["Asia/Tokyo"]),
    ])
    func timeZonesForNumber(text: String, region: String?, expected: [String]) throws {
        let number = try util.parse(text, defaultRegion: region)

        #expect(mapper.timeZones(for: number) == expected)
    }

    /// A number whose prefix is in the metadata resolves to the single zone for
    /// that prefix; one that is not falls back to every zone the country spans.
    @Test("Prefix hits are narrower than the country-level fallback")
    func countryLevelFallback() throws {
        let londonLandline = try util.parse("+442071234567", defaultRegion: nil)
        #expect(mapper.timeZones(for: londonLandline) == ["Europe/London"])

        let ukMobile = try util.parse("+447387654321", defaultRegion: nil)
        #expect(mapper.timeZones(for: ukMobile) == [
            "Europe/Guernsey",
            "Europe/Isle_of_Man",
            "Europe/Jersey",
            "Europe/London",
        ])
    }

    @Test("An unknown country code yields the unknown sentinel")
    func unknownCountry() {
        let number = PhoneNumber()
        number.countryCode = 999
        number.nationalNumber = 2_423_651_234

        #expect(mapper.timeZones(for: number) == [PhoneNumberTimeZonesMapper.unknownTimeZone])
        #expect(PhoneNumberTimeZonesMapper.unknownTimeZone == "Etc/Unknown")
    }

    @Test("The geographical-only lookup agrees for geographical numbers")
    func geographicalLookup() throws {
        let number = try util.parse("6509600000", defaultRegion: "US")

        #expect(mapper.timeZonesForGeographicalNumber(number) == mapper.timeZones(for: number))
    }

    @Test("Concurrent lookups share one database connection safely")
    func concurrentLookups() async {
        let results = await withTaskGroup(of: [String].self) { group in
            for _ in 0..<16 {
                group.addTask {
                    guard let number = try? PhoneNumberUtility.shared
                        .parse("6509600000", defaultRegion: "US") else {
                        return []
                    }
                    return PhoneNumberTimeZonesMapper.shared.timeZones(for: number)
                }
            }

            var collected: [[String]] = []
            for await result in group {
                collected.append(result)
            }
            return collected
        }

        #expect(results.count == 16)
        #expect(results.allSatisfy { $0 == ["America/Los_Angeles"] })
    }
}
