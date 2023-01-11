//
//  NBPhoneNumberOfflineGeocoder.h
//  libPhoneNumberiOS
//
//  Created by Rastaar Haghi on 6/12/20.
//  Copyright © 2020 Google LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NBGeocoderMetadataHelper;
@class NBPhoneNumber;
@class NBPhoneNumberUtil;

NS_ASSUME_NONNULL_BEGIN

typedef NBGeocoderMetadataHelper *_Nonnull (^NBGeocoderMetadataHelperFactory)(NSNumber *countryCode,
                                                                              NSString *language);

@interface NBPhoneNumberOfflineGeocoder : NSObject

/**
 * Returns an instance of NBPhoneNumberOfflineGeocoder that uses a desired and
 * predefined NBGeocoderMetadataHelperFactory method to use whenever this class
 * creates an object of type NBGeocoderMetadataHelper
 *
 * @param factory  a factory method, with countryCode and language parameters,
 * that returns an instance of NBGeocoderMetadataHelper
 * @param phoneNumberUtil an instance of NBPhoneNumberUtil class.
 * @return an instance of NBPhoneNumberOfflineGeocoder that creates
 * NBGeocoderMetadataHelper instances using the factory method parameter
 */
- (instancetype)initWithMetadataHelperFactory:(NBGeocoderMetadataHelperFactory)factory
                              phoneNumberUtil:(NBPhoneNumberUtil *)phoneNumberUtil;

/**
 * Returns an instance of NBPhoneNumberOfflineGeocoder that uses a default
 * NBPhoneNumberOfflineGeocoder factory. This method only allows a single
 * instane of the class NBPhoneNumberOfflineGeocoder to exist during the
 * lifecycle of current application.
 *
 *  @return an instance of NBPhoneNumberOfflineGeocoder that creates
 * NBGeocoderMetadataHelper instances using a default factory method
 */
+ (NBPhoneNumberOfflineGeocoder *)sharedInstance;

/**
 * Returns a text description for the given phone number, in the language
 * provided. The description might consist of the name of the country where the
 * phone number is from, or the name of the geographical area the phone number
 * is from if more detailed information is available.
 *
 * This method assumes the validity of the number passed in has already been
 * checked, and that the number is suitable for geocoding. We consider
 * fixed-line and mobile numbers possible candidates for geocoding.
 *
 * @param phoneNumber  a valid phone number for which we want to get a text
 * description
 * @param languageCode  the language code for which the description should be
 * written
 * @return a text description for the given language code for the given phone
 * number, or returns nil if the number could come from multiple countries, the
 * country code is in fact invalid, or doesn't have a region description
 * available.
 */
- (nullable NSString *)descriptionForValidNumber:(NBPhoneNumber *)phoneNumber
                                withLanguageCode:(NSString *)languageCode;

/**
 * Returns a text description for the given phone number, in the language
 * provided, but also considers the region of the user. If the phone number is
 * from the same region as the user, only a lower-level description will be
 * returned, if one exists. Otherwise, the phone number's region will be
 * returned, with optionally some more detailed information.
 *
 * For example, for a user from the region "US" (United States), we would show
 * "Mountain View, CA" for a particular number, omitting the United States from
 * the description. For a user from the United Kingdom (region "GB"), for the
 * same number we may show "Mountain View, CA, United States" or even just
 * "United States".
 *
 * This method assumes the validity of the number passed in has already been
 * checked.
 *
 * @param phoneNumber  the phone number for which we want to get a text
 * description
 * @param languageCode  the language code for which the description should be
 * written
 * @param userRegion  the region code for a given user. This region will be
 * omitted from the description if the phone number comes from this region. It
 * should be a two-letter upper-case CLDR region code.
 * @return a text description for the given language code for the given phone
 * number, or returns nil if the number could come from multiple countries, the
 * country code is invalid, or doesn't have a region description available.
 */
- (nullable NSString *)descriptionForValidNumber:(NBPhoneNumber *)phoneNumber
                                withLanguageCode:(NSString *)languageCode
                                  withUserRegion:(NSString *)userRegion;

/**
 * As per descriptionForValidNumber:phoneNumber:languageCode but explicitly
 * checks the validity of the number passed in.
 *
 * @param phoneNumber  the phone number for which we want to get a text
 * description
 * @param languageCode  the language code for which the description should be
 * written
 * @return a text description for the given language code for the given phone
 * number, or returns nil if the number passed in is invalid, could belong to
 * multiple countries, or doesn't have a region description available.
 */
- (nullable NSString *)descriptionForNumber:(NBPhoneNumber *)phoneNumber
                           withLanguageCode:(NSString *)languageCode;

/**
 * As per descriptionForValidNumber:phoneNumber:languageCode:userRegion  but
 * explicitly checks the validity of the number passed in.
 *
 * @param phoneNumber  the phone number for which we want to get a text
 * description
 * @param languageCode  the language code for which the description should be
 * written
 * @param userRegion  the region code for a given user. This region will be
 * omitted from the description if the phone number comes from this region. It
 * should be a two-letter upper-case CLDR region code.
 * @return a text description for the given language code for the given phone
 * number, or returns nil if the number passed in is invalid, could belong to
 * multiple countries, or doesn't have a region description available.
 */
- (nullable NSString *)descriptionForNumber:(NBPhoneNumber *)phoneNumber
                           withLanguageCode:(NSString *)languageCode
                             withUserRegion:(NSString *)userRegion;

#pragma mark - Convenience Methods

/**
 * Convenience method.
 * As per descriptionForNumber:phoneNumber:languageCode but manually gathers
 * device's preferred language code using NSLocale.
 * @param phoneNumber  the phone number for which we want to get a text
 * description
 * @return a text description for the given language code for the given phone
 * number, or returns nil if the number passed in is invalid, could belong to
 * multiple countries, cannot obtain a language code using NSLocale, or doesn't
 * have a region description available.
 */
- (nullable NSString *)descriptionForNumber:(NBPhoneNumber *)phoneNumber;

/**
 * Convenience method.
 * As per descriptionForNumber:phoneNumber:languageCode:userRegion manually
 * gathers device's preferred language code using NSLocale.
 *
 * @param phoneNumber  the phone number for which we want to get a text
 * description
 * @param userRegion  the region code for a given user. This region will be
 * omitted from the description if the phone number comes from this region. It
 * should be a two-letter upper-case CLDR region code.
 * @return a text description for the given language code for the given phone
 * number, or returns nil if the number passed in is invalid, could belong to
 * multiple countries, cannot obtain a language code using NSLocale, or doesn't
 * have a region description available.
 */
- (nullable NSString *)descriptionForNumber:(NBPhoneNumber *)phoneNumber
                             withUserRegion:(NSString *)userRegion;

@end

NS_ASSUME_NONNULL_END
