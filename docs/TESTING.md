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

## Concurrency Validation

The Swift facades are declared `@unchecked Sendable` on the strength of the
Objective-C core's internal locking, so the guarantee has to be exercised rather
than trusted. Run the suite under the thread sanitizer whenever you touch
mutable state in the Objective-C targets or add a facade entry point:

```bash
swift test --sanitize=thread
```

The concurrency suites live in `libPhoneNumberSwiftCoreTests` and in each
optional module's test target. They drive the shared instances from many tasks
at once; under the sanitizer an unguarded write is reported even when the
assertions still pass. CI runs this on every pull request.

## Platform Validation

`swift test` only covers macOS. `Package.swift` declares six platforms, so build
the package for each of the others before merging a packaging, linking, or
availability change:

```bash
for destination in \
  'generic/platform=iOS' \
  'generic/platform=tvOS' \
  'generic/platform=watchOS' \
  'generic/platform=visionOS' \
  'platform=macOS,variant=Mac Catalyst'
do
  xcodebuild build \
    -workspace .swiftpm/xcode/package.xcworkspace \
    -scheme libPhoneNumber-Package \
    -destination "$destination" \
    -derivedDataPath "/tmp/libphone-dd"
done
```

CI runs the same matrix on every pull request.

## Coverage

```bash
swift test --enable-code-coverage
xcrun llvm-cov report \
  -instr-profile "$(dirname "$(swift test --show-codecov-path)")/default.profdata" \
  "$(swift build --show-bin-path)/libPhoneNumberPackageTests.xctest/Contents/MacOS/libPhoneNumberPackageTests"
```

Coverage is a review aid, not a merge gate. Use it to find untested branches in
a module you changed, not to chase a number.

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
swift scripts/testXcodeSchemes.swift
```

If the destination name is ambiguous or unavailable, list destinations and use a simulator UDID:

```bash
xcodebuild -scheme libPhoneNumber -showdestinations
swift scripts/testXcodeSchemes.swift --destination 'id=<simulator-udid>'
```

Using a fresh `-derivedDataPath` is useful when code coverage files or stale derived data create noisy warnings:

```bash
swift scripts/testXcodeSchemes.swift \
  --destination 'id=<simulator-udid>' \
  --derived-data-root /tmp/libphone-xc-dd \
  libPhoneNumberShortNumber
```

## Required Matrix By Change Type

For a small implementation or test-only change:

- `swift test`
- `swift build -c release`
- `git diff --check`

For metadata updates:

- Use a patch version for metadata-only releases. Use a minor version only when the change also adds public API, new modules, or additive behavior beyond metadata freshness.
- `swift scripts/checkMetadataFreshness.swift --output .build/metadata-freshness`
- `swift scripts/updateMetadata.swift <metadata-ref> --dry-run`
- `swift scripts/checkUpstreamTestParity.swift --upstream-ref <metadata-ref>`
- `swift scripts/checkUpstreamAPIParity.swift --upstream-ref <metadata-ref>`
- `scripts/testGeocodingMetadataUpdater.sh` if the geocoding updater changed.
- Update `docs/METADATA_UPDATE_LOG.md` with the upstream comparison and validation results.
- `swift test`
- `LC_ALL=ko_KR.UTF-8 LANG=ko_KR.UTF-8 swift test`
- `swift build -c release`
- `swift scripts/testXcodeSchemes.swift`
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
- `swift scripts/testXcodeSchemes.swift --destination 'id=<simulator-udid>' libPhoneNumberGeocoding`
- `git diff --check`

For short-number behavior changes:

- `swift test`
- `swift scripts/testXcodeSchemes.swift --destination 'id=<simulator-udid>' libPhoneNumberShortNumber`
- `git diff --check`

For Swift facade changes:

- `swift test`
- `LC_ALL=ko_KR.UTF-8 LANG=ko_KR.UTF-8 swift test`
- `swift test --sanitize=thread` when the change touches shared state or adds a facade entry point
- `swift build -c release`
- `swift scripts/publishPodspecs.swift --lint`
- Confirm the facade remains a thin wrapper over the Objective-C core instead of duplicating phone-number logic.
- See the historical module split note in `docs/archive/SWIFT_FACADE_MODULE_SPLIT.md` before changing module boundaries.

For packaging changes:

- `swift scripts/checkVersionConsistency.swift`
- `swift scripts/publishPodspecs.swift --lint`
- the per-platform build matrix above, since `swift test` only covers macOS

## Locale-Sensitive Tests

Do not assert user-preferred localized strings from convenience APIs unless the test controls locale. Prefer APIs that accept explicit language and region parameters when asserting exact geocoder descriptions.

At minimum, run:

```bash
LC_ALL=ko_KR.UTF-8 LANG=ko_KR.UTF-8 swift test
```

This catches tests that only pass on machines configured for English.

## Test Frameworks

New tests use [Swift Testing](https://developer.apple.com/documentation/testing)
(`import Testing`, `@Suite`, `@Test`, `#expect`). Both frameworks run under
`swift test` and each reports its own totals, so a green run shows two summary
lines.

The XCTest suites stay as they are. The Objective-C ones in particular mirror
upstream test names one for one, which is what makes
`scripts/checkUpstreamTestParity.swift` meaningful; converting them would break
that mapping for no benefit.

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
