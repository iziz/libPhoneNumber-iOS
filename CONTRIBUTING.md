# Contributing

Thanks for helping maintain libPhoneNumber for iOS. This document covers what a
change needs before it can be merged. The deeper references live in `docs/`.

## Before You Start

This library is a port of Google's
[libphonenumber](https://github.com/google/libphonenumber). Parsing, formatting,
validation, geocoding, and short-number behavior follow upstream. If a number is
handled differently here than in Google's Java or JavaScript implementation,
that is a bug in this port; if you disagree with the behavior itself, the change
belongs upstream first.

Two consequences follow:

- Behavior changes should cite the upstream code or metadata they match.
- Metadata is generated, not edited. Run the updater scripts; do not hand-edit
  `libPhoneNumber/NBGeneratedPhoneNumberMetaData.m` or the `generatedJSON`
  files. Local overrides are only allowed under `docs/METADATA_PATCH_POLICY.md`.

## Where Code Goes

- The Objective-C core is the source of truth. Parsing and validation logic
  belongs in `libPhoneNumber/`, not in a Swift facade.
- The Swift facades are thin wrappers. They map types, they do not reimplement
  behavior.
- UI code belongs in `libPhoneNumberSwiftUI`, which consumers opt into
  separately.

## Development

Build and test:

```bash
swift test
```

The full local checklist, including the non-English locale run, the per-platform
builds, the thread sanitizer, and the Xcode scheme tests, is in
`docs/TESTING.md`.

Run the parity checks when you touch public API or the test suites:

```bash
swift scripts/checkUpstreamTestParity.swift
swift scripts/checkUpstreamAPIParity.swift
```

## Tests

Every bug fix needs a test that fails before the fix and passes after it. State
in the pull request that you checked this; a test that passes either way
documents behavior but does not protect it.

New tests use [Swift Testing](https://developer.apple.com/documentation/testing)
(`import Testing`). The existing XCTest suites, including the large
Objective-C ones ported from upstream, stay as they are; do not convert them
wholesale, because their structure is what makes upstream parity auditable.

## Concurrency

The Swift facades are declared `@unchecked Sendable` on the strength of the
Objective-C core's internal locking. If you add mutable state to any Objective-C
type reachable from a facade, that claim stops being true. Guard the state, and
extend the concurrency suites in `libPhoneNumberSwiftCoreTests` so the guarantee
is exercised rather than assumed. They run under the thread sanitizer in CI.

## Public API

Adding API is a minor release; changing or removing it is a major one. See
`docs/RELEASE_RUNBOOK.md`. Deprecate rather than delete where you can, and give
the deprecation message a replacement to point at.

Record anything user-visible in `CHANGELOG.md` under `## Unreleased`.

## Pull Requests

Fill in the pull request template. It asks for the upstream reference, the
metadata scope, the parity checks, and the test commands you ran. Paste the
command output rather than asserting the result, so a future release can audit
the decision from the log instead of from memory.

Keep the diff focused. Unrelated formatting churn makes the metadata and parity
review much harder.
