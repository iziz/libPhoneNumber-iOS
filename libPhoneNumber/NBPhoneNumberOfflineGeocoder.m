//
//  NBPhoneNumberOfflineGeocoder.m
//  libPhoneNumberiOS
//
//  Created by Rastaar Haghi on 6/12/20.
//  Copyright © 2020 ohtalk.me. All rights reserved.
//

#import "NBPhoneNumberOfflineGeocoder.h"

@implementation NBPhoneNumberOfflineGeocoder

-(instancetype) init {
    self = [super init];
    self.supportedLanguages = @[@"ar", @"be", @"bg", @"bs", @"de", @"el", @"en", @"es", @"fa", @"fi", @"fr", @"hr", @"hu", @"hy", @"id", @"it", @"iw", @"ja", @"ko", @"nl", @"pl", @"pt", @"ro", @"ru", @"sq", @"sr", @"sv", @"th", @"tr", @"uk", @"vi", @"zh_Hant", @"zh"];
    
    // need to get from ios device settings
    if ([[NSLocale preferredLanguages] count] > 0) {
        // set language to preferred
        self.language = [NSLocale preferredLanguages][0];
        // if the preferred language isn't supported by metadata, set by default to english
        if(![self.supportedLanguages containsObject:self.language]) {
            self.language = @"en";
            NSLog(@"Set default language to ENGLISH");
        }
    }
    
    NSLog(@"Preferred language: %@", _language);
    self.geocoderHelper = [[NBGeocoderMetadataHelper alloc] initWithCountryCode:@"1" withLanguage:self.language];
    NBPhoneNumber *usPremiumNumber = [[NBPhoneNumber alloc] init];
    usPremiumNumber.countryCode = @1;
    usPremiumNumber.nationalNumber = @9098611758;
    NSLog(@"The test showed: %@", [self getDescriptionForNumber:usPremiumNumber withLanguage:self.language]);
    usPremiumNumber.countryCode = @20;
    usPremiumNumber.nationalNumber = @2046;
    NSLog(@"The test showed: %@", [self getDescriptionForNumber:usPremiumNumber withLanguage:self.language]);
    return self;
}
-(NSString*) getCountryNameForNumber: (NBPhoneNumber*) number withLanguage: (NSString*) language {
    return @"";
}
-(NSString*) getDescriptionForNumber: (NBPhoneNumber*) number withLanguage: (NSString*) language {
    NSString* descriptionResult = [self.geocoderHelper searchPhoneNumberInDatabase:number withLanguage: language];
    if(descriptionResult == NULL) {
        return @"unknown";
    } else {
        return descriptionResult;
    }
}

@end
