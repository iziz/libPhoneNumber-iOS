# Carrier And Timezone Metadata

Google libphonenumber ships carrier and timezone metadata outside the JavaScript metadata currently mirrored by this project. These datasets can make libPhoneNumber-iOS useful for CRM, support, global contact forms, analytics enrichment, and SwiftUI phone-input hints, but they must remain opt-in because they add metadata size and their results are prefix-based estimates.

## Product Principle

- Keep carrier and timezone metadata out of `libPhoneNumberSwiftCore`.
- Keep carrier and timezone metadata out of `libPhoneNumberIOSSwift` until there is explicit demand for a larger full umbrella.
- Add separate Objective-C lookup modules and Swift facade modules.
- Treat Google libphonenumber metadata as the source of truth.
- Generate deterministic checked-in metadata artifacts from an explicit upstream ref.
- Document that carrier lookup returns the originally allocated carrier prefix, not the current carrier after number portability.
- Document that timezone lookup returns possible CLDR timezone IDs from prefix metadata, not the user's current location.

## Upstream Sources

Use these Google libphonenumber paths as the upstream inputs and behavior references:

| Area | Upstream path | Notes |
| --- | --- | --- |
| Carrier text metadata | `resources/carrier/<locale>/<country-calling-code>.txt` | Locale-specific prefix-to-carrier mappings. |
| Mobile portability metadata | `resources/PhoneNumberMetadata.xml` | `mobileNumberPortableRegion` territories used by carrier safe-display behavior. |
| Carrier mapper behavior | `java/carrier/src/com/google/i18n/phonenumbers/PhoneNumberToCarrierMapper.java` | Mobile, fixed-line-or-mobile, and pager lookup; safe-display behavior for mobile portability regions. |
| Carrier tests | `java/carrier/test/com/google/i18n/phonenumbers/PhoneNumberToCarrierMapperTest.java` | Port representative behavior tests. |
| Timezone text metadata | `resources/timezones/map_data.txt` | Prefix-to-CLDR-timezone-ID mappings. |
| Timezone mapper behavior | `java/geocoder/src/com/google/i18n/phonenumbers/PhoneNumberToTimeZonesMapper.java` | Valid-number check, geographical fallback, country-level fallback, `Etc/Unknown`. |
| Timezone tests | `java/geocoder/test/com/google/i18n/phonenumbers/PhoneNumberToTimeZonesMapperTest.java` | Port representative behavior tests. |
| Prefix mapper internals | `java/internal/prefixmapper/src/com/google/i18n/phonenumbers/prefixmapper/` | Longest-prefix lookup, locale fallback, and timezone tokenization behavior. |

Current checked-in metadata is generated from upstream `v9.0.30`:

- Carrier resources: 219 `.txt` files, 698,755 bytes before packing.
- Carrier rows: 31,001 prefix mappings.
- Carrier locales observed: `ar`, `be`, `en`, `fa`, `ko`, `ru`, `uk`, `zh`, `zh_Hant`.
- Mobile portable regions: 107 territories from `PhoneNumberMetadata.xml`.
- Timezone resources: one `map_data.txt` file, about 92 KB before packing.
- Timezone rows: 3,294 prefix mappings.
- Timezone values are CLDR/ICU timezone IDs, separated by `&` when a prefix maps to multiple zones.
- Packed carrier bundle size: about 2.0 MB.
- Packed timezone bundle size: about 232 KB.

## Modules

### Swift Package Manager

| Product | Target | Depends on |
| --- | --- | --- |
| `libPhoneNumberCarrier` | `libPhoneNumberCarrier` | `libPhoneNumber` |
| `libPhoneNumberTimeZones` | `libPhoneNumberTimeZones` | `libPhoneNumber` |
| `libPhoneNumberSwiftCarrier` | `libPhoneNumberSwiftCarrier` | `libPhoneNumberSwiftCore`, `libPhoneNumberCarrier` |
| `libPhoneNumberSwiftTimeZones` | `libPhoneNumberSwiftTimeZones` | `libPhoneNumberSwiftCore`, `libPhoneNumberTimeZones` |
| `libPhoneNumberSwiftUIEnrichment` | `libPhoneNumberSwiftUIEnrichment` | `libPhoneNumberSwiftUI`, optional enrichment facades |

Do not add these modules to `libPhoneNumberSwiftCore` or the default SwiftUI module. SwiftUI enrichment should be opt-in.

### CocoaPods

| Pod | Module |
| --- | --- |
| `libPhoneNumberCarrier` | `libPhoneNumberCarrier` |
| `libPhoneNumberTimeZones` | `libPhoneNumberTimeZones` |
| `libPhoneNumber-iOS-SwiftCarrier` | `libPhoneNumberSwiftCarrier` |
| `libPhoneNumber-iOS-SwiftTimeZones` | `libPhoneNumberSwiftTimeZones` |
| `libPhoneNumber-iOS-SwiftUIEnrichment` | `libPhoneNumberSwiftUIEnrichment` |

