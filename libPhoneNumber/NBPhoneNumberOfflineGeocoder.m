//
//  NBPhoneNumberOfflineGeocoder.m
//  libPhoneNumberiOS
//
//  Created by Rastaar Haghi on 6/12/20.
//  Copyright © 2020 ohtalk.me. All rights reserved.
//

#import "NBPhoneNumberOfflineGeocoder.h"

@implementation NBPhoneNumberOfflineGeocoder

- (instancetype)init {
  self = [super init];
  self.phoneUtil = NBPhoneNumberUtil.sharedInstance;
  // gather all available language database files
  NSBundle *bundle = [NSBundle bundleForClass:self.classForCoder];
  NSURL *bundleURL = [[bundle resourceURL] URLByAppendingPathComponent:@"Resources.bundle"];
  NSArray *filesInResourceBundle =
      [[NSFileManager defaultManager] contentsOfDirectoryAtURL:bundleURL
                                    includingPropertiesForKeys:NULL
                                                       options:0
                                                         error:NULL];
  NSMutableArray *supportedLanguages = [[NSMutableArray alloc] init];
  [filesInResourceBundle enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
    NSString *filename = (NSString *)obj;
    if (filename != NULL) {
      [supportedLanguages addObject:[[filename lastPathComponent] stringByDeletingPathExtension]];
    }
  }];
  NSString *language;
  // need to get from ios device settings
  if ([[NSLocale preferredLanguages] count] > 0) {
    // set language to preferred
    language = [NSLocale preferredLanguages][0];
    // if the preferred language isn't supported by metadata, set by default to english
    if (![supportedLanguages containsObject:language]) {
      language = @"en";
      NSLog(@"Set default language to ENGLISH");
    }
  } else {
    language = @"en";
  }

  self.geocoderHelper = [[NBGeocoderMetadataHelper alloc] initWithCountryCode:@1
                                                                 withLanguage:language];
  return self;
}

- (NSString *)countryNameForNumber:(NBPhoneNumber *)number withLanguage:(NSLocale *)language {
  if (number == NULL) return @"";
  NSArray *regionCodes = [_phoneUtil getRegionCodesForCountryCode:number.countryCode];
  if ([regionCodes count] == 1) {
    NSLog(@"Region code array: %@", regionCodes);
    return [self regionDisplayName:[regionCodes objectAtIndex:0] withLanguage:language];
  } else {
    NSString *regionWhereNumberIsValid = @"ZZ";
    for (NSString *regionCode in regionCodes) {
      NSLog(@"RegionCode: %@", regionCode);
      if ([self.phoneUtil isValidNumberForRegion:number regionCode:regionCode]) {
        if (![regionWhereNumberIsValid isEqualToString:@"ZZ"]) {
          NSLog(@"multiple valid regions found, so returning none");
          return @"";
        }
        NSLog(@"Setting regionWhereNumberIsValid to %@", regionCode);
        regionWhereNumberIsValid = regionCode;
      }
    }
    NSLog(@"Returning where regionWhereNumberIsValid to %@", regionWhereNumberIsValid);
    return [self regionDisplayName:regionWhereNumberIsValid withLanguage:language];
  }
}

- (NSString *)regionDisplayName:(NSString *)regionCode withLanguage:(NSLocale *)language {
  return (regionCode == NULL || [regionCode isEqualToString:@"ZZ"] ||
          [regionCode isEqual:NB_REGION_CODE_FOR_NON_GEO_ENTITY])
             ? @""
             : [[[NSLocale alloc] initWithLocaleIdentifier:language.localeIdentifier]
                   displayNameForKey:NSLocaleCountryCode
                               value:regionCode];
}

- (NSString *)descriptionForValidNumber:(NBPhoneNumber *)number withLanguage:(NSLocale *)language {
  [self.geocoderHelper setLanguage:language.languageCode];
  NSString *descriptionResult =
      [self.geocoderHelper searchPhoneNumberInDatabase:number withLanguage:language.languageCode];
  if ([descriptionResult isEqualToString:@""]) {
    return @"";
  } else {
    return descriptionResult;
  }
}

- (NSString *)descriptionForValidNumber:(NBPhoneNumber *)phoneNumber
                           withLanguage:(NSLocale *)language
                         withUserRegion:(NSString *)userRegion {
  NSString *regionCode = [self.phoneUtil getRegionCodeForNumber:phoneNumber];
  if ([userRegion isEqualToString:regionCode]) {
    return [self descriptionForValidNumber:phoneNumber withLanguage:language];
  }

  return [self regionDisplayName:regionCode withLanguage:language];
}

- (NSString *)descriptionForNumber:(NBPhoneNumber *)phoneNumber withLocale:(NSLocale *)locale {
  NBEPhoneNumberType numberType = [self.phoneUtil getNumberType:phoneNumber];
  if (numberType == NBEPhoneNumberTypeUNKNOWN) {
    return @"";
  } else if (![self.phoneUtil isNumberGeographical:phoneNumber]) {
    return [self countryNameForNumber:phoneNumber withLanguage:locale];
  }
  return [self descriptionForValidNumber:phoneNumber withLanguage:locale];
}

- (NSString *)descriptionForNumber:(NBPhoneNumber *)phoneNumber
                  withLanguageCode:(NSLocale *)languageCode
                    withUserRegion:(NSString *)userRegion {
  NBEPhoneNumberType numberType = [self.phoneUtil getNumberType:phoneNumber];
  if (numberType == NBEPhoneNumberTypeUNKNOWN) {
    return @"";
  } else if (![self.phoneUtil isNumberGeographical:phoneNumber]) {
    return [self countryNameForNumber:phoneNumber withLanguage:languageCode];
  }
  return [self descriptionForValidNumber:phoneNumber
                            withLanguage:languageCode
                          withUserRegion:userRegion];
}

@end
