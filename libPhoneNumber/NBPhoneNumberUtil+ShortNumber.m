//
//  NBPhoneNumberUtil+ShortNumber.m
//  libPhoneNumberiOS
//
//  Created by Paween Itthipalkul on 11/29/17.
//  Copyright © 2017 Google LLC. All rights reserved.
//

#import "NBPhoneNumberUtil+ShortNumber.h"

#import <Foundation/Foundation.h>

#import "NBMetadataHelper.h"
#import "NBPhoneMetaData.h"
#import "NBPhoneNumber.h"
#import "NBPhoneNumberDesc.h"
#import "NBRegExMatcher.h"
#import "NBRegularExpressionCache.h"

#if SHORT_NUMBER_SUPPORT

static NSString * const PLUS_CHARS_PATTERN = @"[+\uFF0B]+";

@interface NBPhoneNumberUtil()

@property(nonatomic, strong, readonly) NBMetadataHelper *helper;
@property(nonatomic, strong, readonly) NBRegExMatcher *matcher;

@property (nonatomic) NSDictionary<NSNumber *, NSArray<NSString *> *> *countryToRegionCodeMap;

@end

@implementation NBPhoneNumberUtil (ShortNumber)

- (BOOL)isPossibleShortNumber:(NBPhoneNumber *)phoneNumber forRegion:(NSString *)regionDialingFrom {
  if (![self doesPhoneNumber:phoneNumber matchesRegion:regionDialingFrom]) {
    return NO;
  }

  NBPhoneMetaData *metadata = [self.helper shortNumberMetadataForRegion:regionDialingFrom];
  if (metadata == nil) {
    return NO;
  }

  NSUInteger length = [[self getNationalSignificantNumber:phoneNumber] length];
  return [metadata.generalDesc.possibleLength containsObject:@(length)];
}

- (BOOL)isPossibleShortNumber:(NBPhoneNumber *)phoneNumber {
  NSArray<NSString *> *regionCodes = [self getRegionCodesForCountryCode:phoneNumber.countryCode];
  NSUInteger shortNumberLength = [[self getNationalSignificantNumber:phoneNumber] length];
  for (NSString *region in regionCodes) {
    NBPhoneMetaData *metadata = [self.helper shortNumberMetadataForRegion:region];
    if (metadata == nil) {
      continue;
    }

    if ([metadata.generalDesc.possibleLength containsObject:@(shortNumberLength)]) {
      return YES;
    }
  }

  return NO;
}

- (BOOL)isValidShortNumber:(NBPhoneNumber *)phoneNumber
                 forRegion:(NSString *)regionDialingFrom {
  if (![self doesPhoneNumber:phoneNumber matchesRegion:regionDialingFrom]) {
    return NO;
  }

  NBPhoneMetaData *metadata = [self.helper shortNumberMetadataForRegion:regionDialingFrom];
  if (metadata == nil) {
    return NO;
  }

  NSString *shortNumber = [self getNationalSignificantNumber:phoneNumber];
  NBPhoneNumberDesc *generalDesc = metadata.generalDesc;
  if (![self matchesPossibleNumber:shortNumber andNationalNumber:generalDesc]) {
    return NO;
  }

  NBPhoneNumberDesc *shortNumberDesc = metadata.shortCode;
  return [self matchesPossibleNumber:shortNumber andNationalNumber:shortNumberDesc];
}

- (BOOL)isValidShortNumber:(NBPhoneNumber *)phoneNumber {
  NSArray<NSString *> *regionCodes = [self getRegionCodesForCountryCode:phoneNumber.countryCode];
  NSString *regionCode = [self regionCodeForShortNumber:phoneNumber fromRegionList:regionCodes];
  if (regionCodes.count > 1 && regionCode != nil) {
    // If a matching region had been found for the phone number from among two or more regions,
    // then we have already implicitly verified its validity for that region.
    return YES;
  }

  return [self isValidShortNumber:phoneNumber forRegion:regionCode];
}

