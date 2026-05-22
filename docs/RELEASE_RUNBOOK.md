# Release Runbook

Use this runbook for metadata updates, version bumps, validation, GitHub releases, and CocoaPods publication. Keep command outputs and upstream refs in the pull request so future releases can audit the release decision from code and logs instead of memory.

## Release Types

- Patch release: bug fixes or metadata-only updates.
- Minor release: additive public API, new modules, or metadata work that also changes public behavior beyond freshness.
- Major release: breaking API or packaging changes.

Metadata-only releases should normally be patch releases. Do not add local metadata overrides unless the requirements in `docs/METADATA_PATCH_POLICY.md` are met.

## Preflight

Start from a clean working tree:

```bash
git status --short
```

Check the current local metadata ref and latest upstream candidate:

```bash
swift scripts/checkMetadataFreshness.swift --output .build/metadata-freshness
```

Review these generated artifacts before deciding scope:

- `.build/metadata-freshness/metadata-diff-summary.md`
- `.build/metadata-freshness/metadata-update-issue.md`
- `.build/metadata-freshness/metadata-update-pr.md`
- `.build/metadata-freshness/metadata-update-log-entry.md`

If the release is for a user-reported numbering-plan issue, add or run a focused regression test that proves the old metadata fails and the new metadata fixes the case.

## Update Metadata

Update main, testing, and short-number metadata:

```bash
swift scripts/metadataGenerator.swift <metadata-ref> --pretty
```

Update geocoding metadata when upstream geocoding resources changed:

```bash
swift scripts/updateGeocodingMetadata.swift <metadata-ref> --replace-bundle
```

Update carrier metadata when upstream carrier resources changed:

```bash
swift scripts/updateCarrierMetadata.swift <metadata-ref> --replace-bundle
```

Update timezone metadata when upstream timezone resources changed:

```bash
swift scripts/updateTimeZonesMetadata.swift <metadata-ref> --replace-bundle
```

Use `--output <dir>` instead of `--replace-bundle` when reviewing generated artifacts before changing checked-in bundles.

## Version Bump

Update all project, podspec, dependency, and README version references:

```bash
swift scripts/updateProjectVersions.swift <new-version>
```

Confirm version alignment:

```bash
swift scripts/checkVersionConsistency.swift
```

## Validation

Run upstream parity checks against the exact metadata ref:

```bash
swift scripts/checkUpstreamTestParity.swift --upstream-ref <metadata-ref>
swift scripts/checkUpstreamAPIParity.swift --upstream-ref <metadata-ref>
```

Run the local SwiftPM baseline:

```bash
swift test
LC_ALL=ko_KR.UTF-8 LANG=ko_KR.UTF-8 swift test
swift build -c release
git diff --check
```

Run the main Xcode schemes:

```bash
xcodebuild test -scheme libPhoneNumber -destination 'platform=iOS Simulator,name=iPhone 16'
xcodebuild test -scheme libPhoneNumberGeocoding -destination 'platform=iOS Simulator,name=iPhone 16'
xcodebuild test -scheme libPhoneNumberShortNumber -destination 'platform=iOS Simulator,name=iPhone 16'
```

If the simulator destination is ambiguous, use a concrete UDID:

```bash
xcodebuild -scheme libPhoneNumber -showdestinations
xcodebuild test -scheme libPhoneNumber -destination 'id=<simulator-udid>'
```

Run CocoaPods lint for every shipped podspec when packaging, dependency, or release metadata changed:

```bash
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

Re-run freshness after the metadata update to confirm the checked-in metadata matches the selected upstream ref:

```bash
swift scripts/checkMetadataFreshness.swift --current-ref <metadata-ref> --output .build/metadata-freshness
```

## Update Release Notes

Update `docs/METADATA_UPDATE_LOG.md` for metadata releases. Include:

- Previous local upstream ref.
- New upstream ref.
- Which metadata families changed.
- Issue-specific verification, when applicable.
- Commands that were run.
- Test, parity, build, lint, and freshness results.

The generated `.build/metadata-freshness/metadata-update-log-entry.md` is a starting point, not a substitute for recording release-specific results.

## Pull Request

Open a pull request that includes:

- Upstream metadata ref or source commit.
- Summary of changed metadata families and behavior impact.
- Links to issue-specific verification, if any.
- Upstream parity results.
- Local validation results.
- CocoaPods lint results when podspecs or packaging are affected.

Do not publish CocoaPods podspecs until the release commit is merged and the GitHub release/tag exists.

## GitHub Release

After merge, create the GitHub release for the new version tag. The tag must match each podspec `s.source` tag and `s.version`.

Before publishing, confirm the version alignment from the release checkout:

```bash
swift scripts/checkVersionConsistency.swift
```

## CocoaPods Publish

Check the dependency-aware publish plan first:

```bash
swift scripts/publishPodspecs.swift
```

Publish missing podspec versions in dependency order:

```bash
swift scripts/publishPodspecs.swift --publish
```

The publish script:

- Discovers all root `*.podspec` files.
- Parses actual podspec dependencies with `pod ipc spec`.
- Orders local podspecs so prerequisites publish before dependents.
- Skips versions that already exist on trunk.
- Checks trunk visibility after every push.
- Treats timeout or server errors as inconclusive until `pod trunk info` confirms whether the version exists.

If CocoaPods trunk returns a timeout or internal server error, do not change podspecs as a workaround. Re-run the script; it will skip versions that became visible and retry only missing versions.

## Final Verification

After publication, run:

```bash
swift scripts/publishPodspecs.swift
```

The release is complete only when every podspec version is reported as present on trunk.

Record any CocoaPods trunk incidents in the release notes or maintenance log when they affected the release process.
