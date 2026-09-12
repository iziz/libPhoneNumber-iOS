# Security Policy

## Supported Versions

| Version | Supported |
| --- | --- |
| 2.x | Yes |
| 1.7.x | Security fixes only, for projects that cannot build with Xcode 27 |
| < 1.7 | No |

## Reporting a Vulnerability

Report vulnerabilities privately through
[GitHub's private vulnerability reporting](https://github.com/iziz/libPhoneNumber-iOS/security/advisories/new).
Do not open a public issue for a suspected vulnerability.

Please include the affected version, the integration method (Swift Package
Manager, CocoaPods, Carthage, or manual), and an input that reproduces the
problem. Phone numbers in a report are treated as test data; do not send real
users' numbers.

You can expect an initial response within 7 days.

## Scope

This library parses untrusted text. Reports that are in scope include:

- Crashes, hangs, or unbounded memory growth reachable from a parsing,
  formatting, validation, geocoding, or short-number API.
- Catastrophic backtracking in the regular expressions built from metadata.
- Reads of data outside the bundled metadata.

The following are not vulnerabilities:

- A number being classified as valid or invalid contrary to expectation. That is
  a metadata or parity issue; open a normal issue.
- Carrier or timezone results being wrong or outdated. Both come from prefix
  metadata, and the carrier data reflects original assignment rather than the
  current carrier in regions with number portability.
- Geocoding descriptions being coarser than expected for languages whose
  database carries only their own country.
