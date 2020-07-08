//
//  NBGeocoderMetadataHelper.h
//  libPhoneNumberiOS
//
//  Created by Rastaar Haghi on 6/12/20.
//  Copyright © 2020 Google LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NBPhoneNumber;

NS_ASSUME_NONNULL_BEGIN

@interface NBGeocoderMetadataHelper : NSObject

/**
 * Initializer method that creates a SQLite3 connection to the correct database (based on
 * the language passed in as a parameter), which is stored in the resource bundle of this project.
 * This method opens the database for viewing if possible and prepares a query statement with
 * the country code parameter
 *
 * @param countryCode a valid country code for which we want to set up a prepared statement to
 *  access a SQLite table with that country code.
 * @param languageCode  the language code for which the description should be written
 * @return a NBGeocoderMetadataHelper instance variable with an initial country code and language
 *     code set to the parameters, countryCode and  languageCode, or nil if the NSObject couldn't be
 *     initialized or there was no database URL found for the provided language code.
 */
- (instancetype)initWithCountryCode:(NSNumber *)countryCode
                       withLanguage:(NSString *)languageCode
                         withBundle:(NSBundle *)bundle;

- (instancetype)initWithCountryCode:(NSNumber *)countryCode withLanguage:(NSString *)languageCode;

/**
 * Returns a text description for the given phone number. The description will be based on the
 * country code and national number attributes of the NBPhoneNumber parameter. If no result was
 * found from querying the geocoding databases, this method will return nil.
 *
 * This method assumes the validity of the NBPhoneNumber object passed in that it contains a
 * countryCode and nationalNumber attribute. This method prepares a select statement to search
 * through a SQLite database for the most accurate text description for the phone number parameter.
 *
 * @param phoneNumber  a valid phone number for which we want to get a text description
 * @return a text description for the given language code for the given phone number, or nil if
 *     there were no search results found for the given phone number.
 */
- (NSString *)searchPhoneNumber:(NBPhoneNumber *)phoneNumber;

@end

NS_ASSUME_NONNULL_END
