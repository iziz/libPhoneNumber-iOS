# Metadata Update Log

This file records upstream comparison results for metadata updates. Keep entries concise, command-based, and reviewable so future updates do not need to rediscover the same baseline.

Metadata-only updates should ship as patch releases. Use a minor release only when the update also adds public API, new modules, or additive behavior beyond metadata freshness.

## 2026-08-04: Google libphonenumber v9.0.36

### Scope

- Previous local main, testing, and short-number metadata matched Google libphonenumber `v9.0.35`.
- Updated main phone-number metadata to `v9.0.36`.
- Testing metadata was unchanged between `v9.0.35` and `v9.0.36`.
- Updated short-number metadata to `v9.0.36`.
- Regenerated geocoding metadata from `v9.0.36`; checked-in geocoding databases were unchanged.
- Regenerated carrier metadata from `v9.0.36`; packed metadata remains at 31,033 prefix rows and 107 mobile portable regions while carrier assignments changed for country calling codes 47, 61, 212, 256, 298, 423, 972, and 995.
- Regenerated timezone metadata from `v9.0.36`; source data remained unchanged at 3,295 prefix rows and 286 unique timezone IDs, while the bundle baseline ref advanced to `v9.0.36`.
- Updated project and podspec versions to `1.7.6`.

### Upstream Logic And Resource Comparison

- Compared tracked Google source and resource paths from `v9.0.35` (`aa97ee8d2582`) to `v9.0.36` (`eba87f5b1f76`).
- All 12 changed tracked files were phone-number, short-number, or carrier metadata resources.
- The tracked JavaScript implementation, test, and public API files were unchanged, so no Objective-C logic or test port was required.
- A final comparison from `v9.0.36` to Google `master` (`2b03a9082e13`) found zero tracked source or resource changes.

### Commands

```bash
swift scripts/checkMetadataFreshness.swift --output .build/metadata-freshness-codex
swift scripts/updateMetadata.swift v9.0.36 --dry-run --output-root .build/metadata-update/v9.0.36-dry-run-codex
swift scripts/checkUpstreamSourceDrift.swift --current-ref v9.0.35 --upstream-ref v9.0.36 --output .build/upstream-source-drift-v9.0.35-to-v9.0.36-codex
swift scripts/checkUpstreamTestParity.swift --upstream-ref v9.0.36
swift scripts/checkUpstreamAPIParity.swift --upstream-ref v9.0.36
swift scripts/updateMetadata.swift v9.0.36 --output-root .build/metadata-update/v9.0.36-codex
swift scripts/updateProjectVersions.swift 1.7.6
swift scripts/checkVersionConsistency.swift
scripts/testGeocodingMetadataUpdater.sh
swift test
LC_ALL=ko_KR.UTF-8 LANG=ko_KR.UTF-8 swift test
swift build -c release
swift scripts/testXcodeSchemes.swift --destination 'id=C768167E-DCA0-42C0-A2C0-813F6189F418' --derived-data-root /tmp/libphonenumber-1.7.6-xcode
swift scripts/publishPodspecs.swift --lint
swift scripts/checkMetadataFreshness.swift --current-ref v9.0.36 --output .build/metadata-freshness-v9.0.36-final-codex --fail-on-update
swift scripts/checkUpstreamTestParity.swift --upstream-ref master
swift scripts/checkUpstreamAPIParity.swift --upstream-ref master
swift scripts/checkUpstreamSourceDrift.swift --current-ref v9.0.36 --upstream-ref master --output .build/upstream-source-drift-v9.0.36-to-master-codex
git diff --check
```

### Results