The first shipped carrier/timezone modules used a minor release because they added public modules. Later carrier/timezone metadata-only refreshes should use patch releases.

## Metadata Format

Prefer SQLite bundles for both datasets unless a prototype proves that generated Objective-C dictionaries are materially smaller and faster.

SQLite advantages:

- Deterministic ordering and schema.
- Works well with large prefix maps.
- Supports lazy loading.
- Mirrors the existing geocoding metadata bundle pattern.
- Keeps metadata separate from code review noise.

Recommended schema:

```sql
CREATE TABLE metadata_info (
  key TEXT PRIMARY KEY NOT NULL,
  value TEXT NOT NULL
);

CREATE TABLE carrier_prefixes (
  locale TEXT NOT NULL,
  prefix TEXT NOT NULL,
  carrier_name TEXT NOT NULL,
  PRIMARY KEY (locale, prefix)
);

CREATE INDEX carrier_prefixes_lookup
ON carrier_prefixes(locale, prefix);

CREATE TABLE mobile_portable_regions (
  region_code TEXT PRIMARY KEY NOT NULL
);

CREATE TABLE timezone_prefixes (
  prefix TEXT PRIMARY KEY NOT NULL,
  time_zones TEXT NOT NULL
);
```

Store `upstream_ref`, `generated_at_utc`, `schema_version`, and `source_digest` in `metadata_info`. Sort all inserted rows by locale and numeric prefix string before writing.

## Metadata Generators

Use these generators when working directly with carrier/timezone metadata:

```bash
swift scripts/updateCarrierMetadata.swift <version-or-ref> --output /tmp/carrier-review
swift scripts/updateTimeZonesMetadata.swift <version-or-ref> --output /tmp/timezone-review
```

Current status:

- `scripts/updateTimeZonesMetadata.swift` exists as a deterministic timezone generator.
- It parses `resources/timezones/map_data.txt`, validates prefixes and timezone IDs, writes `timezone-prefixes.json`, `timezone-size-report.md`, `timezone-update-log-entry.md`, and supports `--source`, `--output`, `--replace-bundle`, `--dry-run`, and `--keep-temp`.
- `libPhoneNumberTimeZonesMetaData/TimeZonesMetaData.bundle/timezones.db` is generated from Google libphonenumber `v9.0.30`.
- `libPhoneNumberTimeZones` exists as an Objective-C SPM module.
- `libPhoneNumberSwiftTimeZones` exists as a Swift SPM facade.
- `scripts/updateCarrierMetadata.swift` exists as a deterministic carrier generator.
- It parses `resources/carrier`, validates prefixes and carrier names, parses `mobileNumberPortableRegion` from `resources/PhoneNumberMetadata.xml`, writes `carrier-prefixes.json`, `carrier-size-report.md`, `carrier-update-log-entry.md`, and supports `--source`, `--output`, `--replace-bundle`, `--dry-run`, and `--keep-temp`.
- `libPhoneNumberCarrierMetaData/CarrierMetaData.bundle/carriers.db` is generated from Google libphonenumber `v9.0.30`.
- `libPhoneNumberCarrier` exists as an Objective-C SPM and CocoaPods module.
- `libPhoneNumberSwiftCarrier` exists as a Swift SPM and CocoaPods facade.
- `libPhoneNumberSwiftUIEnrichment` exists as an optional SPM and CocoaPods module connecting carrier/timezone metadata to SwiftUI state.

Generator options:

- `--source <path>`: Use an existing Google libphonenumber checkout.
- `--output <path>`: Write review artifacts without replacing checked-in bundles.
- `--replace-bundle`: Replace checked-in metadata bundles.
- `--dry-run`: Parse, validate, and size-report without writing checked-in files.
- `--pretty`: Write normalized text/JSON review artifacts if useful.

Generator behavior:

- Reject malformed prefix rows.
- Reject duplicate locale/prefix rows unless upstream has an intentional duplicate policy documented.
- Sort deterministically before writing.
- Write a size report with raw source size, packed bundle size, and per-locale carrier row counts.
- Write a metadata summary suitable for `docs/METADATA_UPDATE_LOG.md`.
- Produce identical checked-in output when run twice from the same upstream ref.

## Objective-C API

### Carrier

```objc
@interface NBPhoneNumberToCarrierMapper : NSObject

+ (instancetype)sharedInstance;

- (NSString *)nameForNumber:(NBPhoneNumber *)number
                 localeCode:(NSString *)localeCode;

- (NSString *)nameForValidNumber:(NBPhoneNumber *)number
                       localeCode:(NSString *)localeCode;

- (NSString *)safeDisplayNameForNumber:(NBPhoneNumber *)number
                             localeCode:(NSString *)localeCode;

@end
```

Behavior:

