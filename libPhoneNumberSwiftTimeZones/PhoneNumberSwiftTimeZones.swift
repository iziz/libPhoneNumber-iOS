import Foundation
import libPhoneNumberSwiftCore
#if canImport(libPhoneNumberTimeZones)
import libPhoneNumberTimeZones
#endif

public final class PhoneNumberTimeZonesMapper {
    public static let shared = PhoneNumberTimeZonesMapper()
    public static let unknownTimeZone = NBPhoneNumberToTimeZonesMapper.unknownTimeZone()

    public let objc: NBPhoneNumberToTimeZonesMapper

    public init(objc: NBPhoneNumberToTimeZonesMapper = NBPhoneNumberToTimeZonesMapper.sharedInstance()) {
        self.objc = objc
    }

    public func timeZones(for number: PhoneNumber) -> [String] {
        objc.timeZones(for: number)
    }

    public func timeZonesForGeographicalNumber(_ number: PhoneNumber) -> [String] {
        objc.timeZones(forGeographicalNumber: number)
    }
}
