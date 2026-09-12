# ``libPhoneNumberSwiftCore``

Parse, format, and validate international phone numbers from Swift.

## Overview

This module is the Swift-first entry point to libPhoneNumber for iOS. It wraps
the Objective-C core, which is a port of Google's
[libphonenumber](https://github.com/google/libphonenumber) and remains the
source of truth for behavior.

Start with ``PhoneNumberUtility``:

```swift
import libPhoneNumberSwiftCore

let utility = PhoneNumberUtility.shared
let number = try utility.parse("01065431234", defaultRegion: "KR")

try utility.format(number, as: .e164)   // "+821065431234"
utility.isValidNumber(number)           // true
utility.type(of: number)                // .mobile
```

Geocoding, short numbers, carrier lookup, timezone lookup, and the SwiftUI input
field are separate modules, so an app only pays for the metadata it uses.

## Values Versus Numbers

``PhoneNumber`` is the Objective-C model object. It is a mutable reference type
and is not `Sendable`, so it should stay inside the scope that parsed it.

For anything that is stored, sent across an actor boundary, or encoded, use
``PhoneNumberValue``, which is an immutable `Codable`, `Hashable`, `Sendable`
struct:

```swift
let value = try utility.value(from: "01065431234", defaultRegion: "KR").get()
value.e164                       // "+821065431234"
value.nationalSignificantNumber  // "1065431234"
```

A value converts back to a number through
``PhoneNumberUtility/phoneNumber(from:)``.

## Concurrency

``PhoneNumberUtility`` is `Sendable`, and the shared instance is safe to use
from any task. The conformance is `@unchecked`, resting on the locking inside
the Objective-C core rather than on anything the compiler can verify, and the
package's test suite exercises the shared instances under concurrent load with
the thread sanitizer enabled.

``AsYouTypeFormatter`` is deliberately not `Sendable`. Each instance accumulates
the digits entered so far, so create one per input field.

## Errors

Throwing APIs surface the `NSError` raised by the Objective-C core.
`Result`-returning APIs report ``PhoneNumberValueError``, which distinguishes
input that could not be parsed from a number that could not be formatted.

```swift
switch utility.value(from: userInput, defaultRegion: "US") {
case let .success(value):
    store(value.e164)
case .failure(.invalidInput):
    showFieldError()
case let .failure(error):
    log(error)
}
```

## Topics

### Parsing and Formatting

- ``PhoneNumberUtility``
- ``PhoneNumber``
- ``PhoneNumberFormat``

### Values

- ``PhoneNumberValue``
- ``PhoneNumberValueError``

### Classification

- ``PhoneNumberType``
- ``ValidationResult``
- ``MatchType``
- ``CountryCodeSource``

### Input

- ``AsYouTypeFormatter``
