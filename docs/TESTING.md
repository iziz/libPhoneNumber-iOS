# Testing Guide

Use this guide before merging changes to metadata, parsing, formatting, geocoding, short-number behavior, or public APIs.

The Swift package includes both the stable Objective-C targets and the Swift-first facade target, so `swift test` is the baseline check for Swift and Objective-C package users.

## Fast Local Validation

Run the Swift Package Manager test suite:

```bash
swift test
```

Run it with a non-English locale to catch locale-sensitive assumptions:

```bash
LC_ALL=ko_KR.UTF-8 LANG=ko_KR.UTF-8 swift test
```

Run a release build:

```bash
swift build -c release
```

Check whitespace before committing:

```bash
git diff --check
```

Check package and README version alignment:

```bash
swift scripts/checkVersionConsistency.swift
```

## Upstream Parity Validation

Run the upstream test parity check:

```bash
swift scripts/checkUpstreamTestParity.swift
```

Run the upstream API parity check:

```bash
swift scripts/checkUpstreamAPIParity.swift
```

When validating a specific Google libphonenumber version or commit, pin the ref:

```bash
swift scripts/checkUpstreamTestParity.swift --upstream-ref <version-or-commit>
swift scripts/checkUpstreamAPIParity.swift --upstream-ref <version-or-commit>
```

See `docs/UPSTREAM_PARITY.md` for the full parity workflow.

## Xcode Scheme Validation

Run the three main schemes on an iOS Simulator:

```bash
xcodebuild test -scheme libPhoneNumber -destination 'platform=iOS Simulator,name=iPhone 16'
xcodebuild test -scheme libPhoneNumberGeocoding -destination 'platform=iOS Simulator,name=iPhone 16'
xcodebuild test -scheme libPhoneNumberShortNumber -destination 'platform=iOS Simulator,name=iPhone 16'
```

If the destination name is ambiguous or unavailable, list destinations and use a simulator UDID:

```bash
xcodebuild -scheme libPhoneNumber -showdestinations
xcodebuild test -scheme libPhoneNumber -destination 'id=<simulator-udid>'
```

Using a fresh `-derivedDataPath` is useful when code coverage files or stale derived data create noisy warnings:

```bash
xcodebuild test -scheme libPhoneNumberShortNumber \
  -destination 'id=<simulator-udid>' \
  -derivedDataPath /tmp/libphone-xc-shortnumber-dd
```

## Required Matrix By Change Type

For a small implementation or test-only change:

- `swift test`
- `swift build -c release`
- `git diff --check`

For metadata updates:

- Use a patch version for metadata-only releases. Use a minor version only when the change also adds public API, new modules, or additive behavior beyond metadata freshness.
- `swift scripts/checkMetadataFreshness.swift --current-ref <metadata-ref> --output .build/metadata-freshness`
- `swift scripts/checkUpstreamTestParity.swift --upstream-ref <metadata-ref>`
- `swift scripts/checkUpstreamAPIParity.swift --upstream-ref <metadata-ref>`
- `swift scripts/updateGeocodingMetadata.swift <metadata-ref> --output /tmp/geocoding-review` if geocoding metadata changed upstream.
- `scripts/testGeocodingMetadataUpdater.sh` if the geocoding updater changed.
- Update `docs/METADATA_UPDATE_LOG.md` with the upstream comparison and validation results.
- `swift test`
- `LC_ALL=ko_KR.UTF-8 LANG=ko_KR.UTF-8 swift test`
- `swift build -c release`
- all three Xcode schemes
- `git diff --check`

For public API or parser/formatter behavior changes:

- `swift scripts/checkUpstreamTestParity.swift`
- `swift scripts/checkUpstreamAPIParity.swift`
- `swift test`
- `LC_ALL=ko_KR.UTF-8 LANG=ko_KR.UTF-8 swift test`
- `swift build -c release`
- affected Xcode schemes, usually `libPhoneNumber`
- `git diff --check`

For geocoding behavior changes:

- `swift test`
- `LC_ALL=ko_KR.UTF-8 LANG=ko_KR.UTF-8 swift test`
- `xcodebuild test -scheme libPhoneNumberGeocoding -destination 'id=<simulator-udid>'`
- `git diff --check`

For short-number behavior changes:

- `swift test`
- `xcodebuild test -scheme libPhoneNumberShortNumber -destination 'id=<simulator-udid>'`
- `git diff --check`

For Swift facade changes:

