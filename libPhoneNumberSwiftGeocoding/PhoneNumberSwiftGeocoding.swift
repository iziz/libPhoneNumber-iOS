import Foundation
import libPhoneNumberSwiftCore
#if canImport(libPhoneNumberGeocoding)
import libPhoneNumberGeocoding
#endif

public final class PhoneNumberGeocoder {
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
