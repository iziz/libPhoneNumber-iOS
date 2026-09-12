//
//  NBPhoneNumberOfflineGeocoder.m
//  libPhoneNumberiOS
//
//  Created by Rastaar Haghi on 6/12/20.
//  Copyright © 2020 Google LLC. All rights reserved.
//

#import "NBGeocoderMetaDataHelper.h"
#import "NBPhoneNumberOfflineGeocoder.h"
#import "NBPhoneNumber.h"
#import "NBPhoneNumberUtil.h"

@implementation NBPhoneNumberOfflineGeocoder {
 @private
  NBPhoneNumberUtil *_phoneNumberUtil;
  NSCache<NSString *, NBGeocoderMetaDataHelper *> *_metadataHelpers;
  NBGeocoderMetaDataHelperFactory _metadataHelperFactory;
}

static NSString *const INVALID_REGION_CODE = @"ZZ";

- (instancetype)init {
  return [self
      initWithMetaDataHelperFactory:^NBGeocoderMetaDataHelper *(NSNumber *_Nonnull countryCode,
                                                                NSString *_Nonnull language) {
        return [[NBGeocoderMetaDataHelper alloc] initWithCountryCode:countryCode
                                                        withLanguage:language];
      }
                    phoneNumberUtil:NBPhoneNumberUtil.sharedInstance];
}

- (instancetype)initWithMetaDataHelperFactory:(NBGeocoderMetaDataHelperFactory)factory
                              phoneNumberUtil:(NBPhoneNumberUtil *)phoneNumberUtil {
  self = [super init];
  if (self != nil) {
    _phoneNumberUtil = phoneNumberUtil;
    _metadataHelpers = [[NSCache alloc] init];
    _metadataHelperFactory = [factory copy];
  }
  return self;
}

+ (NBPhoneNumberOfflineGeocoder *)sharedInstance {
  static dispatch_once_t onceToken;
  static NBPhoneNumberOfflineGeocoder *instance;
  dispatch_once(&onceToken, ^{
    instance = [[self alloc] init];
  });
  return instance;
}

// Returns the cached helper for |languageCode|, creating it on first use.
//
// The lookup and the insertion are performed under a single lock so concurrent
// callers cannot each open their own SQLite connection for the same language.
- (NBGeocoderMetaDataHelper *)metadataHelperForLanguageCode:(NSString *)languageCode
                                                countryCode:(NSNumber *)countryCode {
  @synchronized(self) {
    NBGeocoderMetaDataHelper *helper = [_metadataHelpers objectForKey:languageCode];
    if (helper == nil) {
      helper = _metadataHelperFactory(countryCode, languageCode);
      if (helper != nil) {
        [_metadataHelpers setObject:helper forKey:languageCode];
      }
    }
    return helper;
  }
}

- (nullable NSString *)descriptionForValidNumber:(NBPhoneNumber *)phoneNumber
                                withLanguageCode:(NSString *)languageCode {
  // If the NSCache doesn't contain a key equivalent to languageCode, create a
  // new NBGeocoderMetadataHelper object with a language set equal to
  // languageCode and default country code to United States / Canada
  NBGeocoderMetaDataHelper *helper =
      [self metadataHelperForLanguageCode:languageCode countryCode:phoneNumber.countryCode];
  NSString *result = [helper searchPhoneNumber:phoneNumber];
  if (result == nil) {
    return [self countryNameForNumber:phoneNumber withLanguageCode:languageCode];
  } else {
    return result;
  }
}

- (nullable NSString *)descriptionForValidNumber:(NBPhoneNumber *)phoneNumber
                                withLanguageCode:(NSString *)languageCode
                                  withUserRegion:(NSString *)userRegion {
  NSString *regionCode = [_phoneNumberUtil getRegionCodeForNumber:phoneNumber];
  if ([userRegion isEqualToString:regionCode]) {
    return [self descriptionForValidNumber:phoneNumber withLanguageCode:languageCode];
  }
  return [self regionDisplayName:regionCode withLanguageCode:languageCode];
}

