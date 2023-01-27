
# **libPhoneNumberShortNumber for iOS**

- NBShortNumberUtil

> ARC only

## Update Log
[https://github.com/iziz/libPhoneNumber-iOS/wiki/Update-Log](https://github.com/iziz/libPhoneNumber-iOS/wiki/Update-Log)


## Install 

The libPhoneNumberShortNumber pod requires the libPhoneNumber-iOS framework in order to build. This framework
will automatically download the libPhoneNumber-iOS cocoapod if not already included in the project podfile. 

#### Using [CocoaPods](http://cocoapods.org/?q=libPhoneNumber-iOS)
```
pod 'libPhoneNumberShortNumber', :git => 'https://github.com/iziz/libPhoneNumber-iOS'
```

And set the **Embedded Content Contains Swift** to "Yes" in your build settings.

See sample test code from
> [libPhoneNumber-iOS/libPhoneNumberShortNumberTests/ ... Test.m] (https://github.com/iziz/libPhoneNumber-iOS/tree/master/libPhoneNumberShortNumberTests)


#### with Swift
##### Case (1) with Framework
```
import libPhoneNumberShortNumber
```

##### Case (2) with Bridging-Header
```obj-c
// Manually added
#import "NBShortNumberUtil.h"
#import "NBPhoneNumber.h"

// CocoaPods (check your library path)
#import "libPhoneNumberShortNumber/NBShortNumberUtil.h"
#import "libPhoneNumberShortNumber/NBPhoneNumber.h"

// add more if you want...
```

## Usage - **NBShortNumberUtil**
```obj-c
NBShortNumberUtil *shortNumberUtil = [NBShortNumberUtil sharedInstance];
    
    // possibleNumber                  : +33123456
    NSLog(@"Is possible short number: %d",
          [shortNumberUtil isPossibleShortNumber:possibleNumber]);
    // validNumber                     : +331010
    NSLog(@"Is valid short number: %d", [shortNumberUtil isValidShortNumber:validNumber]);

    // carrierSpecificNumber           : +133669
    NSLog(@"Is carrier specific number: %d",
          [shortNumberUtil isPhoneNumberCarrierSpecific:carrierSpecificNumber]);

    // notCarrierSpecific              : +1911
    NSLog(@"Is carrier specific number: %d",
          [shortNumberUtil isPhoneNumberCarrierSpecific:notCarrierSpecific]);

    // premiumRateNumber               : +3336665
    NSLog(@"Premium Rate Phone Number: %lu",
          [shortNumberUtil expectedCostOfPhoneNumber:premiumRateNumber forRegion:@"FR"]);

    // emergencyNumber
    NSLog(@"Connects to Emergency Number From String: %d",
          [shortNumberUtil connectsToEmergencyNumberFromString:@"911" forRegion:@"US"]);
    
```
##### Output
```
    Is possible short number: 1
    Is valid short number: 1
    Is carrier specific number: 1
    Is carrier specific number: 0
    Premium Rate Phone Number: 3
    Connects to Emergency Number From String: 1
```

##### Visit [libphonenumber](https://github.com/google/libphonenumber) for more information
