[![CocoaPods](https://img.shields.io/cocoapods/p/libPhoneNumber-iOS.svg?style=flat)](http://cocoapods.org/?q=libPhoneNumber-iOS)
[![CocoaPods](https://img.shields.io/cocoapods/v/libPhoneNumber-iOS.svg?style=flat)](http://cocoapods.org/?q=libPhoneNumber-iOS)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

# libPhoneNumber for iOS

Objective-C implementation of Google's [libphonenumber](https://github.com/google/libphonenumber) metadata and behavior for Apple platforms, with a Swift-first facade for new Swift integrations.

The project keeps the Objective-C core stable for existing apps while exposing a smaller Swift API for common parsing, formatting, validation, geocoding, and short-number workflows.

## Products

| Product | Use when |
| --- | --- |
| `libPhoneNumberSwift` | You are writing new Swift code and want a native-feeling facade. |
| `libPhoneNumber` | You need the stable Objective-C core API. |
| `libPhoneNumberGeocoding` | You need offline region descriptions for phone numbers. |
| `libPhoneNumberShortNumber` | You need emergency and short-code support. |

## Installation

### Swift Package Manager

Add this repository as a package dependency and select the products you need.

For most Swift apps, choose:

```swift
.product(name: "libPhoneNumberSwift", package: "libPhoneNumber")
```

Use the Objective-C-compatible products directly if you need lower-level access:

```swift
.product(name: "libPhoneNumber", package: "libPhoneNumber")
.product(name: "libPhoneNumberGeocoding", package: "libPhoneNumber")
.product(name: "libPhoneNumberShortNumber", package: "libPhoneNumber")
```

### CocoaPods

For Objective-C-compatible core APIs:

```ruby
pod 'libPhoneNumber-iOS', '~> 1.4'
```

For the Swift-first facade:

```ruby
pod 'libPhoneNumberSwift', '~> 1.4'
```

Optional modules:

```ruby
pod 'libPhoneNumberGeocoding', '~> 1.4'
pod 'libPhoneNumberShortNumber', '~> 1.4'
```

### Carthage

Add this to your `Cartfile`:

```ogdl
github "iziz/libPhoneNumber-iOS"
```

### Manual Integration

Add the source files from the modules you need and link `Contacts.framework` for the core library.

## Swift Quick Start

Prefer `libPhoneNumberSwift` for new Swift code:

```swift
import libPhoneNumberSwift

let phoneUtil = PhoneNumberUtility.shared
let phoneNumber = try phoneUtil.parse("01065431234", defaultRegion: "KR")

let e164 = try phoneUtil.format(phoneNumber, as: .e164)
let isValid = phoneUtil.isValidNumber(phoneNumber)
let numberType = phoneUtil.type(of: phoneNumber)
```

The Swift facade delegates to the Objective-C implementation. Phone number parsing and validation logic should stay in the Objective-C core so upstream behavior remains centralized.

### As-You-Type Formatting

```swift
import libPhoneNumberSwift

let formatter = AsYouTypeFormatter(regionCode: "US")

formatter.inputDigit("6") // "6"
formatter.inputDigit("5") // "65"
formatter.inputDigit("0") // "650"
formatter.inputDigit("2") // "650-2"
```

### Short Numbers

```swift
import libPhoneNumberSwift

let phoneUtil = PhoneNumberUtility.shared
let shortUtil = ShortNumberUtility.shared
let number = try phoneUtil.parse("911", defaultRegion: "US")

shortUtil.isValidShortNumber(number, forRegion: "US")
shortUtil.connectsToEmergencyNumber("911", forRegion: "US")
shortUtil.expectedCost(of: number, forRegion: "US")
```

### Geocoding

```swift
import libPhoneNumberSwift

let phoneUtil = PhoneNumberUtility.shared
let geocoder = PhoneNumberGeocoder.shared
let number = try phoneUtil.parse("16502530000", defaultRegion: "US")

let description = geocoder.description(for: number, languageCode: "en")
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

### As-You-Type Formatting

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

New Swift code should prefer `libPhoneNumberSwift` unless it specifically needs Objective-C API details.

## Metadata And Upstream Parity

Phone number behavior is driven by Google's libphonenumber metadata. When metadata or upstream behavior changes, update this repository in a normal PR and include:

- The Google libphonenumber version or commit used.
- Main metadata changes.
- Geocoding metadata changes, if applicable.
- Upstream test parity results.
- Upstream API parity results.
- Local test results.

Useful commands:

```bash
swift scripts/checkUpstreamTestParity.swift --upstream-ref <version-or-ref>
swift scripts/checkUpstreamAPIParity.swift --upstream-ref <version-or-ref>
swift test
LC_ALL=ko_KR.UTF-8 LANG=ko_KR.UTF-8 swift test
swift build -c release
```

For the full maintenance workflow, see:

- [Upstream parity guide](docs/UPSTREAM_PARITY.md)
- [Testing guide](docs/TESTING.md)

## Updating Metadata

### Main Metadata

Run the metadata generator from the `scripts` directory:

```bash
cd scripts
./metadataGenerator.swift <libphonenumber-version> --pretty
```

This downloads metadata from Google's libphonenumber repository, updates the generated Objective-C metadata files from compact JSON, and writes pretty-printed `generatedJSON` files for review.

### Geocoding Metadata

1. Open `libPhoneNumber-GeocodingParser` in Xcode.
2. Edit the run scheme arguments.
3. Set the libphonenumber version.
4. Set an output directory.
5. Run the parser.
6. Copy the generated `*.db` files into `libPhoneNumberGeocodingMetaData/GeocodingMetaData.bundle`.

## Validation

Before merging behavior, metadata, packaging, or API changes, run the relevant checks from [docs/TESTING.md](docs/TESTING.md).

Common local checks:

```bash
swift test
LC_ALL=ko_KR.UTF-8 LANG=ko_KR.UTF-8 swift test
swift build -c release
git diff --check
```

For Swift facade changes:

```bash
pod lib lint libPhoneNumberSwift.podspec --allow-warnings --include-podspecs='*.podspec'
```

For Xcode schemes:

```bash
xcodebuild test -scheme libPhoneNumber -destination 'platform=iOS Simulator,name=iPhone 16'
xcodebuild test -scheme libPhoneNumberGeocoding -destination 'platform=iOS Simulator,name=iPhone 16'
xcodebuild test -scheme libPhoneNumberShortNumber -destination 'platform=iOS Simulator,name=iPhone 16'
```

## Release Checklist

1. Decide the next version:
   - Patch for bug fixes.
   - Minor for metadata updates or additive functionality.
   - Major for breaking changes.
2. Run the validation matrix.
3. Lint the affected podspecs.
4. Open a pull request with upstream version, parity results, and test results.
5. Create a GitHub release after merge.
6. Push updated podspecs.

## Links

- [Google libphonenumber](https://github.com/google/libphonenumber)
- [Update log](https://github.com/iziz/libPhoneNumber-iOS/wiki/Update-Log)
- [libPhoneNumberGeocoding README](libPhoneNumberGeocoding/README.md)
- [libPhoneNumberShortNumber README](libPhoneNumberShortNumber/README.md)
