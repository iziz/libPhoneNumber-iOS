# libPhoneNumber for iOS 

* NBPhoneNumberUtil
* NBAsYouTypeFormatter

### - Install with [CocoaPods](http://cocoapods.org/?q=libPhoneNumber-iOS)

### - Install without CocoaPods
##### Add source files to your projects from libPhoneNumber
    - NBPhoneNumberUtil.h, .m
    - NBAsYouTypeFormatter.h, .m
    
    - NBNumberFormat.h, .m
    - NBPhoneNumber.h, .m
    - NBPhoneNumberDesc.h, .m
    - NBPhoneNumberDefines.h
    
    - NBPhoneNumberMetadata.h, .m
    - NBPhoneNumberMetadataForTesting.h, .m
    
    - Add "NBPhoneNumberMetadata.plist" and "NBPhoneNumberMetadataForTesting.plist" to bundle resources
    - Add "CoreTelephony.framework"

    See sample test code from "libPhoneNumber-iOS / libPhoneNumberTests / libPhoneNumberTests.m"

### Sample Usage
    NBPhoneNumberUtil *phoneUtil = [NBPhoneNumberUtil sharedInstance];
    
    NSError *aError = nil;
    NBPhoneNumber *myNumber = [phoneUtil parse:@"6766077303" defaultRegion:@"AT" error:&aError];
    
    if (aError == nil) {
        // Should check error
        NSLog(@"isValidPhoneNumber ? [%@]", [phoneUtil isValidNumber:myNumber] ? @"YES":@"NO");
        NSLog(@"E164          : %@", [phoneUtil format:myNumber numberFormat:NBEPhoneNumberFormatE164 
                                                 error:&aError]);
        NSLog(@"INTERNATIONAL : %@", [phoneUtil format:myNumber numberFormat:NBEPhoneNumberFormatINTERNATIONAL 
                                                 error:&aError]);
        NSLog(@"NATIONAL      : %@", [phoneUtil format:myNumber numberFormat:NBEPhoneNumberFormatNATIONAL 
                                                 error:&aError]);
        NSLog(@"RFC3966       : %@", [phoneUtil format:myNumber numberFormat:NBEPhoneNumberFormatRFC3966 
                                                 error:&aError]);
    }
    else {
        NSLog(@"Error : %@", [aError localizedDescription]);
    }
    
    NSLog (@"extractCountryCode [%ld]", [phoneUtil extractCountryCode:@"823213123123" 
                                                       nationalNumber:nil]);
    
    NSString *res = nil;
    UInt32 dRes = [phoneUtil extractCountryCode:@"823213123123" nationalNumber:&res];
    
    NSLog (@"extractCountryCode [%lu] [%@]", dRes, res);


##### Visit [libPhoneNumber](http://code.google.com/p/libphonenumber/) for more information or mail (zen.isis@gmail.com)

### Metadata managing (updating metadata)
##### Step1. Fetch "metadata.js" and "metadatafortesting.js" from Repositories
    svn checkout http://libphonenumber.googlecode.com/svn/trunk/ libphonenumber-read-only
      
##### Step2. Convert Javascript Object to JSON using PHP scripts 
    Output - "PhoneNumberMetaData.json" and "PhoneNumberMetaDataForTesting.json"

##### Step3. Generate binary file from NBPhoneMetaDataGenerator
    Output - "NBPhoneNumberMetadata.plist" and "NBPhoneNumberMetadataForTesting.plist"

##### Step4. Update exists "NBPhoneNumberMetadata.plist" and "NBPhoneNumberMetadataForTesting.plist" files
