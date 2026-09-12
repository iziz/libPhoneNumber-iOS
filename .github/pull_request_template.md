## Summary

- 

## Upstream / Metadata

- Google libphonenumber ref:
- Metadata updated: yes/no
- Geocoding metadata updated: yes/no

## Parity Checks

- [ ] `swift scripts/checkUpstreamTestParity.swift --upstream-ref <ref>`
- [ ] `swift scripts/checkUpstreamAPIParity.swift --upstream-ref <ref>`

## Tests

- [ ] `swift test`
- [ ] `LC_ALL=ko_KR.UTF-8 LANG=ko_KR.UTF-8 swift test`
- [ ] `swift build -c release`
- [ ] `swift test --sanitize=thread` (when shared state or a facade entry point changed)
- [ ] `xcodebuild test -scheme libPhoneNumber -destination 'id=<simulator-udid>'`
- [ ] `xcodebuild test -scheme libPhoneNumberGeocoding -destination 'id=<simulator-udid>'`
- [ ] `xcodebuild test -scheme libPhoneNumberShortNumber -destination 'id=<simulator-udid>'`
- [ ] `git diff --check`

## Changelog

- [ ] `CHANGELOG.md` updated under `## Unreleased`, or not user-visible

## Notes

- Intentional ObjC/API naming differences:
- Upstream behavior intentionally not ported:
