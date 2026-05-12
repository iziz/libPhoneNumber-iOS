# Swift Facade Module Split

This document defines the target direction for a Swift-first facade while keeping the Objective-C implementation as the stable behavioral core.

## Current State

`libPhoneNumberSwift` is a single Swift facade target. It depends on:

- `libPhoneNumber`
- `libPhoneNumberGeocoding`
- `libPhoneNumberShortNumber`

This is convenient for users who want one import, but it makes every Swift facade consumer link optional geocoding and short-number features even when they only need parsing, formatting, and validation.

## Goals

- Keep Objective-C as the source of truth for parsing, formatting, validation, geocoding, and short-number behavior.
- Let Swift consumers depend on a smaller core facade without pulling geocoding metadata or short-number APIs.
- Preserve `import libPhoneNumberSwift` as the backwards-compatible umbrella module during migration.
- Keep CocoaPods and Swift Package Manager product names predictable.

## Non-Goals

- Do not rewrite libphonenumber behavior in Swift.
- Do not rename or destabilize the Objective-C public API.
- Do not remove the existing `libPhoneNumberSwift` product until downstream migration data supports it.

## Target Module Layout

| Module | Depends on | Public surface |
| --- | --- | --- |
| `libPhoneNumberSwiftCore` | `libPhoneNumber` | `PhoneNumber`, `PhoneNumberUtility`, `AsYouTypeFormatter`, Swift enums/errors |
| `libPhoneNumberSwiftGeocoding` | `libPhoneNumberSwiftCore`, `libPhoneNumberGeocoding` | `PhoneNumberGeocoder` |
| `libPhoneNumberSwiftShortNumber` | `libPhoneNumberSwiftCore`, `libPhoneNumberShortNumber` | `ShortNumberUtility`, short-number cost/type wrappers |
| `libPhoneNumberSwiftUI` | `libPhoneNumberSwiftCore`, `SwiftUI` | `PhoneNumberTextField`, `PhoneNumberFieldStyle`, validation state |
| `libPhoneNumberSwift` | core, geocoding, short-number facade modules | Backwards-compatible umbrella import |

The umbrella module should contain little or no behavior. Its purpose is compatibility and convenience.

## CocoaPods Direction

Prefer explicit podspecs or subspecs that mirror the Swift Package products:

- `libPhoneNumber-iOS-SwiftCore`
- `libPhoneNumber-iOS-SwiftGeocoding`
- `libPhoneNumber-iOS-SwiftShortNumber`
- `libPhoneNumber-iOS-SwiftUI`
- `libPhoneNumber-iOS-Swift` as an umbrella pod

The umbrella pod should remain available and continue to depend on the non-UI Swift facade modules. SwiftUI remains opt-in because it is UI-specific and its view APIs require newer SwiftUI runtime availability. New README examples should recommend `libPhoneNumber-iOS-SwiftCore` for parse/format-only apps.

## Migration Plan

1. Document the split and keep the current product unchanged. Done.
2. Move Swift facade files into feature-aligned directories without changing public symbols. Done.
3. Add SPM targets/products for core, geocoding, short-number, and umbrella modules. Done.
4. Add matching CocoaPods packaging and lint checks. Done.
5. Update README examples to recommend the smallest product for each workflow. Done.
6. Keep the umbrella product until at least one minor release after the split.

## Acceptance Criteria

- A Swift app that only parses and formats phone numbers can depend on `libPhoneNumberSwiftCore` without linking geocoding metadata.
- Existing `import libPhoneNumberSwift` users continue to build.
- The Swift facade tests cover both the umbrella module and each split module.
- CI runs `swift test`, `swift build -c release`, version consistency checks, and CocoaPods lint for every shipped podspec.
- Any new Swift wrapper still delegates behavior to the Objective-C core.

## Verification Checklist

- Run `swift scripts/checkVersionConsistency.swift` after adding products or podspecs.
- Run `swift test` and `LC_ALL=ko_KR.UTF-8 LANG=ko_KR.UTF-8 swift test`.
- Run `pod lib lint` for all Swift facade podspecs.
- Inspect the package graph to confirm `libPhoneNumberSwiftCore` does not depend on geocoding or short-number targets.