- `nameForNumber` checks the number type first.
- Lookup is allowed for `MOBILE`, `FIXED_LINE_OR_MOBILE`, and `PAGER`.
- Invalid numbers return `@""`.
- Missing metadata returns `@""`.
- Locale fallback follows upstream: fallback to English except for Chinese, Japanese, and Korean.
- `safeDisplayNameForNumber` returns `@""` for mobile-number-portable regions.

### Timezones

```objc
@interface NBPhoneNumberToTimeZonesMapper : NSObject

+ (instancetype)sharedInstance;

+ (NSString *)unknownTimeZone;

- (NSArray<NSString *> *)timeZonesForNumber:(NBPhoneNumber *)number;

- (NSArray<NSString *> *)timeZonesForGeographicalNumber:(NBPhoneNumber *)number;

@end
```

Behavior:

- Unknown result is `@[ @"Etc/Unknown" ]`.
- `timeZonesForNumber` checks number type and geographical suitability before lookup.
- Non-geographical valid numbers use country-level timezone lookup.
- `timeZonesForGeographicalNumber` assumes the caller already knows the number is geocodable, but still returns `Etc/Unknown` when no prefix mapping exists.

## Swift API

### Carrier

```swift
public final class PhoneNumberCarrierMapper {
    public static let shared: PhoneNumberCarrierMapper

    public func name(for number: PhoneNumber, localeCode: String) -> String?
    public func nameForValidNumber(_ number: PhoneNumber, localeCode: String) -> String?
    public func safeDisplayName(for number: PhoneNumber, localeCode: String) -> String?
}
```

Return `nil` when upstream returns an empty string.

### Timezones

```swift
public final class PhoneNumberTimeZonesMapper {
    public static let shared: PhoneNumberTimeZonesMapper

    public static let unknownTimeZone = "Etc/Unknown"

    public func timeZones(for number: PhoneNumber) -> [String]
    public func timeZonesForGeographicalNumber(_ number: PhoneNumber) -> [String]
}
```

Return upstream-compatible `["Etc/Unknown"]` for unknown results.

## SwiftUI Enrichment

Keep `libPhoneNumberSwiftUI` dependent only on `libPhoneNumberSwiftCore`. Add an optional enrichment protocol in the lightweight SwiftUI module:

```swift
public struct PhoneNumberEnrichment: Equatable, Sendable {
    public var carrierName: String?
    public var timeZones: [String]
}

public protocol PhoneNumberEnriching {
    func enrichment(for number: PhoneNumber, regionCode: String?) -> PhoneNumberEnrichment
}
```

Then add `libPhoneNumberSwiftUIEnrichment` with a concrete implementation:

```swift
public struct CarrierTimeZonesPhoneNumberEnricher: PhoneNumberEnriching {
    public func enrichment(for number: PhoneNumber, regionCode: String?) -> PhoneNumberEnrichment
}
```

`PhoneNumberTextField` can accept an optional enricher without importing carrier/timezone metadata by default.

## Testing

Port representative upstream tests:

- Carrier mobile portable region.
- Carrier non-mobile-portable region.
- Carrier fixed-line number.
- Carrier fixed-line-or-mobile number.
- Carrier pager number.
- Carrier invalid number.
- Carrier missing prefix.
- Carrier missing metadata file.
- Carrier locale fallback.
- Timezone valid geographical number.
- Timezone invalid number.
- Timezone invalid country code.
- Timezone non-geographical number.
- Timezone country-level fallback.
- Timezone multiple-zone prefix.

Local integration tests:

- `swift test`
- `LC_ALL=ko_KR.UTF-8 LANG=ko_KR.UTF-8 swift test`
- `swift build -c release`
- `swift scripts/publishPodspecs.swift --lint`
- Generator determinism test: run generation twice from the same source and confirm no diff.
- Bundle missing/corrupt tests should return deterministic empty or unknown results without crashing.

## Size Measurement

Every carrier/timezone update should report:

- Raw upstream carrier resource size.
- Packed carrier bundle size.
- Carrier row count by locale.
- Raw upstream timezone resource size.
- Packed timezone bundle size.
- Timezone row count.
- Delta compared with the previous checked-in bundle.

Record the result in `docs/METADATA_UPDATE_LOG.md`.

## Implementation Status

- Deterministic carrier and timezone generators are implemented.
- SQLite bundles are the checked-in packed format.
- Objective-C carrier and timezone modules are implemented.
- Swift carrier and timezone facade modules are implemented.
- Optional SwiftUI enrichment protocol and concrete carrier/timezone enricher are implemented.
- SPM products, CocoaPods podspecs, README installation examples, package selection guidance, and release validation hooks are implemented.

## Release Criteria

- No carrier/timezone metadata is linked by `libPhoneNumberSwiftCore`.
- No carrier/timezone metadata is linked by default `libPhoneNumberSwiftUI`.
- All new metadata modules are opt-in.
- Upstream behavior differences are documented before release.
- Generated metadata is reproducible from the recorded upstream ref.
- Bundle size impact is measured and documented.
- All validation commands in `docs/TESTING.md` pass for the new modules.
