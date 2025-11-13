[![CocoaPods](https://img.shields.io/cocoapods/p/libPhoneNumber-iOS.svg?style=flat)](http://cocoapods.org/?q=libPhoneNumber-iOS)
[![CocoaPods](https://img.shields.io/cocoapods/v/libPhoneNumber-iOS.svg?style=flat)](http://cocoapods.org/?q=libPhoneNumber-iOS)
[![Travis](https://travis-ci.org/iziz/libPhoneNumber-iOS.svg?branch=master)](https://travis-ci.org/iziz/libPhoneNumber-iOS)
[![Coveralls](https://coveralls.io/repos/iziz/libPhoneNumber-iOS/badge.svg?branch=master&service=github)](https://coveralls.io/github/iziz/libPhoneNumber-iOS?branch=master)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

# **libPhoneNumber for iOS**

 - NBPhoneNumberUtil
 - NBAsYouTypeFormatter

> ARC only

## Update Log
[https://github.com/iziz/libPhoneNumber-iOS/wiki/Update-Log](https://github.com/iziz/libPhoneNumber-iOS/wiki/Update-Log)


## Issue
You can check phone number validation using below link.
https://rawgit.com/googlei18n/libphonenumber/master/javascript/i18n/phonenumbers/demo-compiled.html

Please report, if the above results are different from this iOS library.
Otherwise, please create issue to following link below to request additional telephone numbers formatting rule.
https://github.com/google/libphonenumber/issues

Metadata in this library was generated from that. so, you should change it first. :)

## Install

#### Using [CocoaPods](http://cocoapods.org/?q=libPhoneNumber-iOS)
```
source 'https://github.com/CocoaPods/Specs.git'
pod 'libPhoneNumber-iOS', '~> 0.8'
```
##### Installing libPhoneNumber Geocoding Features
```
pod 'libPhoneNumberGeocoding', :git => 'https://github.com/CocoaPods/Specs.git'
```

#### Using [Carthage](https://github.com/Carthage/Carthage)

 Carthage is a decentralized dependency manager that automates the process of adding frameworks to your Cocoa application.

 You can install Carthage with [Homebrew](http://brew.sh/) using the following command:

```bash
$ brew update
$ brew install carthage
```

To integrate libPhoneNumber into your Xcode project using Carthage, specify it in your `Cartfile`:

```ogdl
github "iziz/libPhoneNumber-iOS"
```

And set the **Embedded Content Contains Swift** to "Yes" in your build settings.

#### Setting up manually
 Add source files to your projects from libPhoneNumber
    - Add "Contacts.framework"

See sample test code from
> [libPhoneNumber-iOS/libPhoneNumberTests/ ... Test.m] (https://github.com/iziz/libPhoneNumber-iOS/tree/master/libPhoneNumberTests)

## Usage - **NBPhoneNumberUtil**
```obj-c
 NBPhoneNumberUtil *phoneUtil = [NBPhoneNumberUtil sharedInstance];
 NSError *anError = nil;
 NBPhoneNumber *myNumber = [phoneUtil parse:@"6766077303"
                              defaultRegion:@"AT" error:&anError];
 if (anError == nil) {
     NSLog(@"isValidPhoneNumber ? [%@]", [phoneUtil isValidNumber:myNumber] ? @"YES":@"NO");

     // E164          : +436766077303
     NSLog(@"E164          : %@", [phoneUtil format:myNumber
                                       numberFormat:NBEPhoneNumberFormatE164
                                              error:&anError]);
     // INTERNATIONAL : +43 676 6077303
     NSLog(@"INTERNATIONAL : %@", [phoneUtil format:myNumber
                                       numberFormat:NBEPhoneNumberFormatINTERNATIONAL
                                              error:&anError]);
     // NATIONAL      : 0676 6077303
     NSLog(@"NATIONAL      : %@", [phoneUtil format:myNumber
                                       numberFormat:NBEPhoneNumberFormatNATIONAL
                                              error:&anError]);
     // RFC3966       : tel:+43-676-6077303
     NSLog(@"RFC3966       : %@", [phoneUtil format:myNumber
                                       numberFormat:NBEPhoneNumberFormatRFC3966
                                              error:&anError]);
 } else {
     NSLog(@"Error : %@", [anError localizedDescription]);
 }

 NSLog (@"extractCountryCode [%@]", [phoneUtil extractCountryCode:@"823213123123" nationalNumber:nil]);

 NSString *nationalNumber = nil;
 NSNumber *countryCode = [phoneUtil extractCountryCode:@"823213123123" nationalNumber:&nationalNumber];

 NSLog (@"extractCountryCode [%@] [%@]", countryCode, nationalNumber);
```
##### Output
```
2014-07-06 12:39:37.240 libPhoneNumberTest[1581:60b] isValidPhoneNumber ? [YES]
2014-07-06 12:39:37.242 libPhoneNumberTest[1581:60b] E164          : +436766077303
2014-07-06 12:39:37.243 libPhoneNumberTest[1581:60b] INTERNATIONAL : +43 676 6077303
2014-07-06 12:39:37.243 libPhoneNumberTest[1581:60b] NATIONAL      : 0676 6077303
2014-07-06 12:39:37.244 libPhoneNumberTest[1581:60b] RFC3966       : tel:+43-676-6077303
2014-07-06 12:39:37.244 libPhoneNumberTest[1581:60b] extractCountryCode [82]
2014-07-06 12:39:37.245 libPhoneNumberTest[1581:60b] extractCountryCode [82] [3213123123]
```

#### with Swift
##### Case (1) with Framework
```
import libPhoneNumberiOS
```

##### Case (2) with Bridging-Header
```obj-c
// Manually added
#import "NBPhoneNumberUtil.h"
#import "NBPhoneNumber.h"

// CocoaPods (check your library path)
#import "libPhoneNumber_iOS/NBPhoneNumberUtil.h"
#import "libPhoneNumber_iOS/NBPhoneNumber.h"

// add more if you want...
```

##### Case (3) with CocoaPods
import libPhoneNumber_iOS


##### - in swift class file
###### 2.x
```swift
override func viewDidLoad() {
    super.viewDidLoad()

    guard let phoneUtil = NBPhoneNumberUtil.sharedInstance() else {
        return
    }

    do {
        let phoneNumber: NBPhoneNumber = try phoneUtil.parse("01065431234", defaultRegion: "KR")
        let formattedString: String = try phoneUtil.format(phoneNumber, numberFormat: .E164)

        NSLog("[%@]", formattedString)
    }
    catch let error as NSError {
        print(error.localizedDescription)
    }
}
```

## Usage - **NBAsYouTypeFormatter**
```obj-c
 NBAsYouTypeFormatter *f = [[NBAsYouTypeFormatter alloc] initWithRegionCode:@"US"];
    NSLog(@"%@", [f inputDigit:@"6"]); // "6"
    NSLog(@"%@", [f inputDigit:@"5"]); // "65"
    NSLog(@"%@", [f inputDigit:@"0"]); // "650"
    NSLog(@"%@", [f inputDigit:@"2"]); // "650 2"
    NSLog(@"%@", [f inputDigit:@"5"]); // "650 25"
    NSLog(@"%@", [f inputDigit:@"3"]); // "650 253"

    // Note this is how a US local number (without area code) should be formatted.
    NSLog(@"%@", [f inputDigit:@"2"]); // "650 2532"
    NSLog(@"%@", [f inputDigit:@"2"]); // "650 253 22"
    NSLog(@"%@", [f inputDigit:@"2"]); // "650 253 222"
    NSLog(@"%@", [f inputDigit:@"2"]); // "650 253 2222"
    // Can remove last digit
    NSLog(@"%@", [f removeLastDigit]); // "650 253 222"

    NSLog(@"%@", [f inputString:@"16502532222"]); // 1 650 253 2222
```

## libPhoneNumberGeocoding

For more information on libPhoneNumberGeocoding and its usage, please visit [libPhoneNumberGeocoding](https://github.com/iziz/libPhoneNumber-iOS/blob/master/libPhoneNumberGeocoding/README.md) for more information.

## libPhoneNumberShortNumber

For more information on libPhoneNumberShortNumber and its usage, please visit [libPhoneNumberShortNumber](https://github.com/iziz/libPhoneNumber-iOS/blob/master/libPhoneNumberShortNumber/README.md) for more information.

##### Visit [libphonenumber](https://github.com/google/libphonenumber) for more information or mail (zen.isis@gmail.com)

## Updating libPhoneNumber MetaData

We are dependent on the community to help keep this library up-to-date with the latest libPhoneNumber MetaData from Google.

When new versions of libPhoneNumber MetaData are released from Google, please feel free to work to update this repo with a pull request.
Make sure to follow the steps below to update the main MetaData & the Geocoding MetaData (even if you don't consume all of the functionality).

To see the current version of MetaData used by this library, check the commit comments and/or release notes. To correlate the version of metadata go to Google's [libphonenumber repo](https://github.com/google/libphonenumber).


### Update Main MetaData
1. `cd` into the `scripts` directory
2. Run `metadataGenerator.swift` passing in the desired version number

   ```
   ./metadataGenerator.swift 1.2.3
   ```

3. Run `GeneratePhoneNumberMetaDataFiles.sh` to update the generated files
4. Update the `generatedJSON` files to be "pretty printed" so that consumers can easily compare commits to see differences (add the `-p` argument)

   ```
   ./metadataGenerator.swift 1.2.3 -p
   ```
> NOTE: Don't want to generate the phone number MetaData off of the pretty-printed files because that takes up A LOT more space


### Update Geocoding MetaData
1. Open the libPhoneNumber-GeocodingParser project in Xcode
2. Edit the libPhoneNumber-GeocodingParser Scheme
3. In the `Run` section go to the `Arguments` tab
4. Edit the version argument to be the desired version number
5. Add an argument specifying the output directory (ex. `/Users/john.doe/geocoding`)
6. Run the libPhoneNumber-GeocodingParser program in Xcode (`Cmd+R`) on your machine
7. Wait a few minutes for the program to complete (the console will say when the program is done)
8. Copy the `*.db` files from your specified output directory to `libPhoneNumberGeocodingMetaData/GeocodingMetaData.bundle`


### Validating Updates
1. Open the libPhoneNumber project in Xcode
2. Run the tests for each library of the project:
 * libPhoneNumber
 * libPhoneNumberGeocoding
 * libPhoneNumberShortNumber

3. Open the `Package.swift` SPM project in Xcode
4. Run the tests for the package - `libPhoneNumber-Package` (runs the tests for each of the package targets in one run)

#### Optional Validation: Cocoapods
1. `cd` into the `libPhoneNumber-Demo` directory
2. Verify the `Podfile` is pointing to the local copies of the pods (using `:path => '../'`)
2. Run `pod install`
3. Open the `libPhoneNumber-Demo` project in Xcode
4. Run the demo project validating phonenumber formatting works as expected


#### Optional Validation: Swift Package Manager
1. Open the `libPhoneNumber-Demo-SPM` project in Xcode
2. Verify the `libPhoneNumber` package is using the `local` version
2. Run the demo project validating phonenumber formatting works as expected