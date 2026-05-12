# Upstream Parity Guide

This project ports behavior from Google's JavaScript libphonenumber implementation into Objective-C. Metadata parity and test parity are separate concerns:

- Metadata parity means the generated metadata files come from the expected Google libphonenumber ref.
- Test parity means every relevant upstream JavaScript test has a local Objective-C XCTest counterpart.
- API and logic parity means public upstream behavior is represented in the Objective-C API surface and implementation, even when method names are idiomatic Objective-C rather than exact JavaScript names.

Use this guide whenever updating metadata, porting upstream behavior, or reviewing changes that may drift from Google libphonenumber.

## Upstream Sources

The parity check tracks these upstream JavaScript test files:

- `javascript/i18n/phonenumbers/phonenumberutil_test.js`
- `javascript/i18n/phonenumbers/asyoutypeformatter_test.js`
- `javascript/i18n/phonenumbers/shortnumberinfo_test.js`

The corresponding local XCTest files are:

- `libPhoneNumberTests/NBPhoneNumberUtilTest.m`
- `libPhoneNumberTests/NBAsYouTypeFormatterTest.m`
- `libPhoneNumberShortNumberTests/NBShortNumberInfoTest.m`

The upstream implementation files to inspect when porting behavior are:

- `javascript/i18n/phonenumbers/phonenumberutil.js`
- `javascript/i18n/phonenumbers/asyoutypeformatter.js`
- `javascript/i18n/phonenumbers/shortnumberinfo.js`

## Running The Test Parity Check

Run against Google `master`:

```bash
swift scripts/checkUpstreamTestParity.swift
```

Run against a tagged release, branch, or commit:

```bash
swift scripts/checkUpstreamTestParity.swift --upstream-ref v9.0.19
swift scripts/checkUpstreamTestParity.swift --upstream-ref master
swift scripts/checkUpstreamTestParity.swift --upstream-ref <commit-sha>
```

Run against already-downloaded upstream files:

```bash
mkdir -p /tmp/libphone-js-upstream
curl -fsSL https://raw.githubusercontent.com/google/libphonenumber/master/javascript/i18n/phonenumbers/phonenumberutil_test.js -o /tmp/libphone-js-upstream/phonenumberutil_test.js
curl -fsSL https://raw.githubusercontent.com/google/libphonenumber/master/javascript/i18n/phonenumbers/asyoutypeformatter_test.js -o /tmp/libphone-js-upstream/asyoutypeformatter_test.js
curl -fsSL https://raw.githubusercontent.com/google/libphonenumber/master/javascript/i18n/phonenumbers/shortnumberinfo_test.js -o /tmp/libphone-js-upstream/shortnumberinfo_test.js
swift scripts/checkUpstreamTestParity.swift --upstream-dir /tmp/libphone-js-upstream
```

The script compares upstream `function test...` names with local `- (void)test...` method names. It normalizes known naming differences such as `normalise` versus `normalize`, `geographical` versus `geographic`, and `dialling` versus `dialing`.

## Running The API Parity Check

Run against Google `master`:

```bash
swift scripts/checkUpstreamAPIParity.swift
```

Run against a tagged release, branch, or commit:

```bash
swift scripts/checkUpstreamAPIParity.swift --upstream-ref v9.0.19
swift scripts/checkUpstreamAPIParity.swift --upstream-ref master
swift scripts/checkUpstreamAPIParity.swift --upstream-ref <commit-sha>
```

Run against already-downloaded upstream implementation files:

```bash
mkdir -p /tmp/libphone-js-upstream-src
curl -fsSL https://raw.githubusercontent.com/google/libphonenumber/master/javascript/i18n/phonenumbers/phonenumberutil.js -o /tmp/libphone-js-upstream-src/phonenumberutil.js
curl -fsSL https://raw.githubusercontent.com/google/libphonenumber/master/javascript/i18n/phonenumbers/asyoutypeformatter.js -o /tmp/libphone-js-upstream-src/asyoutypeformatter.js
curl -fsSL https://raw.githubusercontent.com/google/libphonenumber/master/javascript/i18n/phonenumbers/shortnumberinfo.js -o /tmp/libphone-js-upstream-src/shortnumberinfo.js
swift scripts/checkUpstreamAPIParity.swift --upstream-dir /tmp/libphone-js-upstream-src
```

The API checker compares Google JS public prototype methods against the local ObjC public headers. It intentionally allows known idiomatic ObjC selector differences, such as `getExpectedCostForRegion` mapping to `expectedCostOfPhoneNumber:forRegion:`.

## When The Check Fails

For each missing upstream test:

