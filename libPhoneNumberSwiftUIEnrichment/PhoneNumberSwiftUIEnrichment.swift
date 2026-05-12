import Foundation
import libPhoneNumberSwiftCore
import libPhoneNumberSwiftCarrier
import libPhoneNumberSwiftTimeZones
import libPhoneNumberSwiftUI

public struct CarrierTimeZonesPhoneNumberEnricher: PhoneNumberEnriching {
    private let carrierMapper: PhoneNumberCarrierMapper
    private let timeZonesMapper: PhoneNumberTimeZonesMapper
    private let localeCode: String

    public init(
        carrierMapper: PhoneNumberCarrierMapper = .shared,
        timeZonesMapper: PhoneNumberTimeZonesMapper = .shared,
        localeCode: String = Locale.current.identifier
    ) {
        self.carrierMapper = carrierMapper
        self.timeZonesMapper = timeZonesMapper
        self.localeCode = localeCode
    }

    public func enrichment(for number: PhoneNumber, regionCode: String?) -> PhoneNumberEnrichment {
        PhoneNumberEnrichment(
            carrierName: carrierMapper.safeDisplayName(for: number, localeCode: localeCode),
            timeZones: timeZonesMapper.timeZones(for: number)
        )
    }
}
