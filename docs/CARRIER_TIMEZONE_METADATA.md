# Carrier And Timezone Metadata Evaluation

Google libphonenumber ships carrier and timezone metadata outside the JavaScript metadata currently mirrored by this project. Adding those datasets could differentiate this library for global and enterprise apps, but it should be treated as a separate feature area rather than folded into the core parser.

## Recommended Direction

- Keep carrier and timezone metadata out of `libPhoneNumberSwiftCore`.
- Add separate Objective-C metadata bundles and Swift facade modules only if there is confirmed product demand.
- Prefer opt-in packages:
  - `libPhoneNumberCarrier`
  - `libPhoneNumberTimezone`
  - `libPhoneNumberSwiftCarrier`
  - `libPhoneNumberSwiftTimezone`
- Measure bundle size before adding checked-in metadata.

## Required Work Before Implementation

1. Identify the exact upstream metadata source files and license implications.
2. Build deterministic generators for carrier and timezone metadata.
3. Add tests against upstream examples.
4. Add package-size reporting to the release checklist.
5. Decide whether APIs return localized display names, stable identifiers, or both.

## API Shape To Consider

```swift
let carrier = PhoneNumberCarrierMapper.shared.name(for: number, languageCode: "en")
let timeZones = PhoneNumberTimeZoneMapper.shared.timeZones(for: number)
```

These APIs should delegate lookup behavior to generated metadata and should not add parsing rules outside the Objective-C core.
