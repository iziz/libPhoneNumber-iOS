[![CocoaPods](https://img.shields.io/cocoapods/p/libPhoneNumber-iOS.svg?style=flat)](https://cocoapods.org/pods/libPhoneNumber-iOS)
[![CocoaPods](https://img.shields.io/cocoapods/v/libPhoneNumber-iOS.svg?style=flat)](https://cocoapods.org/pods/libPhoneNumber-iOS)
[![Swift Package Manager](https://img.shields.io/badge/SPM-supported-orange.svg?style=flat)](https://swift.org/package-manager/)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

# libPhoneNumber for iOS

Apple-platform port of Google's [libphonenumber](https://github.com/google/libphonenumber) metadata and behavior, with a stable Objective-C core and Swift-first facades for modern Swift apps.

Use the Objective-C API when you need source-compatible legacy integration. Use the Swift facade modules when you want value-oriented parsing, formatting, validation, geocoding, short-number support, or a SwiftUI phone input.

## Why This Library

- Objective-C core remains the source of truth for parsing, formatting, validation, geocoding, and short-number behavior.
- Swift facade modules provide smaller, task-focused imports for new Swift code.
- SwiftUI phone input is available as an opt-in module instead of being bundled into the core parser.
- Swift Package Manager and CocoaPods are both supported.
- Metadata updates are tracked against Google libphonenumber with parity checks and review artifacts.

## Recommended Setup

For most Swift apps, start with the core Swift facade:

```swift
.product(name: "libPhoneNumberSwiftCore", package: "libPhoneNumber")
```

Add optional modules only when needed:

```swift
.product(name: "libPhoneNumberSwiftGeocoding", package: "libPhoneNumber")
.product(name: "libPhoneNumberSwiftShortNumber", package: "libPhoneNumber")
.product(name: "libPhoneNumberSwiftCarrier", package: "libPhoneNumber")
.product(name: "libPhoneNumberSwiftTimeZones", package: "libPhoneNumber")
.product(name: "libPhoneNumberSwiftUI", package: "libPhoneNumber")
.product(name: "libPhoneNumberSwiftUIEnrichment", package: "libPhoneNumber")
```

Use the umbrella product when you want one non-UI import for core, geocoding, and short-number facades:

```swift
.product(name: "libPhoneNumberIOSSwift", package: "libPhoneNumber")
```

For CocoaPods Swift apps:

```ruby
pod 'libPhoneNumber-iOS-SwiftCore', '~> 1.7'
```

For the CocoaPods umbrella facade:

```ruby
pod 'libPhoneNumber-iOS-Swift', '~> 1.7'
```

Then import the umbrella module as:

```swift
import libPhoneNumberIOSSwift
```

## Products

| Product | Package manager | Use when |
| --- | --- | --- |
| `libPhoneNumberSwiftCore` | SPM, CocoaPods | You need Swift parsing, formatting, validation, and as-you-type formatting. |
| `libPhoneNumberSwiftGeocoding` | SPM, CocoaPods | You need Swift offline geocoding on top of the core facade. |
| `libPhoneNumberSwiftShortNumber` | SPM, CocoaPods | You need Swift emergency-number and short-code support. |
| `libPhoneNumberSwiftCarrier` | SPM, CocoaPods | You need Swift carrier prefix lookup. |
| `libPhoneNumberSwiftTimeZones` | SPM, CocoaPods | You need Swift timezone prefix lookup. |
| `libPhoneNumberSwiftUI` | SPM, CocoaPods | You need a SwiftUI phone-number input component. |
| `libPhoneNumberSwiftUIEnrichment` | SPM, CocoaPods | You want carrier/timezone metadata connected to SwiftUI field state. |
| `libPhoneNumberIOSSwift` | SPM, CocoaPods umbrella module | You want one non-UI Swift import for core, geocoding, and short-number facades. |
| `libPhoneNumber` | SPM, CocoaPods, Carthage, manual | You need the stable Objective-C core API. |
| `libPhoneNumberGeocoding` | SPM, CocoaPods | You need Objective-C offline geocoding APIs. |
| `libPhoneNumberShortNumber` | SPM, CocoaPods | You need Objective-C emergency-number and short-code APIs. |
| `libPhoneNumberCarrier` | SPM, CocoaPods | You need Objective-C carrier prefix lookup APIs. |
| `libPhoneNumberTimeZones` | SPM, CocoaPods | You need Objective-C timezone prefix lookup APIs. |

The SwiftUI module is intentionally separate from the umbrella module because it is UI-specific and requires SwiftUI runtime availability.

## Installation

### Swift Package Manager

Add this repository as a package dependency:

```text
https://github.com/iziz/libPhoneNumber-iOS
```

Select only the products your app needs:

```swift
.product(name: "libPhoneNumberSwiftCore", package: "libPhoneNumber")
.product(name: "libPhoneNumberSwiftGeocoding", package: "libPhoneNumber")
.product(name: "libPhoneNumberSwiftShortNumber", package: "libPhoneNumber")
.product(name: "libPhoneNumberSwiftCarrier", package: "libPhoneNumber")
.product(name: "libPhoneNumberSwiftTimeZones", package: "libPhoneNumber")
.product(name: "libPhoneNumberSwiftUI", package: "libPhoneNumber")
.product(name: "libPhoneNumberSwiftUIEnrichment", package: "libPhoneNumber")
.product(name: "libPhoneNumberIOSSwift", package: "libPhoneNumber")
```

Objective-C-compatible products are also available:

```swift
.product(name: "libPhoneNumber", package: "libPhoneNumber")
.product(name: "libPhoneNumberGeocoding", package: "libPhoneNumber")
.product(name: "libPhoneNumberShortNumber", package: "libPhoneNumber")
.product(name: "libPhoneNumberCarrier", package: "libPhoneNumber")
.product(name: "libPhoneNumberTimeZones", package: "libPhoneNumber")
```

### CocoaPods

Core Objective-C API:

```ruby
pod 'libPhoneNumber-iOS', '~> 1.7'
```

Swift facade modules:

```ruby
pod 'libPhoneNumber-iOS-SwiftCore', '~> 1.7'
pod 'libPhoneNumber-iOS-SwiftGeocoding', '~> 1.7'
pod 'libPhoneNumber-iOS-SwiftShortNumber', '~> 1.7'
pod 'libPhoneNumber-iOS-SwiftCarrier', '~> 1.7'
pod 'libPhoneNumber-iOS-SwiftTimeZones', '~> 1.7'
pod 'libPhoneNumber-iOS-SwiftUI', '~> 1.7'
pod 'libPhoneNumber-iOS-SwiftUIEnrichment', '~> 1.7'
```

Swift umbrella facade:

```ruby
pod 'libPhoneNumber-iOS-Swift', '~> 1.7'
```

Objective-C optional modules:

```ruby
pod 'libPhoneNumberGeocoding', '~> 1.7'
pod 'libPhoneNumberShortNumber', '~> 1.7'
pod 'libPhoneNumberCarrier', '~> 1.7'
pod 'libPhoneNumberTimeZones', '~> 1.7'
```

### Carthage

Add this to your `Cartfile`:

```ogdl
github "iziz/libPhoneNumber-iOS"
```

### Manual Integration

Add the source files from the modules you need and link `Contacts.framework` for the core library.

## Swift Quick Start

Prefer `libPhoneNumberSwiftCore` for new Swift code that only needs parsing, formatting, validation, and as-you-type formatting:

```swift
import libPhoneNumberSwiftCore

let phoneUtil = PhoneNumberUtility.shared
let phoneNumber = try phoneUtil.parse("01065431234", defaultRegion: "KR")

let e164 = try phoneUtil.format(phoneNumber, as: .e164)
let isValid = phoneUtil.isValidNumber(phoneNumber)
let numberType = phoneUtil.type(of: phoneNumber)
```

The Swift facade delegates to the Objective-C implementation. Phone-number parsing and validation logic should stay in the Objective-C core so upstream behavior remains centralized.

For storage, concurrency boundaries, or API responses, use the immutable value wrapper:

```swift
let value = try phoneUtil.value(from: "01065431234", defaultRegion: "KR").get()

value.e164
value.regionCode
value.nationalSignificantNumber
value.type
```

### As-You-Type Formatting

```swift
import libPhoneNumberSwiftCore

let formatter = AsYouTypeFormatter(regionCode: "US")

formatter.inputDigit("6") // "6"
formatter.inputDigit("5") // "65"
formatter.inputDigit("0") // "650"
formatter.inputDigit("2") // "650-2"
```

### Short Numbers

```swift
import libPhoneNumberSwiftCore
import libPhoneNumberSwiftShortNumber

let phoneUtil = PhoneNumberUtility.shared
let shortUtil = ShortNumberUtility.shared
let number = try phoneUtil.parse("911", defaultRegion: "US")

shortUtil.isValidShortNumber(number, forRegion: "US")
shortUtil.connectsToEmergencyNumber("911", forRegion: "US")
shortUtil.expectedCost(of: number, forRegion: "US")
```

### Geocoding

```swift
import libPhoneNumberSwiftCore
import libPhoneNumberSwiftGeocoding

let phoneUtil = PhoneNumberUtility.shared
let geocoder = PhoneNumberGeocoder.shared
let number = try phoneUtil.parse("16502530000", defaultRegion: "US")

let description = geocoder.description(for: number, languageCode: "en")
```

### Carrier

```swift
import libPhoneNumberSwiftCore
import libPhoneNumberSwiftCarrier

let phoneUtil = PhoneNumberUtility.shared
let mapper = PhoneNumberCarrierMapper.shared
let number = try phoneUtil.parse("+244917654321", defaultRegion: "AO")

let carrier = mapper.safeDisplayName(for: number, localeCode: "en")
```

### Timezones

```swift
import libPhoneNumberSwiftCore
import libPhoneNumberSwiftTimeZones

let phoneUtil = PhoneNumberUtility.shared
let mapper = PhoneNumberTimeZonesMapper.shared
let number = try phoneUtil.parse("16502530000", defaultRegion: "US")

let timeZones = mapper.timeZones(for: number)
```

### SwiftUI Phone Input

```swift
import SwiftUI
import libPhoneNumberSwiftUI

struct PhoneForm: View {
  @State private var phoneNumber = ""
  @State private var e164: String?

  var body: some View {
    PhoneNumberTextField(
      "Phone number",
      text: $phoneNumber,
      defaultRegion: "US",
      onStateChange: { state in
        e164 = state.e164
      },
      regionPicker: { region in
        Text(region)
      }
    )
  }
}
```

### SwiftUI Carrier And Timezone Enrichment

```swift
import SwiftUI
import libPhoneNumberSwiftUI
import libPhoneNumberSwiftUIEnrichment

struct EnrichedPhoneForm: View {
  @State private var phoneNumber = ""
  @State private var carrierName: String?
  @State private var timeZones: [String] = []

  private let formatter = PhoneNumberFieldFormatter(
    enricher: CarrierTimeZonesPhoneNumberEnricher(localeCode: "en")
  )

  var body: some View {
    PhoneNumberTextField(
      "Phone number",
      text: $phoneNumber,
      defaultRegion: "AO",
      formatter: formatter,
      onStateChange: { state in
        carrierName = state.enrichment?.carrierName
        timeZones = state.enrichment?.timeZones ?? []
      }
    )
  }
}
```

## Objective-C Usage

Use `NBPhoneNumberUtil` when integrating from Objective-C or when you need direct access to the core API:

```objc
NBPhoneNumberUtil *phoneUtil = [NBPhoneNumberUtil sharedInstance];
NSError *error = nil;

NBPhoneNumber *phoneNumber = [phoneUtil parse:@"6766077303"
                                defaultRegion:@"AT"
                                        error:&error];

if (phoneNumber != nil && error == nil) {
  NSLog(@"isValidPhoneNumber ? %@", [phoneUtil isValidNumber:phoneNumber] ? @"YES" : @"NO");

  NSLog(@"E164          : %@", [phoneUtil format:phoneNumber
                                    numberFormat:NBEPhoneNumberFormatE164
                                           error:&error]);
  NSLog(@"INTERNATIONAL : %@", [phoneUtil format:phoneNumber
                                    numberFormat:NBEPhoneNumberFormatINTERNATIONAL
                                           error:&error]);
  NSLog(@"NATIONAL      : %@", [phoneUtil format:phoneNumber
                                    numberFormat:NBEPhoneNumberFormatNATIONAL
                                           error:&error]);
  NSLog(@"RFC3966       : %@", [phoneUtil format:phoneNumber
                                    numberFormat:NBEPhoneNumberFormatRFC3966
                                           error:&error]);
} else {
  NSLog(@"Error: %@", error.localizedDescription);
}
```

### Objective-C As-You-Type Formatting

```objc
NBAsYouTypeFormatter *formatter = [[NBAsYouTypeFormatter alloc] initWithRegionCode:@"US"];

NSLog(@"%@", [formatter inputDigit:@"6"]); // "6"
NSLog(@"%@", [formatter inputDigit:@"5"]); // "65"
NSLog(@"%@", [formatter inputDigit:@"0"]); // "650"
NSLog(@"%@", [formatter inputDigit:@"2"]); // "650-2"
```

## Swift Bridging For Legacy Integrations

Existing Swift projects can continue to import Objective-C headers directly.

For manual integration:

```objc
#import "NBPhoneNumberUtil.h"
#import "NBPhoneNumber.h"
```

For CocoaPods:

```objc
#import "libPhoneNumber_iOS/NBPhoneNumberUtil.h"
#import "libPhoneNumber_iOS/NBPhoneNumber.h"
```

New Swift code should prefer `libPhoneNumberSwiftCore` unless it specifically needs geocoding, short-number support, or Objective-C API details.

## Metadata Freshness

Phone-number behavior is driven by Google's libphonenumber metadata. Metadata or upstream behavior changes should be reviewed in a normal PR with:

- The Google libphonenumber version or commit used.
- Main metadata changes.
- Geocoding metadata changes, if applicable.
- Upstream test parity results.
- Upstream API parity results.
- Local validation results.

Generate a current-vs-upstream freshness report:

```bash
swift scripts/checkMetadataFreshness.swift --output .build/metadata-freshness
```

The script writes review artifacts only. It does not modify checked-in metadata.

For user-reported numbering-plan gaps that are not yet in upstream metadata, follow the [metadata patch policy](docs/METADATA_PATCH_POLICY.md). Local metadata overrides must be evidence-backed, tested, and removed once upstream includes the change.

## Updating Metadata

### Main And Short-Number Metadata

Run the metadata generator from the `scripts` directory:

```bash
cd scripts
./metadataGenerator.swift <libphonenumber-version> --pretty
```

This downloads metadata from Google's libphonenumber repository, updates the generated Objective-C metadata files from compact JSON, and writes pretty-printed `generatedJSON` files for review.

### Geocoding Metadata

Generate SQLite geocoding databases with the command-line updater:

```bash
swift scripts/updateGeocodingMetadata.swift <libphonenumber-version> --replace-bundle
```

Examples:

```bash
swift scripts/updateGeocodingMetadata.swift 9.0.29 --replace-bundle
swift scripts/updateGeocodingMetadata.swift master --output /tmp/geocoding
swift scripts/updateGeocodingMetadata.swift --source /tmp/libphonenumber --output /tmp/geocoding
```

Use `--output` to inspect generated databases before replacing the checked-in bundle. Use `--source` when you already have a local Google libphonenumber checkout or an extracted `resources/geocoding` directory.

## Validation

Before merging behavior, metadata, packaging, or API changes, run the relevant checks from [docs/TESTING.md](docs/TESTING.md).

Common local checks:

```bash
swift scripts/checkVersionConsistency.swift
swift test
LC_ALL=ko_KR.UTF-8 LANG=ko_KR.UTF-8 swift test
swift build -c release
git diff --check
```

For Swift facade changes:

```bash
pod lib lint libPhoneNumber-iOS-SwiftCore.podspec --allow-warnings --include-podspecs='*.podspec'
pod lib lint libPhoneNumber-iOS-SwiftGeocoding.podspec --allow-warnings --include-podspecs='*.podspec'
pod lib lint libPhoneNumber-iOS-SwiftShortNumber.podspec --allow-warnings --include-podspecs='*.podspec'
pod lib lint libPhoneNumber-iOS-SwiftUI.podspec --allow-warnings --include-podspecs='*.podspec'
pod lib lint libPhoneNumber-iOS-Swift.podspec --allow-warnings --include-podspecs='*.podspec'
```

For Xcode schemes:

```bash
xcodebuild test -scheme libPhoneNumber -destination 'platform=iOS Simulator,name=iPhone 16'
xcodebuild test -scheme libPhoneNumberGeocoding -destination 'platform=iOS Simulator,name=iPhone 16'
xcodebuild test -scheme libPhoneNumberShortNumber -destination 'platform=iOS Simulator,name=iPhone 16'
```

## Release Checklist

1. Decide the next version:
   - Patch for bug fixes or metadata-only updates.
   - Minor for additive functionality or public API additions.
   - Major for breaking changes.
2. Update project versions:
   ```bash
   swift scripts/updateProjectVersions.swift <new-version>
   ```
3. Run the validation matrix.
4. Lint the affected podspecs.
5. Open a pull request with upstream version, parity results, and test results.
6. Create a GitHub release after merge.
7. Push updated podspecs in dependency order:
   ```bash
   swift scripts/publishPodspecs.swift
   swift scripts/publishPodspecs.swift --publish
   ```

## Maintenance Guides

- [Upstream parity guide](docs/UPSTREAM_PARITY.md)
- [Testing guide](docs/TESTING.md)
- [Release runbook](docs/RELEASE_RUNBOOK.md)
- [Metadata patch policy](docs/METADATA_PATCH_POLICY.md)
- [Metadata update log](docs/METADATA_UPDATE_LOG.md)
- [Package size options](docs/PACKAGE_SIZE_OPTIONS.md)
- [Swift facade module split](docs/SWIFT_FACADE_MODULE_SPLIT.md)

## Links

- [Google libphonenumber](https://github.com/google/libphonenumber)
- [Latest release](https://github.com/iziz/libPhoneNumber-iOS/releases/latest)
- [CocoaPods: libPhoneNumber-iOS](https://cocoapods.org/pods/libPhoneNumber-iOS)
- [libPhoneNumberGeocoding README](libPhoneNumberGeocoding/README.md)
- [libPhoneNumberShortNumber README](libPhoneNumberShortNumber/README.md)