- Scheduled Upstream Drift run 102 detected Google libphonenumber `v9.0.36` as the latest upstream tag; only the metadata freshness job failed, while source drift and Google master parity jobs passed.
- Main phone-number and short-number metadata changed; testing metadata was unchanged.
- Metadata generation resolved `v9.0.36` to peeled commit `eba87f5b1f76960b6f704588370d5bd708065214`.
- Carrier metadata retained 31,033 prefix rows and 107 mobile portable regions with updated carrier assignments.
- Geocoding databases were unchanged after regeneration.
- Timezone source data was unchanged; the regenerated database records `upstream_ref` `v9.0.36` with 3,295 prefix rows.
- Upstream `v9.0.36` and Google `master` JS test parity passed with 173 upstream JS tests and 181 local Objective-C tests.
- Upstream `v9.0.36` and Google `master` JS API parity passed with 66 upstream public prototype methods and 93 local Objective-C public selectors.
- Google `master` source/resource drift check passed with zero changed tracked files after `v9.0.36`.
- Version consistency passed for `1.7.6`.
- Geocoding metadata updater smoke test passed.
- SwiftPM tests passed in the default and Korean locales: 231 tests in each run.
- Release build passed.
- Xcode scheme tests passed for `libPhoneNumber`, `libPhoneNumberGeocoding`, and `libPhoneNumberShortNumber` on the iPhone 17 / iOS 26.5 simulator.
- All 13 podspecs passed dependency-aware CocoaPods lint.
- Final freshness check with `--fail-on-update` passed.
- Whitespace check passed.

## 2026-07-17: Google libphonenumber v9.0.35

### Scope

- Previous local main, testing, and short-number metadata matched Google libphonenumber `v9.0.34`.
- Updated main phone-number metadata to `v9.0.35`.
- Testing metadata was unchanged between `v9.0.34` and `v9.0.35`.
- Updated short-number metadata to `v9.0.35`.
- Regenerated geocoding metadata from `v9.0.35`; checked-in geocoding databases were unchanged.
- Regenerated carrier metadata from `v9.0.35`; packed metadata now has 31,033 prefix rows and 107 mobile portable regions.
- Regenerated timezone metadata from `v9.0.35`; source data remained unchanged at 3,295 prefix rows and 286 unique timezone IDs, while the bundle baseline ref advanced to `v9.0.35`.
- Updated project and podspec versions to `1.7.5`.

### Upstream Logic And Resource Comparison

- Compared tracked Google source and resource paths from `v9.0.34` (`e6bd443a4d7a`) to `v9.0.35` (`aa97ee8d2582`).
- All 20 changed tracked files were phone-number, short-number, carrier, or geocoding metadata resources.
- The tracked JavaScript implementation, test, and public API files were unchanged, so no Objective-C logic or test port was required.
- A final comparison from `v9.0.35` to Google `master` (`f7e3e88c92b9`) found zero tracked source or resource changes.

### Commands

```bash
swift scripts/checkMetadataFreshness.swift --output .build/metadata-freshness
swift scripts/updateMetadata.swift v9.0.35 --dry-run --output-root .build/metadata-update/v9.0.35-dry-run
swift scripts/checkUpstreamSourceDrift.swift --current-ref v9.0.34 --upstream-ref v9.0.35 --output .build/upstream-source-drift-v9.0.34-to-v9.0.35
swift scripts/checkUpstreamTestParity.swift --upstream-ref v9.0.35
swift scripts/checkUpstreamAPIParity.swift --upstream-ref v9.0.35
swift scripts/updateMetadata.swift v9.0.35 --output-root .build/metadata-update/v9.0.35
swift scripts/updateProjectVersions.swift 1.7.5
swift scripts/checkVersionConsistency.swift
scripts/testGeocodingMetadataUpdater.sh
swift test
LC_ALL=ko_KR.UTF-8 LANG=ko_KR.UTF-8 swift test
swift build -c release
swift scripts/testXcodeSchemes.swift --destination 'id=C768167E-DCA0-42C0-A2C0-813F6189F418' --derived-data-root /tmp/libphonenumber-1.7.5-xcode
swift scripts/publishPodspecs.swift --lint
swift scripts/checkMetadataFreshness.swift --current-ref v9.0.35 --output .build/metadata-freshness-v9.0.35-final --fail-on-update
swift scripts/checkUpstreamTestParity.swift --upstream-ref master
swift scripts/checkUpstreamAPIParity.swift --upstream-ref master
swift scripts/checkUpstreamSourceDrift.swift --current-ref v9.0.35 --upstream-ref master --output .build/upstream-source-drift-v9.0.35-to-master
git diff --check
```

### Results