- (NBEShortNumberCost)expectedCostOfPhoneNumber:(NBPhoneNumber *)phoneNumber
                                      forRegion:(NSString *)regionDialingFrom {
  if (![self doesRegionDialingFrom:regionDialingFrom matchesPhoneNumber:phoneNumber]) {
    return NBEShortNumberCostUnknown;
  }

  NBPhoneMetaData *metadata = [self.helper shortNumberMetadataForRegion:regionDialingFrom];
  if (metadata == nil) {
    return NBEShortNumberCostUnknown;
  }

  NSString *shortNumber = [self getNationalSignificantNumber:phoneNumber];

  // The possible lengths are not present for a particular sub-type if they match the general
  // description; for this reason, we check the possible lengths against the general description
  // first to allow an early exit if possible.
  if (![metadata.generalDesc.possibleLength containsObject:@(shortNumber.length)]) {
    return NBEShortNumberCostUnknown;
  }

  // The cost categories are tested in order of decreasing expense, since if for some reason the
  // patterns overlap the most expensive matching cost category should be returned.
  if ([self matchesPossibleNumber:shortNumber andNationalNumber:metadata.premiumRate]) {
    return NBEShortNumberCostPremiumRate;
  } else if ([self matchesPossibleNumber:shortNumber andNationalNumber:metadata.standardRate]) {
    return NBEShortNumberCostStandardRate;
  } else if ([self matchesPossibleNumber:shortNumber andNationalNumber:metadata.tollFree]) {
    return NBEShortNumberCostTollFree;
  }

  if ([self isEmergencyNumber:shortNumber forRegion:regionDialingFrom]) {
    // Emergency numbers are implicitly toll-free.
    return NBEShortNumberCostTollFree;
  }

  return NBEShortNumberCostUnknown;
}

- (NBEShortNumberCost)expectedCostOfPhoneNumber:(NBPhoneNumber *)phoneNumber {
  NSArray<NSString *> *regionCodes = [self getRegionCodesForCountryCode:phoneNumber.countryCode];
  if (regionCodes.count == 0) {
    return NBEShortNumberCostUnknown;
  }
  if (regionCodes.count == 1) {
    return [self expectedCostOfPhoneNumber:phoneNumber forRegion:regionCodes[0]];
  }

  NBEShortNumberCost cost = NBEShortNumberCostTollFree;
  for (NSString *regionCode in regionCodes) {
    NBEShortNumberCost costForRegion = [self expectedCostOfPhoneNumber:phoneNumber
                                                             forRegion:regionCode];
    switch (costForRegion) {
      case NBEShortNumberCostPremiumRate:
        return NBEShortNumberCostPremiumRate;
      case NBEShortNumberCostUnknown:
        cost = NBEShortNumberCostUnknown;
        break;
      case NBEShortNumberCostStandardRate:
        if (cost != NBEShortNumberCostUnknown) {
          cost = NBEShortNumberCostStandardRate;
        }
        break;
      case NBEShortNumberCostTollFree:
        // Do nothing.
        break;
    }
  }

  return cost;
}

- (BOOL)isPhoneNumberCarrierSpecific:(NBPhoneNumber *)phoneNumber {
  NSArray<NSString *> *regionCodes = [self getRegionCodesForCountryCode:phoneNumber.countryCode];
  NSString *regionCode = [self regionCodeForShortNumber:phoneNumber fromRegionList:regionCodes];
  NSString *nationalNumber = [self getNationalSignificantNumber:phoneNumber];
  NBPhoneMetaData *metadata = [self.helper shortNumberMetadataForRegion:regionCode];
  return (metadata != nil &&
      ([self matchesPossibleNumber:nationalNumber andNationalNumber:metadata.carrierSpecific]));
}

- (BOOL)isPhoneNumberCarrierSpecific:(NBPhoneNumber *)phoneNumber forRegion:(NSString *)regionCode {
  if (![self doesRegionDialingFrom:regionCode matchesPhoneNumber:phoneNumber]) {
    return NO;
  }

  NSString *nationalNumber = [self getNationalSignificantNumber:phoneNumber];
  NBPhoneMetaData *metadata = [self.helper shortNumberMetadataForRegion:regionCode];
  return (metadata != nil
      && ([self matchesPossibleNumber:nationalNumber andNationalNumber:metadata.carrierSpecific]));
}

- (BOOL)isPhoneNumberSMSService:(NBPhoneNumber *)phoneNumber forRegion:(NSString *)regionCode {
  if (![self doesRegionDialingFrom:regionCode matchesPhoneNumber:phoneNumber]) {
    return NO;
  }

  NSString *nationalNumber = [self getNationalSignificantNumber:phoneNumber];
  NBPhoneMetaData *metadata = [self.helper shortNumberMetadataForRegion:regionCode];
  return (metadata != nil
      && ([self matchesPossibleNumber:nationalNumber andNationalNumber:metadata.smsServices]));
}

- (BOOL)connectsToEmergencyNumberFromString:(NSString *)number forRegion:(NSString *)regionCode {
  return [self matchesEmergencyNumberHelper:number regionCode:regionCode allowsPrefixMatch:YES];
}

- (BOOL)isEmergencyNumber:(NSString *)number forRegion:(NSString *)regionCode {
  return [self matchesEmergencyNumberHelper:number regionCode:regionCode allowsPrefixMatch:NO];
}

// MARK: - Private

// In these countries, if extra digits are added to an emergency number, it no longer connects
// to the emergency service.
+ (NSSet<NSString *> *)regionsWhereEmergencyNumbersMustBeExact {
  static NSSet<NSString *> *regions;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    regions = [NSSet setWithObjects:@"BR", @"CL", @"NI", nil];
  });
  return regions;
}

