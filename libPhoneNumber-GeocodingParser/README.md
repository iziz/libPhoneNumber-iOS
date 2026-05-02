# libPhoneNumber-iOS Geocoding File Parser

This Objective-C parser is the legacy Xcode project used to convert Google's libphonenumber geocoding text files into SQLite databases.

New metadata updates should use the repository-level command-line updater instead:

```bash
swift scripts/updateGeocodingMetadata.swift <libphonenumber-version> --replace-bundle
```

The Swift updater does not require opening Xcode, supports local source directories, and is suitable for CI or scripted maintenance.

## Legacy Parser Usage

The legacy parser accepts:

1. The Google libphonenumber version or `master`.
2. The local output directory for generated SQLite database files.

Example:

```text
9.0.29 /Users/JohnDoe/Documents/geocoding
```

Prefer the Swift updater unless you are specifically debugging this Objective-C parser.
