//
//  NBPhoneNumberUtil.h
//  libPhoneNumber
//
//  Created by tabby on 2015. 2. 8..
//  Copyright (c) 2015년 ohtalk.me. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NBPhoneNumberDefines.h"

@class NBPhoneMetaData, NBPhoneNumber, NBMetadataHelper;

@interface NBPhoneNumberUtil : NSObject

+ (NBPhoneNumberUtil * _Nonnull)sharedInstance;
- (instancetype _Nonnull)initWithMetadataHelper:(NBMetadataHelper * _Nonnull)helper;

- (instancetype _Nonnull)init NS_UNAVAILABLE;

@property(nonatomic, strong, readonly, nonnull) NSDictionary * DIGIT_MAPPINGS;

// regular expressions
- (NSArray * _Nullable)matchesByRegex:(NSString * _Nonnull)sourceString regex:(NSString * _Nonnull)pattern;
- (NSArray * _Nullable)matchedStringByRegex:(NSString * _Nonnull)sourceString regex:(NSString * _Nonnull)pattern;
- (NSString * _Nonnull)replaceStringByRegex:(NSString * _Nonnull)sourceString
                                      regex:(NSString * _Nonnull)pattern
                               withTemplate:(NSString * _Nonnull)templateString;
- (int)stringPositionByRegex:(NSString * _Nullable)sourceString regex:(NSString * _Nullable)pattern;

// libPhoneNumber Util functions
- (NSString * _Nonnull)convertAlphaCharactersInNumber:(NSString * _Nonnull)number;

- (NSString * _Nonnull)normalize:(NSString * _Nonnull)number;
- (NSString * _Nonnull)normalizeDigitsOnly:(NSString * _Nonnull)number;
- (NSString * _Nonnull)normalizeDiallableCharsOnly:(NSString * _Nonnull)number;

- (BOOL)isNumberGeographical:(NBPhoneNumber * _Nonnull)phoneNumber;

- (NSString * _Nonnull)extractPossibleNumber:(NSString * _Nonnull)number;
- (NSNumber * _Nonnull)extractCountryCode:(NSString * _Nonnull)fullNumber nationalNumber:(NSString * _Nullable * _Nullable)nationalNumber;
- (NSString * _Nonnull)countryCodeByCarrier;

- (NSString * _Nullable)getNddPrefixForRegion:(NSString * _Nullable)regionCode stripNonDigits:(BOOL)stripNonDigits;
- (NSString * _Nonnull)getNationalSignificantNumber:(NBPhoneNumber * _Nonnull)phoneNumber;

- (NSArray * _Nullable)getSupportedRegions;

- (NBEPhoneNumberType)getNumberType:(NBPhoneNumber * _Nonnull)phoneNumber;

- (NSNumber * _Nonnull)getCountryCodeForRegion:(NSString * _Nullable)regionCode;

- (NSString * _Nonnull)getRegionCodeForCountryCode:(NSNumber * _Nonnull)countryCallingCode;
- (NSArray * _Nullable)getRegionCodesForCountryCode:(NSNumber * _Nonnull)countryCallingCode;
- (NSString * _Nullable)getRegionCodeForNumber:(NBPhoneNumber * _Nullable)phoneNumber;

- (NBPhoneNumber * _Nullable)getExampleNumber:(NSString * _Nonnull)regionCode error:(NSError * _Nullable __autoreleasing * _Nullable)error;
- (NBPhoneNumber * _Nullable)getExampleNumberForType:(NSString * _Nonnull)regionCode
                                                type:(NBEPhoneNumberType)type
                                               error:(NSError * _Nullable __autoreleasing * _Nullable)error;
- (NBPhoneNumber * _Nullable)getExampleNumberForNonGeoEntity:(NSNumber * _Nonnull)countryCallingCode
                                                       error:(NSError * _Nullable * _Nullable)error;

- (BOOL)canBeInternationallyDialled:(NBPhoneNumber * _Nonnull)number error:(NSError * _Nullable * _Nullable)error;

- (BOOL)truncateTooLongNumber:(NBPhoneNumber * _Nonnull)number;

- (BOOL)isValidNumber:(NBPhoneNumber * _Nonnull)number;
- (BOOL)isViablePhoneNumber:(NSString * _Nonnull)phoneNumber;
- (BOOL)isAlphaNumber:(NSString * _Nonnull)number;
- (BOOL)isValidNumberForRegion:(NBPhoneNumber * _Nonnull)number regionCode:(NSString * _Nonnull)regionCode;
- (BOOL)isNANPACountry:(NSString * _Nullable)regionCode;
- (BOOL)isLeadingZeroPossible:(NSNumber * _Nonnull)countryCallingCode;

- (NBEValidationResult)isPossibleNumberWithReason:(NBPhoneNumber * _Nonnull)number
                                            error:(NSError * _Nullable * _Nullable)error;

- (BOOL)isPossibleNumber:(NBPhoneNumber * _Nonnull)number;
- (BOOL)isPossibleNumber:(NBPhoneNumber * _Nonnull)number error:(NSError * _Nullable * _Nullable)error;
- (BOOL)isPossibleNumberString:(NSString * _Nonnull)number
             regionDialingFrom:(NSString * _Nullable)regionDialingFrom
                         error:(NSError * _Nullable * _Nullable)error;

