# Metadata Update Log

This file records upstream comparison results for metadata updates. Keep entries concise, command-based, and reviewable so future updates do not need to rediscover the same baseline.

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

Carrier and timezone data changed upstream, but this project does not currently package carrier mapper or timezone metadata.

### Commands

```bash
swift scripts/metadataGenerator.swift v9.0.30 --pretty
swift scripts/updateGeocodingMetadata.swift v9.0.30 --replace-bundle

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
pod lib lint libPhoneNumberSwift.podspec --allow-warnings --include-podspecs='*.podspec'
```

### Results

- Upstream JS test parity: passed, 172 upstream JS tests and 180 local ObjC tests.
- Upstream JS API parity: passed, 66 upstream JS public prototype methods and 93 local ObjC public selectors.
- Version consistency: passed for `1.4.0`.
- SwiftPM default locale tests: passed, 204 tests.
- SwiftPM Korean locale tests: passed, 204 tests.
- Release build: passed.
- Whitespace check: passed.
- CocoaPods lint: all four podspecs passed validation.
- Geocoding database sanity check: 34 databases, `en.db` has 151 geocoding tables, `kk.db` has 1 geocoding table.

### Notes

- `libPhoneNumberGeocoding` and `libPhoneNumberShortNumber` still emit CocoaPods Swift version warnings because those podspecs do not specify Swift version metadata. Validation passes with `--allow-warnings`.
- No malformed geocoding database names such as `(null)*.db` were generated.
