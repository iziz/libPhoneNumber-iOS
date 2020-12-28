# **libPhoneNumberGeocoding for iOS**

 - NBPhoneNumberOfflineGeocoder

> ARC only

## Update Log
[https://github.com/iziz/libPhoneNumber-iOS/wiki/Update-Log](https://github.com/iziz/libPhoneNumber-iOS/wiki/Update-Log)


## Install 

The libPhoneNumberGeocoding pod requires the libPhoneNumber-iOS framework in order to build. This framework
will automatically download the libPhoneNumber-iOS cocoapod if not already included in the project podfile. 

#### Using [CocoaPods](http://cocoapods.org/?q=libPhoneNumber-iOS)
```
pod 'libPhoneNumberGeocoding', :git => 'https://github.com/iziz/libPhoneNumber-iOS'
```

And set the **Embedded Content Contains Swift** to "Yes" in your build settings.

See sample test code from
> [libPhoneNumber-iOS/libPhoneNumberGeocodingTests/ ... Test.m] (https://github.com/iziz/libPhoneNumber-iOS/tree/master/libPhoneNumberGeocodingTests)


#### with Swift
##### Case (1) with Framework
```
import libPhoneNumberGeocoding
```

##### Case (2) with Bridging-Header
```obj-c
// Manually added
#import "NBPhoneNumberOfflineGeocoder.h"
#import "NBPhoneNumber.h"

// CocoaPods (check your library path)
#import "libPhoneNumberGeocoding/NBPhoneNumberOfflineGeocoder.h"
#import "libPhoneNumberGeocoding/NBPhoneNumber.h"

// add more if you want...
```

## Usage - **NBPhoneNumberOfflineGeocoder**
```obj-c
NBPhoneNumberOfflineGeocoder *geocoder = [[NBPhoneNumberOfflineGeocoder alloc] init];
    
    // unitedStatesPhoneNumber                   : +16509601234
    NSLog(@Valid US Number: "%@", [geocoder descriptionForNumber: unitedStatesPhoneNumber 
                                               withLanguageCode: @"en"]);
    // Convenience Method
    NSLog(@"Convenience Method: %@", [geocoder descriptionForNumber: unitedStatesPhoneNumber]);
       
    // United States Phone Number, with user located in Italy and device language set to Spanish
    NSLog(@"Method using Spanish Language: %@", [geocoder descriptionForNumber: unitedStatesPhoneNumber 
                                  withLanguageCode: @"es" 
                                    withUserRegion: @"IT"]);

    // southKoreaPhoneNumber                     : +8222123456
    NSLog(@"South Korea Phone Number: %@", [geocoder descriptionForNumber: southKoreaPhoneNumber 
                                                            withLanguageCode: @"en"]);
    NSLog(@"South Korea Phone Number: %@", [geocoder descriptionForNumber: southKoreanPhoneNumber 
                                                            withLanguageCode: @"ko"]);

    // invalidUSPhoneNumber                      : +1123456789
    NSLog(@"%@", [geocoder descriptionForNumber: invalidUSPhoneNumber 
                                  withLanguageCode: @"en"]);
                                  
    // Non-geographical South Korea Phone Number: +82101234567
    NSLog(@"Non-geographical number: %@", [geocoder descriptionForNumber: southKoreaMobilePhone]);
```
##### Output
```
    Valid US Number: Mountain View, CA
    Convenience Method: Mountain View, CA
    Method using Spanish Language: Estados Unidos
    South Korea Phone Number: Seoul
    South Korea Phone Number: 서울
    (null)
    Non-geographical number: South Korea
```

##### Visit [libphonenumber](https://github.com/google/libphonenumber) for more information