- Freshness check found Google libphonenumber `v9.0.35` as the latest upstream tag.
- Main phone-number and short-number metadata changed; testing metadata was unchanged.
- Metadata generation resolved `v9.0.35` to peeled commit `aa97ee8d2582a727e150104aea96dc0d79e186ef`.
- Carrier metadata changed to 31,033 prefix rows and 107 mobile portable regions.
- Geocoding databases were unchanged after regeneration.
- Timezone source data was unchanged; the regenerated database records `upstream_ref` `v9.0.35` with 3,295 prefix rows.
- Upstream `v9.0.35` and Google `master` JS test parity passed with 173 upstream JS tests and 181 local Objective-C tests.
- Upstream `v9.0.35` and Google `master` JS API parity passed with 66 upstream public prototype methods and 93 local Objective-C public selectors.
- Google `master` source/resource drift check passed with zero changed tracked files after `v9.0.35`.
- Version consistency passed for `1.7.5`.
- Geocoding metadata updater smoke test passed.
- SwiftPM tests passed in the default and Korean locales: 231 tests in each run.
- Release build passed.
- Xcode scheme tests passed for `libPhoneNumber`, `libPhoneNumberGeocoding`, and `libPhoneNumberShortNumber` on the iPhone 17 / iOS 26.5 simulator.
- All 13 podspecs passed dependency-aware CocoaPods lint.
- Final freshness check with `--fail-on-update` passed.
- Whitespace check passed.

## 2026-07-04: Google libphonenumber v9.0.34

### Scope

- Previous local main, testing, and short-number metadata matched Google libphonenumber `v9.0.33`.
- Updated main phone-number metadata to `v9.0.34`.
- Testing metadata was unchanged between `v9.0.33` and `v9.0.34`.
- Short-number metadata was unchanged between `v9.0.33` and `v9.0.34`.
- Regenerated geocoding metadata from `v9.0.34`; checked-in geocoding databases were unchanged.
- Regenerated carrier metadata from `v9.0.34`; packed metadata now has 31,019 prefix rows and 107 mobile portable regions.
- Regenerated timezone metadata from `v9.0.34`; packed metadata now has 3,295 prefix rows and 286 unique timezone IDs.
- Updated project and podspec versions to `1.7.4`.

### Commands

```bash
swift scripts/checkMetadataFreshness.swift --output .build/metadata-freshness
swift scripts/updateMetadata.swift v9.0.34 --dry-run --output-root .build/metadata-update/v9.0.34-dry-run
swift scripts/updateMetadata.swift v9.0.34 --output-root .build/metadata-update/v9.0.34
swift scripts/updateProjectVersions.swift 1.7.4
swift scripts/checkMetadataFreshness.swift --output .build/metadata-freshness --fail-on-update
swift scripts/checkUpstreamTestParity.swift --upstream-ref v9.0.34
swift scripts/checkUpstreamAPIParity.swift --upstream-ref v9.0.34
swift scripts/checkVersionConsistency.swift
swift scripts/checkUpstreamSourceDrift.swift --output .build/upstream-source-drift
scripts/testGeocodingMetadataUpdater.sh
swift test
LC_ALL=ko_KR.UTF-8 LANG=ko_KR.UTF-8 swift test
swift build -c release
swift scripts/publishPodspecs.swift --lint
swift scripts/testXcodeSchemes.swift --destination 'id=C768167E-DCA0-42C0-A2C0-813F6189F418'
git diff --check
```

### Results

- Freshness check found Google libphonenumber `v9.0.34` as the latest upstream tag.
- Main phone-number metadata changed.
- Testing metadata was unchanged.
- Short-number metadata was unchanged.
- Metadata update resolved `v9.0.34` to peeled commit `e6bd443a4d7a38662018a4f24c2265f944afd5fb` for raw metadata downloads.
- Carrier metadata changed to 31,019 prefix rows and 107 mobile portable regions.
- Timezone metadata source digest changed; row count increased to 3,295 and unique timezone IDs stayed at 286.
- Geocoding metadata was unchanged after regeneration.
- Freshness re-check with `--fail-on-update`: metadata is up to date.
- Upstream JS test parity: passed, 173 upstream JS tests and 181 local ObjC tests.
- Upstream JS API parity: passed, 66 upstream JS public prototype methods and 93 local ObjC public selectors.
- Version consistency: passed for `1.7.4`.
- Source/resource drift check: passed, 0 changed tracked files from Google `master`.
- Geocoding metadata updater smoke test: passed.
- SwiftPM tests: passed, 231 tests.
- Korean locale SwiftPM tests: passed, 231 tests.
- Release build: passed.
- CocoaPods lint: all podspecs passed validation.
- Xcode scheme tests: `libPhoneNumber`, `libPhoneNumberGeocoding`, and `libPhoneNumberShortNumber` passed on iPhone 17 simulator `C768167E-DCA0-42C0-A2C0-813F6189F418`.
- Whitespace check: passed.

