import Foundation
import libPhoneNumberSwiftCore
#if canImport(libPhoneNumberShortNumber)
import libPhoneNumberShortNumber
#endif

public enum ShortNumberCost: UInt, Codable, Sendable {
    case unknown = 0
    case tollFree = 1
    case standardRate = 2
    case premiumRate = 3

    init(_ objcValue: NBEShortNumberCost) {
        self = ShortNumberCost(rawValue: objcValue.rawValue) ?? .unknown
    }
}

public final class ShortNumberUtility {
    public static let shared = ShortNumberUtility()

    public let objc: NBShortNumberUtil

    public init(objc: NBShortNumberUtil = NBShortNumberUtil.sharedInstance()) {
        self.objc = objc
    }

    public var supportedRegions: [String] {
        objc.getSupportedRegions()
    }

    public func exampleShortNumber(forRegion regionCode: String?) -> String {
        objc.getExampleShortNumber(regionCode)
    }

    public func exampleShortNumber(forRegion regionCode: String, cost: ShortNumberCost) -> String {
        objc.getExampleShortNumber(forRegion: regionCode, cost: NBEShortNumberCost(rawValue: cost.rawValue)!)
    }

    public func isPossibleShortNumber(_ number: PhoneNumber) -> Bool {
        objc.isPossibleShortNumber(number)
    }

    public func isPossibleShortNumber(_ number: PhoneNumber, forRegion regionCode: String) -> Bool {
        objc.isPossibleShortNumber(number, forRegion: regionCode)
    }

    public func isValidShortNumber(_ number: PhoneNumber) -> Bool {
        objc.isValidShortNumber(number)
    }

    public func isValidShortNumber(_ number: PhoneNumber, forRegion regionCode: String) -> Bool {
        objc.isValidShortNumber(number, forRegion: regionCode)
    }

    public func expectedCost(of number: PhoneNumber) -> ShortNumberCost {
        ShortNumberCost(objc.expectedCost(of: number))
    }

    public func expectedCost(of number: PhoneNumber, forRegion regionCode: String) -> ShortNumberCost {
        ShortNumberCost(objc.expectedCost(of: number, forRegion: regionCode))
    }

    public func isCarrierSpecific(_ number: PhoneNumber) -> Bool {
        objc.isPhoneNumberCarrierSpecific(number)
    }

    public func isCarrierSpecific(_ number: PhoneNumber, forRegion regionCode: String) -> Bool {
        objc.isPhoneNumberCarrierSpecific(number, forRegion: regionCode)
    }

    public func isSMSService(_ number: PhoneNumber, forRegion regionCode: String) -> Bool {
        objc.isPhoneNumberSMSService(number, forRegion: regionCode)
    }

    public func connectsToEmergencyNumber(_ number: String, forRegion regionCode: String) -> Bool {
        objc.connectsToEmergencyNumber(from: number, forRegion: regionCode)
    }

    public func isEmergencyNumber(_ number: String, forRegion regionCode: String) -> Bool {
        objc.isEmergencyNumber(number, forRegion: regionCode)
    }
}
