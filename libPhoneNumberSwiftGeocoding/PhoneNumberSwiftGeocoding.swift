import Foundation
import libPhoneNumberSwiftCore
#if canImport(libPhoneNumberGeocoding)
import libPhoneNumberGeocoding
#endif

/// The Objective-C geocoder is safe to share across threads: its per-language
/// SQLite helpers are created under a lock and every query on a helper is
/// serialized by that helper. Sendable is asserted rather than checked, because
/// the compiler cannot see the Objective-C side's locking.
public final class PhoneNumberGeocoder: @unchecked Sendable {
    public static let shared = PhoneNumberGeocoder()

    public let objc: NBPhoneNumberOfflineGeocoder

    public init(objc: NBPhoneNumberOfflineGeocoder = NBPhoneNumberOfflineGeocoder.sharedInstance()) {
        self.objc = objc
    }

    public func description(forValidNumber number: PhoneNumber, languageCode: String) -> String? {
        objc.description(forValidNumber: number, withLanguageCode: languageCode)
    }

    public func description(forValidNumber number: PhoneNumber, languageCode: String, userRegion: String) -> String? {
        objc.description(forValidNumber: number, withLanguageCode: languageCode, withUserRegion: userRegion)
    }

    public func description(for number: PhoneNumber, languageCode: String) -> String? {
        objc.description(for: number, withLanguageCode: languageCode)
    }

    public func description(for number: PhoneNumber, languageCode: String, userRegion: String) -> String? {
        objc.description(for: number, withLanguageCode: languageCode, withUserRegion: userRegion)
    }

    public func description(for number: PhoneNumber) -> String? {
        objc.description(for: number)
    }

    public func description(for number: PhoneNumber, userRegion: String) -> String? {
        objc.description(for: number, withUserRegion: userRegion)
    }
}
