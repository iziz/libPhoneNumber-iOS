# Changelog

This file records user-visible changes. Metadata refreshes are listed in
`docs/METADATA_UPDATE_LOG.md` and are only summarized here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html)
as described in `docs/RELEASE_RUNBOOK.md`.

## Unreleased

## 2.1.0

Additive. No public API is removed or changed, so this is a minor release.

The one compatibility note is the toolchain: the Swift package now requires
Swift 6 tools, so Swift Package Manager consumers need Xcode 16 or later.
Deployment targets are unchanged, and the CocoaPods specs accept Swift 5.9 or
6.0.

### Fixed

- Geocoding now finds its metadata when the package is consumed through Swift
  Package Manager. `NBGeocoderMetaDataHelper` looked for
  `GeocodingMetaData.bundle` directly beside the consuming binary, which is only
  where CocoaPods, Carthage, and manual integration put it. SwiftPM nests the
  payload inside a generated wrapper bundle, so no database was ever opened and
  every lookup fell back to the country name, with no error and no crash. The
  same search the carrier and timezone mappers already use is now applied here,
  covering both the flat layout SwiftPM emitted up to Xcode 26 and the
  macOS-structured layout it emits from Xcode 27. `descriptionForNumber:` on a
  Mountain View number returns `"Mountain View, CA"` instead of
  `"United States"`.
- A geocoding lookup for a country a language's database does not carry no
  longer disables that language permanently. Preparing the query for a missing
  table left the finalized statement in place, after which every later lookup in
  that language short-circuited to nil. A Korean-locale app that geocoded one US
  number lost city-level Korean geocoding for the rest of the process.
- `NBMetadataHelper`'s region-to-calling-code table is built under a lock. It was
  populated lazily with no synchronization, so concurrent first use raced.
- `NBPhoneNumberOfflineGeocoder` creates its per-language helpers under a lock,
  instead of a check-then-insert that let concurrent callers each open their own
  SQLite connection for the same language.

### Added

- visionOS is a supported platform. It is declared in `Package.swift`, every
  podspec sets `visionos.deployment_target`, and CI builds every product for it.
- All Swift facade entry points are `Sendable`, so `PhoneNumberUtility.shared`
  and its siblings can be used from Swift 6 code without a concurrency error.
  `PhoneNumberFieldState` stays non-`Sendable` because it carries the error
  raised by the Objective-C core, whose domain and code callers rely on; use
  `PhoneNumberValue` for state that leaves the field's concurrency domain.
  The conformances are `@unchecked` and documented against the Objective-C
  core's locking, and the concurrency test suite exercises the shared instances
  from many tasks at once under the thread sanitizer.
- `PhoneNumberValueError` conforms to `Sendable` and `LocalizedError`, and gains
  `init(_: Error)` for wrapping errors raised by the Objective-C core.
- `NBGeocoderMetaDataHelper.defaultMetadataBundle` is public, so integrators can
  check whether the geocoding metadata resolved at all.
- Test coverage for the Swift facades: Objective-C enum bridging is pinned case
  by case, concurrency is exercised under load, and each optional module has
  behavioral tests beyond its single smoke test.
- CI builds every product for iOS, tvOS, watchOS, visionOS, and Mac Catalyst,
  runs the suite under the thread sanitizer, publishes a coverage report, and
  lints every podspec. Five podspecs were previously never linted, and four
  declared platforms were never built.

### Changed

- The package requires Swift 6 tools (`swift-tools-version:6.0`) and builds in
  the Swift 6 language mode. Podspecs accept Swift 5.9 or 6.0.
- `PhoneNumberUtility.phoneNumber(from:)` reports failures through
  `PhoneNumberValueError(_:)`, consistent with the other `Result`-returning APIs.
- The regular-expression cache compiles patterns outside its lock, so a cache hit
  is no longer serialized behind an unrelated pattern being built.

### Maintenance

- Refresh Google libphonenumber metadata from `v9.0.38` to `v9.0.39`, including
  phone-number, carrier, and geocoding changes. The timezone source data is
  unchanged; see `docs/METADATA_UPDATE_LOG.md` for the comparison and checks.
- `scripts/testXcodeSchemes.swift` resolves an installed iPhone simulator
  instead of defaulting to a pinned model name. The pinned name fails outright
  on any machine whose Xcode ships a different set of simulators.
- `scripts/publishPodspecs.swift` parses `pod ipc spec` output starting at the
  first brace, so CocoaPods' non-UTF-8 terminal warning is no longer reported as
  a malformed podspec.
- `CONTRIBUTING.md`, `SECURITY.md`, `CHANGELOG.md`, and issue templates added.
- A DocC catalog documents the Swift core facade, covering the value type, the
  concurrency guarantees, and the error model.

### Deprecated

- `PhoneNumberError`. It was public but never thrown; every throwing API reports
  failures as `PhoneNumberValueError` or the underlying `NSError`. It will be
  removed in the next major version.

## 2.0.1

- Resolve carrier and timezone metadata bundles under the Xcode 27 SwiftPM
  layout. Both fell back silently before: `timeZonesForNumber:` returned
  `Etc/Unknown` and carrier lookups returned nil.

## 2.0.0

- Raise deployment targets to the lowest versions Xcode 27 accepts: iOS 15,
  macCatalyst 15, tvOS 15, watchOS 9, macOS 12. Version 1.7.x remains available
  for iOS 12, tvOS 12, watchOS 4, and macOS 10.13, but cannot be built with
  Xcode 27.

## 1.6.0

- Add Swift-first facade modules for core parsing, geocoding, short numbers,
  carrier lookup, timezone lookup, and a SwiftUI phone input.

## 1.7.x and earlier

See the [release history](https://github.com/iziz/libPhoneNumber-iOS/releases).
