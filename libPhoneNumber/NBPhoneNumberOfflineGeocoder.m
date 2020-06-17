//
//  NBPhoneNumberOfflineGeocoder.m
//  libPhoneNumberiOS
//
//  Created by Rastaar Haghi on 6/12/20.
//  Copyright © 2020 ohtalk.me. All rights reserved.
//

#import "NBPhoneNumberOfflineGeocoder.h"

@implementation NBPhoneNumberOfflineGeocoder {
 @private
  NBPhoneNumberUtil *phoneUtil;
  NBGeocoderMetadataHelper *geocoderHelper;
}

- (instancetype)init {
  self = [super init];
  self->phoneUtil = NBPhoneNumberUtil.sharedInstance;
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

  self->geocoderHelper = [[NBGeocoderMetadataHelper alloc] initWithCountryCode:@1
                                                                  withLanguage:language];
  return self;
}

- (NSString *)countryNameForNumber:(NBPhoneNumber *)number
                  withLanguageCode:(NSString *)languageCode {
  if (number == NULL) return @"";
  NSArray *regionCodes = [self->phoneUtil getRegionCodesForCountryCode:number.countryCode];
  if ([regionCodes count] == 1) {
    return [self regionDisplayName:[regionCodes objectAtIndex:0] withLanguageCode:languageCode];
  } else {
    NSString *regionWhereNumberIsValid = @"ZZ";
    for (NSString *regionCode in regionCodes) {
      if ([self->phoneUtil isValidNumberForRegion:number regionCode:regionCode]) {
        if (![regionWhereNumberIsValid isEqualToString:@"ZZ"]) {
          NSLog(@"multiple valid regions found, so returning none");
          return @"";
        }
        NSLog(@"Setting regionWhereNumberIsValid to %@", regionCode);
        regionWhereNumberIsValid = regionCode;
      }
    }

    return [self regionDisplayName:regionWhereNumberIsValid withLanguageCode:languageCode];
  }
}

- (NSString *)regionDisplayName:(NSString *)regionCode withLanguageCode:(NSString *)languageCode {
  return (regionCode == NULL || [regionCode isEqualToString:@"ZZ"] ||
          [regionCode isEqual:NB_REGION_CODE_FOR_NON_GEO_ENTITY])
             ? @""
             : [[[NSLocale alloc] initWithLocaleIdentifier:languageCode]
                   displayNameForKey:NSLocaleCountryCode
                               value:regionCode];
}

- (NSString *)descriptionForValidNumber:(NBPhoneNumber *)number
                       withLanguageCode:(NSString *)languageCode {
  [self->geocoderHelper setLanguage:languageCode];
  NSString *descriptionResult = [self->geocoderHelper searchPhoneNumberInDatabase:number
                                                                     withLanguage:languageCode];
  if ([descriptionResult isEqualToString:@""]) {
    return @"";
  } else {
    return descriptionResult;
  }
}

- (NSString *)descriptionForValidNumber:(NBPhoneNumber *)phoneNumber
                       withLanguageCode:(NSString *)languageCode
                         withUserRegion:(NSString *)userRegion {
  NSString *regionCode = [self->phoneUtil getRegionCodeForNumber:phoneNumber];
  if ([userRegion isEqualToString:regionCode]) {
    return [self descriptionForValidNumber:phoneNumber withLanguageCode:languageCode];
  }

  return [self regionDisplayName:regionCode withLanguageCode:languageCode];
}

- (NSString *)descriptionForNumber:(NBPhoneNumber *)phoneNumber
                  withLanguageCode:(NSString *)languageCode {
  NBEPhoneNumberType numberType = [self->phoneUtil getNumberType:phoneNumber];
  if (numberType == NBEPhoneNumberTypeUNKNOWN) {
    return @"";
  } else if (![self->phoneUtil isNumberGeographical:phoneNumber]) {
    return [self countryNameForNumber:phoneNumber withLanguageCode:languageCode];
  }
  return [self descriptionForValidNumber:phoneNumber withLanguageCode:languageCode];
}

- (NSString *)descriptionForNumber:(NBPhoneNumber *)phoneNumber
                  withLanguageCode:(NSString *)languageCode
                    withUserRegion:(NSString *)userRegion {
  NBEPhoneNumberType numberType = [self->phoneUtil getNumberType:phoneNumber];
  if (numberType == NBEPhoneNumberTypeUNKNOWN) {
    return @"";
  } else if (![self->phoneUtil isNumberGeographical:phoneNumber]) {
    return [self countryNameForNumber:phoneNumber withLanguageCode:languageCode];
  }
  return [self descriptionForValidNumber:phoneNumber
                        withLanguageCode:languageCode
                          withUserRegion:userRegion];
}

- (NSString *)descriptionForNumber:(NBPhoneNumber *)phoneNumber {
  NBEPhoneNumberType numberType = [self->phoneUtil getNumberType:phoneNumber];
  NSString *languageCode;
  // need to get from ios device settings
  if ([[NSLocale preferredLanguages] count] > 0) {
    // set language to preferred
    languageCode = [NSLocale preferredLanguages][0];
  } else {
    languageCode = @"en";
  }
  if (numberType == NBEPhoneNumberTypeUNKNOWN) {
    return @"";
  } else if (![self->phoneUtil isNumberGeographical:phoneNumber]) {
    return [self countryNameForNumber:phoneNumber withLanguageCode:languageCode];
  }
  return [self descriptionForValidNumber:phoneNumber withLanguageCode:languageCode];
}
- (NSString *)descriptionForNumber:(NBPhoneNumber *)phoneNumber
                    withUserRegion:(NSString *)userRegion {
  NBEPhoneNumberType numberType = [self->phoneUtil getNumberType:phoneNumber];
  NSString *languageCode;
  // need to get from ios device settings
  if ([[NSLocale preferredLanguages] count] > 0) {
    // set language to preferred
    languageCode = [NSLocale preferredLanguages][0];
  } else {
    languageCode = @"en";
  }
  if (numberType == NBEPhoneNumberTypeUNKNOWN) {
    return @"";
  } else if (![self->phoneUtil isNumberGeographical:phoneNumber]) {
    NSLog(@"not geographical");
    return [self countryNameForNumber:phoneNumber withLanguageCode:languageCode];
  }
  return [self descriptionForValidNumber:phoneNumber
                        withLanguageCode:languageCode
                          withUserRegion:userRegion];
}

@end
