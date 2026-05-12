# Package Size Options

The Swift facade is split so consumers can choose the smallest dependency surface that matches their app.

## Swift Package Manager

| Need | Product |
| --- | --- |
| Parse, format, validate, as-you-type formatting | `libPhoneNumberSwiftCore` |
| Core plus offline geocoding | `libPhoneNumberSwiftGeocoding` |
| Core plus emergency and short-code support | `libPhoneNumberSwiftShortNumber` |
| SwiftUI phone input | `libPhoneNumberSwiftUI` |
| Backwards-compatible non-UI umbrella | `libPhoneNumberSwift` |

## CocoaPods

| Need | Pod |
| --- | --- |
| Parse, format, validate, as-you-type formatting | `libPhoneNumber-iOS-SwiftCore` |
| Core plus offline geocoding | `libPhoneNumber-iOS-SwiftGeocoding` |
| Core plus emergency and short-code support | `libPhoneNumber-iOS-SwiftShortNumber` |
| SwiftUI phone input | `libPhoneNumber-iOS-SwiftUI` |
| Backwards-compatible non-UI umbrella | `libPhoneNumber-iOS-Swift` |

The SwiftUI module is intentionally not part of the umbrella product because it is UI-specific. Its public SwiftUI view APIs are guarded with Swift availability annotations for iOS 13, macOS 10.15, tvOS 13, and watchOS 6.

The geocoding module remains opt-in because it ships offline geocoding databases.