## 2026-06-19: Google libphonenumber v9.0.33

### Scope

- Previous local main, testing, and short-number metadata matched Google libphonenumber `v9.0.32`.
- Updated main phone-number metadata to `v9.0.33`.
- Testing metadata was unchanged between `v9.0.32` and `v9.0.33`.
- Short-number metadata was unchanged between `v9.0.32` and `v9.0.33`.
- Regenerated geocoding metadata from `v9.0.33`; checked-in geocoding databases were unchanged.
- Regenerated carrier metadata from `v9.0.33`; packed metadata now has 31,017 prefix rows and 107 mobile portable regions.
- Regenerated timezone metadata from `v9.0.33`; packed metadata still has 3,294 prefix rows.
- Hardened maintenance scripts that read GitHub raw files to resolve version tags to peeled commit SHAs before downloading, avoiding annotated-tag raw URL availability issues.

### Commands

```bash
swift scripts/checkMetadataFreshness.swift --current-ref v9.0.32 --output .build/metadata-freshness-v9.0.32-to-v9.0.33
swift scripts/updateMetadata.swift v9.0.33 --dry-run --output-root .build/metadata-update/v9.0.33-dry-run
swift scripts/updateMetadata.swift v9.0.33 --output-root .build/metadata-update/v9.0.33
swift scripts/updateProjectVersions.swift 1.7.3
swift scripts/checkMetadataFreshness.swift --output .build/metadata-freshness --fail-on-update
swift scripts/checkUpstreamTestParity.swift --upstream-ref v9.0.33
swift scripts/checkUpstreamAPIParity.swift --upstream-ref v9.0.33
swift scripts/checkVersionConsistency.swift
swift scripts/checkUpstreamSourceDrift.swift --output .build/upstream-source-drift
scripts/testGeocodingMetadataUpdater.sh
swift test
LC_ALL=ko_KR.UTF-8 LANG=ko_KR.UTF-8 swift test
swift build -c release
swift scripts/publishPodspecs.swift --lint
swift scripts/testXcodeSchemes.swift --destination 'id=1451ACEF-2B8C-480B-9D1F-873DBD717BAF'
git diff --check
```

### Results

- Freshness check found Google libphonenumber `v9.0.33` as the latest upstream tag.
- Main phone-number metadata changed.
- Testing metadata was unchanged.
- Short-number metadata was unchanged.
- Metadata update resolved `v9.0.33` to peeled commit `5178ee5b450e37a3adda9808abb09200acbae5db` for raw metadata downloads.
- Carrier metadata changed to 31,017 prefix rows and 107 mobile portable regions.
- Timezone metadata source digest changed; row count stayed at 3,294.
- Geocoding metadata was unchanged after regeneration.
- Freshness re-check with `--fail-on-update`: metadata is up to date.
- Upstream JS test parity: passed, 173 upstream JS tests and 181 local ObjC tests.
- Upstream JS API parity: passed, 66 upstream JS public prototype methods and 93 local ObjC public selectors.
- Version consistency: passed for `1.7.3`.
- Source/resource drift check: passed, 0 changed tracked files from Google `master`.
- Geocoding metadata updater smoke test: passed.
- SwiftPM tests: passed, 231 tests.
- Korean locale SwiftPM tests: passed, 231 tests.
- Release build: passed.
- CocoaPods lint: all podspecs passed validation.
- Xcode scheme tests: `libPhoneNumber`, `libPhoneNumberGeocoding`, and `libPhoneNumberShortNumber` passed on iPhone 16 simulator `1451ACEF-2B8C-480B-9D1F-873DBD717BAF`.
- Whitespace check: passed.

