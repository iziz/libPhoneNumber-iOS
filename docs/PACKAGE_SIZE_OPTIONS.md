# Package Size Options

The Swift facade is split so consumers can choose the smallest dependency surface that matches their app.

## Swift Package Manager

| Need | Product |
| --- | --- |
| Parse, format, validate, as-you-type formatting | `libPhoneNumberSwiftCore` |
| Core plus offline geocoding | `libPhoneNumberSwiftGeocoding` |
| Core plus emergency and short-code support | `libPhoneNumberSwiftShortNumber` |
| Core plus carrier prefix lookup | `libPhoneNumberSwiftCarrier` |
| Core plus timezone prefix lookup | `libPhoneNumberSwiftTimeZones` |
| SwiftUI phone input | `libPhoneNumberSwiftUI` |
| SwiftUI phone input plus carrier/timezone enrichment | `libPhoneNumberSwiftUIEnrichment` |
| Non-UI umbrella | `libPhoneNumberIOSSwift` |

## CocoaPods

| Need | Pod |
| --- | --- |
| Parse, format, validate, as-you-type formatting | `libPhoneNumber-iOS-SwiftCore` |
| Core plus offline geocoding | `libPhoneNumber-iOS-SwiftGeocoding` |
| Core plus emergency and short-code support | `libPhoneNumber-iOS-SwiftShortNumber` |
| Core plus carrier prefix lookup | `libPhoneNumber-iOS-SwiftCarrier` |
| Core plus timezone prefix lookup | `libPhoneNumber-iOS-SwiftTimeZones` |
| SwiftUI phone input | `libPhoneNumber-iOS-SwiftUI` |
| SwiftUI phone input plus carrier/timezone enrichment | `libPhoneNumber-iOS-SwiftUIEnrichment` |
| Non-UI umbrella | `libPhoneNumber-iOS-Swift` |

The SwiftUI module is intentionally not part of the umbrella product because it is UI-specific. Its public SwiftUI view APIs are guarded with Swift availability annotations for iOS 13, macOS 10.15, tvOS 13, and watchOS 6.

The geocoding module remains opt-in because it ships offline geocoding databases.

The carrier module remains opt-in because it ships prefix metadata. Carrier names are original-assignment hints and can be misleading in mobile-number-portable regions; use the safe-display API for user-facing labels.

The timezone module remains opt-in because it ships prefix metadata. It returns possible timezone IDs from Google libphonenumber metadata, not the user's current location.