1. Open the upstream JavaScript test and identify the behavior being asserted.
2. Port the test into the matching local XCTest file.
3. If the test fails locally, inspect the corresponding upstream implementation file and port the required logic.
4. Prefer ObjC method names that fit the existing project, but keep test names close enough that the parity script can match them.
5. If a legitimate naming difference appears, update the normalization rules in `scripts/checkUpstreamTestParity.swift` and explain why in the PR.

Do not silence a missing test by adding an empty test method. A passing parity check should mean the behavior has a real local assertion.

## API And Logic Parity Checklist

Test parity is necessary, but it does not prove that the full public API surface is synchronized. When updating from upstream, also compare the upstream prototypes against Objective-C headers.

Check public upstream methods manually when reviewing a large sync:

```bash
rg -n "i18n\\.phonenumbers\\.(PhoneNumberUtil|AsYouTypeFormatter|ShortNumberInfo)\\.prototype\\.[A-Za-z0-9_]+\\s*=\\s*function" /tmp/libphone-js-upstream-src
```

Check local public headers:

```bash
rg -n "^[-+] \\(" libPhoneNumber/NBPhoneNumberUtil.h libPhoneNumber/NBAsYouTypeFormatter.h libPhoneNumberShortNumber/NBShortNumberUtil.h
```

Pay special attention to:

- `PhoneNumberUtil.ValidationResult` numeric values.
- Public metadata accessors and supported-type/calling-code accessors.
- Parsing edge cases, especially RFC3966 `phone-context`, extension parsing, and leading-zero handling.
- Number matching behavior when raw input, country-code source, carrier code, or proto/default-only fields differ.
- Short-number APIs for supported regions, examples, cost, carrier-specific numbers, SMS services, and emergency numbers.
- Locale-sensitive geocoder tests. Convenience APIs may use system locale, so tests must be deterministic.

If upstream exposes a method that should be public in Objective-C, add it to the public header, implement it, and add a focused XCTest. If the method already exists under a legitimate ObjC selector shape, add the mapping to `scripts/checkUpstreamAPIParity.swift` instead of weakening the check.

## Metadata Update Workflow

Before updating checked-in metadata, generate a freshness report:

```bash
swift scripts/checkMetadataFreshness.swift --output .build/metadata-freshness
```

This writes:

- `.build/metadata-freshness/metadata-diff-summary.md`
- `.build/metadata-freshness/metadata-update-issue.md`
- `.build/metadata-freshness/metadata-update-pr.md`
- `.build/metadata-freshness/metadata-update-log-entry.md`

Use these files as maintenance inputs. They are review artifacts, not generated source.

For user-reported numbering-plan gaps that are not yet in upstream metadata, follow [Issue-driven metadata patch policy](METADATA_PATCH_POLICY.md).

For phone-number and short-number metadata:

```bash
swift scripts/metadataGenerator.swift <version-or-ref> --pretty
```

Examples:

```bash
swift scripts/metadataGenerator.swift v9.0.19 --pretty
swift scripts/metadataGenerator.swift master --dry-run
swift scripts/metadataGenerator.swift --pack-only
```

After updating metadata:

1. Review generated metadata diffs for the expected files only.
2. Run the upstream test and API parity checks against the same upstream ref used for metadata.
3. Run the full test matrix in `docs/TESTING.md`.
4. If upstream tests changed, port the new or renamed tests before merging.
5. Record the upstream comparison and validation results in `docs/METADATA_UPDATE_LOG.md`.

Geocoding metadata is maintained through the command-line updater:

```bash
swift scripts/updateGeocodingMetadata.swift <version-or-ref> --replace-bundle
```

Use `--output <dir>` to inspect generated databases before replacing the checked-in bundle, or `--source <dir>` to generate from a local Google libphonenumber checkout.

## Review Expectations

Every PR that updates metadata or upstream-synced behavior should include:

- The Google libphonenumber ref used.
- The `docs/METADATA_UPDATE_LOG.md` entry added or updated for the change.
- The test parity and API parity commands and results.
- The test commands and result.
- Any intentional ObjC/API naming differences.
- Any upstream behavior not ported, with a clear reason.

## Automation

GitHub Actions runs the parity and test matrix on pull requests and pushes to `master` or `main`:

- `.github/workflows/ci.yml` validates SPM, locale-sensitive tests, release build, whitespace, and the three Xcode schemes.
- `.github/workflows/upstream-drift.yml` runs daily against Google `master` to surface newly added upstream tests or API methods.

If the scheduled upstream drift workflow fails, update metadata and port the new tests/API behavior in a normal PR.