- (NBEMatchType)isNumberMatch:(id _Nonnull)firstNumberIn second:(id _Nonnull)secondNumberIn error:(NSError * _Nullable * _Nullable)error;

- (int)getLengthOfGeographicalAreaCode:(NBPhoneNumber * _Nonnull)phoneNumber error:(NSError * _Nullable * _Nullable)error;
- (int)getLengthOfNationalDestinationCode:(NBPhoneNumber * _Nonnull)phoneNumber error:(NSError * _Nullable * _Nullable)error;

- (BOOL)maybeStripNationalPrefixAndCarrierCode:(NSString * _Nullable * _Nullable)number
                                      metadata:(NBPhoneMetaData * _Nonnull)metadata
                                   carrierCode:(NSString * _Nullable * _Nullable)carrierCode;
- (NBECountryCodeSource)maybeStripInternationalPrefixAndNormalize:(NSString * _Nullable * _Nullable)numberStr
                                                possibleIddPrefix:(NSString * _Nonnull)possibleIddPrefix;

- (NSNumber * _Nonnull)maybeExtractCountryCode:(NSString * _Nonnull)number
                                      metadata:(NBPhoneMetaData * _Nullable)defaultRegionMetadata
                                nationalNumber:(NSString * _Nullable * _Nullable)nationalNumber
                                  keepRawInput:(BOOL)keepRawInput
                                   phoneNumber:(NBPhoneNumber * _Nullable * _Nullable)phoneNumber
                                         error:(NSError * _Nullable * _Nullable)error;

- (NBPhoneNumber * _Nullable)parse:(NSString * _Nullable)numberToParse
                     defaultRegion:(NSString * _Nullable)defaultRegion
                             error:(NSError * _Nullable * _Nullable)error;
- (NBPhoneNumber * _Nullable)parseAndKeepRawInput:(NSString * _Nonnull)numberToParse
                                    defaultRegion:(NSString * _Nullable)defaultRegion
                                            error:(NSError * _Nullable * _Nullable)error;
- (NBPhoneNumber * _Nullable)parseWithPhoneCarrierRegion:(NSString * _Nullable)numberToParse
                                                   error:(NSError * _Nullable * _Nullable)error;

- (NSString * _Nullable)format:(NBPhoneNumber * _Nonnull)phoneNumber
                  numberFormat:(NBEPhoneNumberFormat)numberFormat
                         error:(NSError * _Nullable * _Nullable)error;
- (NSString * _Nullable)formatByPattern:(NBPhoneNumber * _Nonnull)number
                           numberFormat:(NBEPhoneNumberFormat)numberFormat
                     userDefinedFormats:(NSArray * _Nullable)userDefinedFormats
                                  error:(NSError * _Nullable * _Nullable)error;
- (NSString * _Nullable)formatNumberForMobileDialing:(NBPhoneNumber * _Nonnull)number
                                   regionCallingFrom:(NSString * _Nonnull)regionCallingFrom
                                      withFormatting:(BOOL)withFormatting
                                               error:(NSError * _Nullable * _Nullable)error;
- (NSString * _Nullable)formatOutOfCountryCallingNumber:(NBPhoneNumber * _Nonnull)number
                                      regionCallingFrom:(NSString * _Nonnull)regionCallingFrom
                                                  error:(NSError * _Nullable * _Nullable)error;
- (NSString * _Nullable)formatOutOfCountryKeepingAlphaChars:(NBPhoneNumber * _Nonnull)number
                                          regionCallingFrom:(NSString * _Nonnull)regionCallingFrom
                                                      error:(NSError * _Nullable * _Nullable)error;
- (NSString * _Nullable)formatNationalNumberWithCarrierCode:(NBPhoneNumber * _Nonnull)number
                                                carrierCode:(NSString * _Nullable)carrierCode
                                                      error:(NSError * _Nullable * _Nullable)error;
- (NSString * _Nullable)formatInOriginalFormat:(NBPhoneNumber * _Nonnull)number
                             regionCallingFrom:(NSString * _Nonnull)regionCallingFrom
                                         error:(NSError * _Nullable * _Nullable)error;
- (NSString * _Nullable)formatNationalNumberWithPreferredCarrierCode:(NBPhoneNumber * _Nonnull)number
                                       fallbackCarrierCode:(NSString * _Nonnull)fallbackCarrierCode
                                                     error:(NSError * _Nullable * _Nullable)error;
- (BOOL)formattingRuleHasFirstGroupOnly:(NSString * _Nullable)nationalPrefixFormattingRule;

/**
 * Returns the mobile token for the provided country calling code if it has one, otherwise
 * returns an empty string. A mobile token is a number inserted before the area code when dialing
 * a mobile number from that country from abroad.
 *
 * @param countryCallingCode  the country calling code for which we want the mobile token.
 * @return  the mobile token, as a string, for the given country calling code.
 */
- (NSString * _Nonnull)getCountryMobileTokenFromCountryCode:(NSInteger)countryCallingCode;

@end