## 2026-06-04: Google libphonenumber v9.0.32

### Scope

- Previous local main, testing, and short-number metadata matched Google libphonenumber `v9.0.31`.
- Updated main phone-number metadata to `v9.0.32`.
- Testing metadata was unchanged between `v9.0.31` and `v9.0.32`.
- Short-number metadata was unchanged between `v9.0.31` and `v9.0.32`.
- Regenerated geocoding metadata from `v9.0.32`; checked-in geocoding databases were unchanged.
- Regenerated carrier metadata from `v9.0.32`; packed metadata now has 31,024 prefix rows and 107 mobile portable regions.
- Regenerated timezone metadata from `v9.0.32`; packed metadata still has 3,294 prefix rows.

### Commands

```bash
swift scripts/checkMetadataFreshness.swift --output .build/metadata-freshness
swift scripts/updateMetadata.swift v9.0.32 --dry-run --output-root .build/metadata-update/v9.0.32-dry-run
swift scripts/updateMetadata.swift v9.0.32 --output-root .build/metadata-update/v9.0.32
swift scripts/updateProjectVersions.swift 1.7.2
swift scripts/checkMetadataFreshness.swift --output .build/metadata-freshness --fail-on-update
swift scripts/checkUpstreamTestParity.swift --upstream-ref v9.0.32
swift scripts/checkUpstreamAPIParity.swift --upstream-ref v9.0.32
swift scripts/checkVersionConsistency.swift
swift test
LC_ALL=ko_KR.UTF-8 LANG=ko_KR.UTF-8 swift test
swift build -c release
swift scripts/publishPodspecs.swift --lint
git diff --check
```

### Results

- Freshness check found Google libphonenumber `v9.0.32` as the latest upstream tag.
- Main phone-number metadata changed.
- Testing metadata was unchanged.
- Short-number metadata was unchanged.
- Carrier metadata changed to 31,024 prefix rows and 107 mobile portable regions.
- Timezone metadata source digest changed; row count stayed at 3,294.
- Geocoding metadata was unchanged after regeneration.
- Freshness re-check with `--fail-on-update`: metadata is up to date.
- Upstream JS test parity: passed, 172 upstream JS tests and 180 local ObjC tests.
- Upstream JS API parity: passed, 66 upstream JS public prototype methods and 93 local ObjC public selectors.
- Version consistency: passed for `1.7.2`.
- SwiftPM tests: passed, 230 tests.
- Korean locale SwiftPM tests: passed, 230 tests.
- Release build: passed.
- CocoaPods lint: all podspecs available at release time passed validation.
- Whitespace check: passed.

## 2026-05-23: Google libphonenumber v9.0.31

### Scope

- Previous local main, testing, and short-number metadata matched Google libphonenumber `v9.0.30`.
- Updated main phone-number metadata to `v9.0.31`.
- Updated short-number metadata to `v9.0.31`.
- Testing metadata was unchanged between `v9.0.30` and `v9.0.31`.
- Verified issue #447 with a bundled-metadata regression test using the issue-style Uganda mobile input `+25679(4)123456`.

### Issue #447 Verification

The Uganda mobile pattern changed from `9[0-3589]` to `9[0-589]`, which includes the `794` range.

The new regression test failed against the previous `v9.0.30` metadata because the parsed number was not valid for `UG` and its type was `UNKNOWN`. After regenerating from `v9.0.31`, the same issue-style input passed and classified the number as `MOBILE`.

### Commands

