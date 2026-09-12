import Foundation
import libPhoneNumberSwiftCore
#if canImport(libPhoneNumberTimeZones)
import libPhoneNumberTimeZones
#endif

/// The Objective-C timezone mapper is safe to share across threads: every SQLite
/// statement it owns is used under `@synchronized(self)`. Sendable is asserted
/// rather than checked, because the compiler cannot see that locking.
public final class PhoneNumberTimeZonesMapper: @unchecked Sendable {
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
