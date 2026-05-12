# Metadata Update Log

This file records upstream comparison results for metadata updates. Keep entries concise, command-based, and reviewable so future updates do not need to rediscover the same baseline.

Metadata-only updates should ship as patch releases. Use a minor release only when the update also adds public API, new modules, or additive behavior beyond metadata freshness.

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