- `swift test`
- `LC_ALL=ko_KR.UTF-8 LANG=ko_KR.UTF-8 swift test`
- `swift build -c release`
- `pod lib lint libPhoneNumber-iOS-SwiftCore.podspec --allow-warnings --include-podspecs='*.podspec'`
- `pod lib lint libPhoneNumber-iOS-SwiftGeocoding.podspec --allow-warnings --include-podspecs='*.podspec'`
- `pod lib lint libPhoneNumber-iOS-SwiftShortNumber.podspec --allow-warnings --include-podspecs='*.podspec'`
- `pod lib lint libPhoneNumber-iOS-SwiftCarrier.podspec --allow-warnings --include-podspecs='*.podspec'`
- `pod lib lint libPhoneNumber-iOS-SwiftTimeZones.podspec --allow-warnings --include-podspecs='*.podspec'`
- `pod lib lint libPhoneNumber-iOS-SwiftUI.podspec --allow-warnings --include-podspecs='*.podspec'`
- `pod lib lint libPhoneNumber-iOS-SwiftUIEnrichment.podspec --allow-warnings --include-podspecs='*.podspec'`
- `pod lib lint libPhoneNumber-iOS-Swift.podspec --allow-warnings --include-podspecs='*.podspec'`
- Confirm the facade remains a thin wrapper over the Objective-C core instead of duplicating phone-number logic.
- See `docs/SWIFT_FACADE_MODULE_SPLIT.md` before changing module boundaries.

For packaging changes:

- `swift scripts/checkVersionConsistency.swift`
- `pod lib lint libPhoneNumber-iOS.podspec --allow-warnings`
- `pod lib lint libPhoneNumberGeocoding.podspec --allow-warnings --include-podspecs='*.podspec'`
- `pod lib lint libPhoneNumberShortNumber.podspec --allow-warnings --include-podspecs='*.podspec'`
- `pod lib lint libPhoneNumberCarrier.podspec --allow-warnings --include-podspecs='*.podspec'`
- `pod lib lint libPhoneNumberTimeZones.podspec --allow-warnings --include-podspecs='*.podspec'`
- `pod lib lint libPhoneNumber-iOS-SwiftCore.podspec --allow-warnings --include-podspecs='*.podspec'`
- `pod lib lint libPhoneNumber-iOS-SwiftGeocoding.podspec --allow-warnings --include-podspecs='*.podspec'`
- `pod lib lint libPhoneNumber-iOS-SwiftShortNumber.podspec --allow-warnings --include-podspecs='*.podspec'`
- `pod lib lint libPhoneNumber-iOS-SwiftCarrier.podspec --allow-warnings --include-podspecs='*.podspec'`
- `pod lib lint libPhoneNumber-iOS-SwiftTimeZones.podspec --allow-warnings --include-podspecs='*.podspec'`
- `pod lib lint libPhoneNumber-iOS-SwiftUI.podspec --allow-warnings --include-podspecs='*.podspec'`
- `pod lib lint libPhoneNumber-iOS-SwiftUIEnrichment.podspec --allow-warnings --include-podspecs='*.podspec'`
- `pod lib lint libPhoneNumber-iOS-Swift.podspec --allow-warnings --include-podspecs='*.podspec'`

## Locale-Sensitive Tests

Do not assert user-preferred localized strings from convenience APIs unless the test controls locale. Prefer APIs that accept explicit language and region parameters when asserting exact geocoder descriptions.

At minimum, run:

```bash
LC_ALL=ko_KR.UTF-8 LANG=ko_KR.UTF-8 swift test
```

This catches tests that only pass on machines configured for English.

## Adding Upstream-Ported Tests

When porting an upstream JS test:

1. Keep the local test name close to the upstream `test...` function name.
2. Add the test to the matching XCTest file:
   - `NBPhoneNumberUtilTest.m`
   - `NBAsYouTypeFormatterTest.m`
   - `NBShortNumberInfoTest.m`
3. Assert concrete behavior, not only that a call does not crash.
4. If the ObjC behavior differs intentionally, document the reason in the test comment and PR.
5. Re-run `swift scripts/checkUpstreamTestParity.swift`.
6. Re-run `swift scripts/checkUpstreamAPIParity.swift` if the upstream public API surface changed.

## Known Noisy Output

Some Xcode test runs may print coverage or SQLite diagnostic messages even when tests pass. Treat them as warnings only after confirming:

- `xcodebuild` exits with status `0`.
- The output ends with `** TEST SUCCEEDED **`.
- The affected XCTest suite reports `0 failures`.

If warnings are caused by reused derived data, rerun with a fresh `-derivedDataPath`.