```bash
swift scripts/checkMetadataFreshness.swift --output .build/metadata-freshness
swift test --filter PhoneNumberSwiftCoreTests/testUganda794MobileRangeFromIssue447
swift scripts/metadataGenerator.swift v9.0.31 --pretty
swift test --filter PhoneNumberSwiftCoreTests/testUganda794MobileRangeFromIssue447
swift scripts/updateProjectVersions.swift 1.7.1
swift scripts/checkMetadataFreshness.swift --current-ref v9.0.31 --output .build/metadata-freshness
swift scripts/checkUpstreamTestParity.swift --upstream-ref v9.0.31
swift scripts/checkUpstreamAPIParity.swift --upstream-ref v9.0.31
swift scripts/checkVersionConsistency.swift
swift test
LC_ALL=ko_KR.UTF-8 LANG=ko_KR.UTF-8 swift test
swift build -c release
git diff --check

xcodebuild test -scheme libPhoneNumber -destination 'id=1451ACEF-2B8C-480B-9D1F-873DBD717BAF' -derivedDataPath /tmp/libphone-xc-core-dd
xcodebuild test -scheme libPhoneNumberGeocoding -destination 'id=1451ACEF-2B8C-480B-9D1F-873DBD717BAF' -derivedDataPath /tmp/libphone-xc-geocoding-dd
xcodebuild test -scheme libPhoneNumberShortNumber -destination 'id=1451ACEF-2B8C-480B-9D1F-873DBD717BAF' -derivedDataPath /tmp/libphone-xc-shortnumber-dd

pod lib lint libPhoneNumber-iOS.podspec --allow-warnings
pod lib lint libPhoneNumberGeocoding.podspec --allow-warnings --include-podspecs='*.podspec'
pod lib lint libPhoneNumberShortNumber.podspec --allow-warnings --include-podspecs='*.podspec'
pod lib lint libPhoneNumberCarrier.podspec --allow-warnings --include-podspecs='*.podspec'
pod lib lint libPhoneNumberTimeZones.podspec --allow-warnings --include-podspecs='*.podspec'
pod lib lint libPhoneNumber-iOS-SwiftCore.podspec --allow-warnings --include-podspecs='*.podspec'
pod lib lint libPhoneNumber-iOS-SwiftGeocoding.podspec --allow-warnings --include-podspecs='*.podspec'
pod lib lint libPhoneNumber-iOS-SwiftShortNumber.podspec --allow-warnings --include-podspecs='*.podspec'
pod lib lint libPhoneNumber-iOS-SwiftCarrier.podspec --allow-warnings --include-podspecs='*.podspec'
pod lib lint libPhoneNumber-iOS-SwiftTimeZones.podspec --allow-warnings --include-podspecs='*.podspec'
pod lib lint libPhoneNumber-iOS-SwiftUI.podspec --allow-warnings --include-podspecs='*.podspec'
pod lib lint libPhoneNumber-iOS-SwiftUIEnrichment.podspec --allow-warnings --include-podspecs='*.podspec'
pod lib lint libPhoneNumber-iOS-Swift.podspec --allow-warnings --include-podspecs='*.podspec'
```

### Results

- Freshness check found Google libphonenumber `v9.0.31` as the latest upstream tag.
- Main phone-number metadata changed.
- Short-number metadata changed.
- Testing metadata was unchanged.
- Issue #447 regression test: failed before the metadata update and passed after the metadata update.
- SwiftPM tests: passed, 230 tests.
- Korean locale SwiftPM tests: passed, 230 tests.
- Release build: passed.
- Whitespace check: passed.
- Upstream JS test parity: passed, 172 upstream JS tests and 180 local ObjC tests.
- Upstream JS API parity: passed, 66 upstream JS public prototype methods and 93 local ObjC public selectors.
- Version consistency: passed for `1.7.1`.
- Xcode scheme tests: `libPhoneNumber`, `libPhoneNumberGeocoding`, and `libPhoneNumberShortNumber` passed on iPhone 16 simulator `1451ACEF-2B8C-480B-9D1F-873DBD717BAF`.
- CocoaPods lint: all podspecs available at release time passed validation.
- Freshness re-check with `--current-ref v9.0.31`: metadata is up to date.

## 2026-05-12: Google libphonenumber v9.0.30

### Scope

- Previous local main and short-number metadata matched Google libphonenumber `v9.0.25`.
- Updated main phone-number metadata to `v9.0.30`.
- Updated short-number metadata to `v9.0.30`.
- Updated testing metadata to `v9.0.30`.
- Updated geocoding metadata to `v9.0.30`.
- Added geocoding locale database `kk.db`.

### Upstream Logic And Test Comparison

Compared these JavaScript files between `v9.0.25` and `v9.0.30`:

- `javascript/i18n/phonenumbers/phonenumberutil.js`
- `javascript/i18n/phonenumbers/phonenumberutil_test.js`
- `javascript/i18n/phonenumbers/asyoutypeformatter.js`
- `javascript/i18n/phonenumbers/asyoutypeformatter_test.js`
- `javascript/i18n/phonenumbers/shortnumberinfo.js`
- `javascript/i18n/phonenumbers/shortnumberinfo_test.js`