/**
 * Helper method to check that the country calling code of the number matches the region it's
 * being dialed from.
 */
- (BOOL)doesPhoneNumber:(NBPhoneNumber *)phoneNumber matchesRegion:(NSString *)regionCode {
  NSArray<NSString *> *regionCodes = [self getRegionCodesForCountryCode:phoneNumber.countryCode];
  return [regionCodes containsObject:regionCode];
}

/**
 * Gets the national significant number of the a phone number. Note a national significant number
 * doesn't contain a national prefix or any formatting.
 * <p>
 * This is a temporary duplicate of the {@code getNationalSignificantNumber} method from
 * {@code PhoneNumberUtil}. Ultimately a canonical static version should exist in a separate
 * utility class (to prevent {@code ShortNumberInfo} needing to depend on PhoneNumberUtil).
 *
 * @param number  the phone number for which the national significant number is needed
 * @return  the national significant number of the PhoneNumber object passed in
 */
+ (NSString *)nationalSignificantNumberFromPhoneNumber:(NBPhoneNumber *)phoneNumber {
  // If leading zero(s) have been set, we prefix this now. Note this is not a national prefix.
  NSMutableString *nationalNumber = [[NSMutableString alloc] init];
  if (phoneNumber.italianLeadingZero) {
    [nationalNumber appendFormat:@"%*d", [phoneNumber.numberOfLeadingZeros intValue], 0];
  }
  [nationalNumber appendString:[phoneNumber.nationalNumber stringValue]];

  return [nationalNumber copy];
}

- (BOOL)matchesPossibleNumber:(NSString *)number andNationalNumber:(NBPhoneNumberDesc *)numberDesc {
  if (numberDesc.possibleLength.count > 0
    && ![numberDesc.possibleLength containsObject:@(number.length)]) {
    return NO;
  }

  return [self.matcher matchNationalNumber:number phoneNumberDesc:numberDesc allowsPrefixMatch:NO];
}

// Helper method to get the region code for a given phone number, from a list of possible region
// codes. If the list contains more than one region, the first region for which the number is
// valid is returned.
- (NSString *)regionCodeForShortNumber:(NBPhoneNumber *)number
                        fromRegionList:(NSArray<NSString *> *)regionCodes {
  if (regionCodes.count == 0) {
    return nil;
  } else if (regionCodes.count == 1) {
    return regionCodes[0];
  }

  NSString *nationalNumber = [self getNationalSignificantNumber:number];
  for (NSString *regionCode in regionCodes) {
    NBPhoneMetaData *metadata = [self.helper shortNumberMetadataForRegion:regionCode];
    if (metadata != nil && [self matchesPossibleNumber:nationalNumber
                                     andNationalNumber:metadata.shortCode]) {
      // The number is valid for this region.
      return regionCode;
    }
  }

  return nil;
}

- (BOOL)doesRegionDialingFrom:(NSString *)regionCode
           matchesPhoneNumber:(NBPhoneNumber *)phoneNumber {
  NSArray<NSString *> *regionCodes = [self getRegionCodesForCountryCode:phoneNumber.countryCode];
  return [regionCodes containsObject:regionCode];
}

- (BOOL)matchesEmergencyNumberHelper:(NSString *)number regionCode:(NSString *)regionCode
                   allowsPrefixMatch:(BOOL)allowsPrefixMatch {
  NSString *possibleNumber = [self extractPossibleNumber:number];
  NSRegularExpression *regex =
      [[NBRegularExpressionCache sharedInstance] regularExpressionForPattern:PLUS_CHARS_PATTERN
                                                                       error:NULL];

  NSTextCheckingResult *result = [regex firstMatchInString:possibleNumber
                                                   options:kNilOptions
                                                     range:NSMakeRange(0, possibleNumber.length)];
  if (result != nil) {
    // Returns false if the number starts with a plus sign. We don't believe dialing the country
    // code before emergency numbers (e.g. +1911) works, but later, if that proves to work, we can
    // add additional logic here to handle it.
    return NO;
  }

  NBPhoneMetaData *metadata = [self.helper shortNumberMetadataForRegion:regionCode];
  if (metadata == nil || metadata.emergency == nil) {
    return NO;
  }

  NSString *normalizedNumber = [self normalizeDigitsOnly:possibleNumber];
  NSSet<NSString *> *exactRegions = [NBPhoneNumberUtil regionsWhereEmergencyNumbersMustBeExact];

  BOOL allowsPrefixMatchForRegion = allowsPrefixMatch && ![exactRegions containsObject:regionCode];

  return [self.matcher matchNationalNumber:normalizedNumber
                           phoneNumberDesc:metadata.emergency
                         allowsPrefixMatch:allowsPrefixMatchForRegion];
}

@end

#endif // SHORT_NUMBER_SUPPORT