- (nullable NSString *)descriptionForNumber:(NBPhoneNumber *)phoneNumber
                           withLanguageCode:(NSString *)languageCode {
  NBEPhoneNumberType numberType = [_phoneNumberUtil getNumberType:phoneNumber];
  if (numberType == NBEPhoneNumberTypeUNKNOWN) {
    return nil;
  } else if (![_phoneNumberUtil isNumberGeographical:phoneNumber]) {
    return [self countryNameForNumber:phoneNumber withLanguageCode:languageCode];
  }
  return [self descriptionForValidNumber:phoneNumber withLanguageCode:languageCode];
}

- (nullable NSString *)descriptionForNumber:(NBPhoneNumber *)phoneNumber
                           withLanguageCode:(NSString *)languageCode
                             withUserRegion:(NSString *)userRegion {
  NBEPhoneNumberType numberType = [_phoneNumberUtil getNumberType:phoneNumber];
  if (numberType == NBEPhoneNumberTypeUNKNOWN) {
    return nil;
  } else if (![_phoneNumberUtil isNumberGeographical:phoneNumber]) {
    return [self countryNameForNumber:phoneNumber withLanguageCode:languageCode];
  }
  return [self descriptionForValidNumber:phoneNumber
                        withLanguageCode:languageCode
                          withUserRegion:userRegion];
}

- (nullable NSString *)descriptionForNumber:(NBPhoneNumber *)phoneNumber {
  NBEPhoneNumberType numberType = [_phoneNumberUtil getNumberType:phoneNumber];
  NSString *languageCode = [[NSLocale preferredLanguages] firstObject];

  if (languageCode == nil) {
    return nil;
  }

  if (numberType == NBEPhoneNumberTypeUNKNOWN) {
    return nil;
  } else if (![_phoneNumberUtil isNumberGeographical:phoneNumber]) {
    return [self countryNameForNumber:phoneNumber withLanguageCode:languageCode];
  }
  return [self descriptionForValidNumber:phoneNumber withLanguageCode:languageCode];
}

- (nullable NSString *)descriptionForNumber:(NBPhoneNumber *)phoneNumber
                             withUserRegion:(NSString *)userRegion {
  NBEPhoneNumberType numberType = [_phoneNumberUtil getNumberType:phoneNumber];
  NSString *languageCode = [[NSLocale preferredLanguages] firstObject];

  if (languageCode == nil) {
    return nil;
  }

  if (numberType == NBEPhoneNumberTypeUNKNOWN) {
    return nil;
  } else if (![_phoneNumberUtil isNumberGeographical:phoneNumber]) {
    return [self countryNameForNumber:phoneNumber withLanguageCode:languageCode];
  }
  return [self descriptionForValidNumber:phoneNumber
                        withLanguageCode:languageCode
                          withUserRegion:userRegion];
}

- (nullable NSString *)countryNameForNumber:(NBPhoneNumber *)number
                           withLanguageCode:(NSString *)languageCode {
  NSArray *regionCodes = [_phoneNumberUtil getRegionCodesForCountryCode:number.countryCode];
  if ([regionCodes count] == 1) {
    return [self regionDisplayName:regionCodes[0] withLanguageCode:languageCode];
  } else {
    NSString *regionWhereNumberIsValid = INVALID_REGION_CODE;
    for (NSString *regionCode in regionCodes) {
      if ([_phoneNumberUtil isValidNumberForRegion:number regionCode:regionCode]) {
        if (![regionWhereNumberIsValid isEqualToString:INVALID_REGION_CODE]) {
          return nil;
        }
        regionWhereNumberIsValid = regionCode;
      }
    }

    return [self regionDisplayName:regionWhereNumberIsValid withLanguageCode:languageCode];
  }
}

- (nullable NSString *)regionDisplayName:(NSString *)regionCode
                        withLanguageCode:(NSString *)languageCode {
  if (regionCode == nil || [regionCode isEqualToString:INVALID_REGION_CODE] ||
      [regionCode isEqual:NB_REGION_CODE_FOR_NON_GEO_ENTITY]) {
    return nil;
  } else {
    return [[NSLocale localeWithLocaleIdentifier:languageCode] displayNameForKey:NSLocaleCountryCode
                                                                           value:regionCode];
  }
}

@end
