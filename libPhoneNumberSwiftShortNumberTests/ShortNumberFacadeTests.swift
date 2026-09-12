import Testing
import libPhoneNumberShortNumber
import libPhoneNumberSwiftCore
import libPhoneNumberSwiftShortNumber

@Suite("Short number facade")
struct ShortNumberFacadeTests {
    private let util = PhoneNumberUtility.shared
    private let shortUtil = ShortNumberUtility.shared

    @Test("Costs map to their Objective-C raw values")
    func costRawValues() {
        let pairs: [(ShortNumberCost, NBEShortNumberCost)] = [
            (.unknown, .unknown),
            (.tollFree, .tollFree),
            (.standardRate, .standardRate),
            (.premiumRate, .premiumRate),
        ]

        for (swift, objc) in pairs {
            #expect(swift.rawValue == objc.rawValue, "\(swift) should mirror \(objc.rawValue)")
        }
    }

    @Test("Emergency numbers are recognized per region", arguments: [
        ("911", "US"),
        ("112", "GB"),
        ("119", "KR"),
        ("110", "JP"),
    ])
    func emergencyNumbers(number: String, region: String) {
        #expect(shortUtil.connectsToEmergencyNumber(number, forRegion: region))
        #expect(shortUtil.isEmergencyNumber(number, forRegion: region))
    }

    @Test("A number that is not an emergency number in the region is rejected")
    func nonEmergencyNumber() {
        #expect(!shortUtil.connectsToEmergencyNumber("911", forRegion: "KR"))
    }

    @Test("Supported regions are non-empty and contain the regions we assert on")
    func supportedRegions() {
        let regions = Set(shortUtil.supportedRegions)

        #expect(regions.count > 100)
        for region in ["US", "GB", "KR", "JP"] {
            #expect(regions.contains(region))
        }
    }

    @Test("Example short numbers round-trip back through validation")
    func exampleShortNumbers() throws {
        for region in ["US", "GB", "KR", "DE"] {
            let example = shortUtil.exampleShortNumber(forRegion: region)
            #expect(!example.isEmpty, "\(region) should ship an example short number")

            let number = try util.parse(example, defaultRegion: region)
            #expect(shortUtil.isValidShortNumber(number, forRegion: region))
        }
    }

    @Test("Region-specific validation does not leak across regions")
    func regionScopedValidation() throws {
        let number = try util.parse("911", defaultRegion: "US")

        #expect(shortUtil.isValidShortNumber(number, forRegion: "US"))
        #expect(!shortUtil.isValidShortNumber(number, forRegion: "KR"))
    }
}
