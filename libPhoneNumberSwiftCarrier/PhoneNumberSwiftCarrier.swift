import Foundation
import libPhoneNumberSwiftCore
#if canImport(libPhoneNumberCarrier)
import libPhoneNumberCarrier
#endif

/// The Objective-C carrier mapper is safe to share across threads: every SQLite
/// statement it owns is used under `@synchronized(self)`. Sendable is asserted
/// rather than checked, because the compiler cannot see that locking.
public final class PhoneNumberCarrierMapper: @unchecked Sendable {
    public static let shared = PhoneNumberCarrierMapper()

    public let objc: NBPhoneNumberToCarrierMapper

    public init(objc: NBPhoneNumberToCarrierMapper = NBPhoneNumberToCarrierMapper.sharedInstance()) {
        self.objc = objc
    }

    public func name(for number: PhoneNumber, localeCode: String) -> String? {
        nilIfEmpty(objc.name(for: number, localeCode: localeCode))
    }

    public func nameForValidNumber(_ number: PhoneNumber, localeCode: String) -> String? {
        nilIfEmpty(objc.name(forValidNumber: number, localeCode: localeCode))
    }

    public func safeDisplayName(for number: PhoneNumber, localeCode: String) -> String? {
        nilIfEmpty(objc.safeDisplayName(for: number, localeCode: localeCode))
    }

    private func nilIfEmpty(_ value: String?) -> String? {
        guard let value, !value.isEmpty else {
            return nil
        }
        return value
    }
}