Result: all files were unchanged. No required ObjC logic port or new upstream JS test port was identified for this metadata update.

Upstream Java had a `PhoneNumberUtil.formatInOriginalFormat` refactor between `v9.0.25` and `v9.0.30`, but the JavaScript implementation remained unchanged. This project tracks Google JavaScript parity, so no immediate ObjC change was applied for that Java-only diff.

Carrier and timezone data changed upstream and are now packaged as opt-in modules after this baseline.

### Commands

```bash
swift scripts/metadataGenerator.swift v9.0.30 --pretty
swift scripts/updateGeocodingMetadata.swift v9.0.30 --replace-bundle
swift scripts/updateCarrierMetadata.swift v9.0.30 --replace-bundle --output .build/carrier-metadata/v9.0.30
swift scripts/updateTimeZonesMetadata.swift v9.0.30 --replace-bundle --output .build/timezone-metadata/v9.0.30

swift scripts/checkUpstreamTestParity.swift --upstream-ref v9.0.30
swift scripts/checkUpstreamAPIParity.swift --upstream-ref v9.0.30
swift scripts/checkVersionConsistency.swift
swift test
LC_ALL=ko_KR.UTF-8 LANG=ko_KR.UTF-8 swift test
swift build -c release
git diff --check

pod lib lint libPhoneNumber-iOS.podspec --allow-warnings
pod lib lint libPhoneNumberGeocoding.podspec --allow-warnings --include-podspecs='*.podspec'
pod lib lint libPhoneNumberShortNumber.podspec --allow-warnings --include-podspecs='*.podspec'
pod lib lint libPhoneNumberCarrier.podspec --allow-warnings --include-podspecs='*.podspec'
pod lib lint libPhoneNumberTimeZones.podspec --allow-warnings --include-podspecs='*.podspec'
pod lib lint libPhoneNumber-iOS-SwiftCore.podspec --allow-warnings --include-podspecs='*.podspec'
pod lib lint libPhoneNumber-iOS-SwiftGeocoding.podspec --allow-warnings --include-podspecs='*.podspec'
pod lib lint libPhoneNumber-iOS-SwiftShortNumber.podspec --allow-warnings --include-podspecs='*.podspec'
pod lib lint libPhoneNumber-iOS-SwiftCarrier.podspec --allow-warnings --include-podspecs='*.podspec'
pod lib lint libPhoneNumber-iOS-SwiftTimeZones.podspec --allow-warnings --include-podspecs='*.podspec'
pod lib lint libPhoneNumber-iOS-SwiftUI.podspec --allow-warnings --include-podspecs='*.podspec'
pod lib lint libPhoneNumber-iOS-SwiftUIEnrichment.podspec --allow-warnings --include-podspecs='*.podspec'
pod lib lint libPhoneNumber-iOS-Swift.podspec --allow-warnings --include-podspecs='*.podspec'
```

### Results

- Upstream JS test parity: passed, 172 upstream JS tests and 180 local ObjC tests.
- Upstream JS API parity: passed, 66 upstream JS public prototype methods and 93 local ObjC public selectors.
- Version consistency: passed for `1.4.0`.
- SwiftPM default locale tests: passed, 204 tests.
- SwiftPM Korean locale tests: passed, 204 tests.
- Release build: passed.
- Whitespace check: passed.
- CocoaPods lint: all podspecs available at release time passed validation.
- Geocoding database sanity check: 34 databases, `en.db` has 151 geocoding tables, `kk.db` has 1 geocoding table.
- Carrier metadata sanity check: 31,001 prefix rows, 107 mobile portable regions, packed database about 2.0 MB.
- Timezone metadata sanity check: 3,294 prefix rows, packed database about 232 KB.

### Notes

- `libPhoneNumberGeocoding` and `libPhoneNumberShortNumber` still emit CocoaPods Swift version warnings because those podspecs do not specify Swift version metadata. Validation passes with `--allow-warnings`.
- No malformed geocoding database names such as `(null)*.db` were generated.
