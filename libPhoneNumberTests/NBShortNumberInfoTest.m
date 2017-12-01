//
//  NBShortNumberInfoTest.m
//  libPhoneNumber
//
//  Created by Paween Itthipalkul on 11/29/17.
//  Copyright © 2017 Google LLC. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "NBMetadataHelper.h"
#import "NBPhoneMetaData.h"
#import "NBPhoneNumber.h"
#import "NBPhoneNumberDesc.h"
#import "NBPhoneNumberUtil+ShortNumber.h"
#import "NBPhoneNumberUtil+ShortNumberTest.h"

#if SHORT_NUMBER_SUPPORT

@interface NBShortNumberInfoTest: XCTestCase
@end

@implementation NBShortNumberInfoTest

- (void)testMetadataParsing_US {
  NBMetadataHelper *metadataHelper = [[NBMetadataHelper alloc] init];

  NBPhoneMetaData *metadata = [metadataHelper shortNumberMetadataForRegion:@"US"];
  XCTAssertNotNil(metadata.shortCode);
  XCTAssertNotNil(metadata.standardRate);
  XCTAssertNotNil(metadata.carrierSpecific);
  XCTAssertNotNil(metadata.smsServices);
}

- (void)testIsPossibleShortNumber {
  NBPhoneNumberUtil *util = [[NBPhoneNumberUtil alloc] init];

  NBPhoneNumber *possibleNumber = [[NBPhoneNumber alloc] init];
  possibleNumber.countryCode = @33;
  possibleNumber.nationalNumber = @123456;
  XCTAssertTrue([util isPossibleShortNumber:possibleNumber]);

  NBPhoneNumber *impossibleNumber = [[NBPhoneNumber alloc] init];
  impossibleNumber.countryCode = @33;
  impossibleNumber.nationalNumber = @9;
  XCTAssertFalse([util isPossibleShortNumber:impossibleNumber]);

  // Note that GB and GG share the country calling code 44, and that this number is possible but
  // not valid.
  NBPhoneNumber *possibleButInvalid = [[NBPhoneNumber alloc] init];
  possibleButInvalid.countryCode = @44;
  possibleButInvalid.nationalNumber = @11001;
  XCTAssertTrue([util isPossibleShortNumber:possibleButInvalid]);
}

- (void)testIsValidShortNumber {
  NBPhoneNumberUtil *util = [[NBPhoneNumberUtil alloc] init];

  NBPhoneNumber *valid = [[NBPhoneNumber alloc] init];
  valid.countryCode = @33;
  valid.nationalNumber = @1010;
  XCTAssertTrue([util isValidShortNumber:valid]);

  NBPhoneNumber *validWithRegion = [util parse:@"1010" defaultRegion:@"FR" error:nil];
  XCTAssertNotNil(validWithRegion);
  XCTAssertTrue([util isValidShortNumber:validWithRegion forRegion:@"FR"]);

  NBPhoneNumber *invalid = [[NBPhoneNumber alloc] init];
  invalid.countryCode = @33;
  invalid.nationalNumber = @123456;
  XCTAssertFalse([util isValidShortNumber:invalid]);

  NBPhoneNumber *invalidWithRegion = [util parse:@"123456" defaultRegion:@"FR" error:nil];
  XCTAssertNotNil(invalidWithRegion);
  XCTAssertFalse([util isValidShortNumber:invalidWithRegion forRegion:@"FR"]);

  // Note that GB and GG share the country calling code 44.
  NBPhoneNumber *valid2 = [[NBPhoneNumber alloc] init];
  valid2.countryCode = @44;
  valid2.nationalNumber = @18001;
  XCTAssertTrue([util isValidShortNumber:valid2]);
}

- (void)testIsCarrierSpecific {
  NBPhoneNumberUtil *util = [[NBPhoneNumberUtil alloc] init];

  NBPhoneNumber *carrierSpecificNumber = [[NBPhoneNumber alloc] init];
  carrierSpecificNumber.countryCode = @1;
  carrierSpecificNumber.nationalNumber = @33669;
  XCTAssertTrue([util isPhoneNumberCarrierSpecific:carrierSpecificNumber]);
  // TODO(paween): Fix this -- should be 33669
  XCTAssertTrue([util isPhoneNumberCarrierSpecific:[util parse:@"33669"
                                                 defaultRegion:@"US"
                                                         error:nil] forRegion:@"US"]);

  NBPhoneNumber *notCarrierSpecific = [[NBPhoneNumber alloc] init];
  notCarrierSpecific.countryCode = @1;
  notCarrierSpecific.nationalNumber = @911;
  XCTAssertFalse([util isPhoneNumberCarrierSpecific:notCarrierSpecific]);
  XCTAssertFalse([util isPhoneNumberCarrierSpecific:[util parse:@"911"
                                                  defaultRegion:@"US"
                                                          error:nil] forRegion:@"US"]);

  NBPhoneNumber *carrierSpecificForSomeRegion = [[NBPhoneNumber alloc] init];
  carrierSpecificForSomeRegion.countryCode = @1;
  carrierSpecificForSomeRegion.nationalNumber = @211;
  XCTAssertTrue([util isPhoneNumberCarrierSpecific:carrierSpecificForSomeRegion]);
  XCTAssertTrue([util isPhoneNumberCarrierSpecific:carrierSpecificForSomeRegion forRegion:@"US"]);
  XCTAssertFalse([util isPhoneNumberCarrierSpecific:carrierSpecificForSomeRegion forRegion:@"BB"]);
}

- (void)testExpectedCost {
  NBPhoneNumberUtil *util = [[NBPhoneNumberUtil alloc] init];

  // Premium rate.
  NSString *premiumRateSample = [util exampleShortNumberForCost:NBEShortNumberCostPremiumRate
                                                     regionCode:@"FR"];
  XCTAssertEqual(NBEShortNumberCostPremiumRate,
      [util expectedCostOfPhoneNumber:[util parse:premiumRateSample defaultRegion:@"FR" error:nil]
                            forRegion:@"FR"]);

  NBPhoneNumber *premiumRateNumber = [[NBPhoneNumber alloc] init];
  premiumRateNumber.countryCode = @33;
  premiumRateNumber.nationalNumber = @([premiumRateSample integerValue]);
  XCTAssertEqual(NBEShortNumberCostPremiumRate,
      [util expectedCostOfPhoneNumber:premiumRateNumber forRegion:@"FR"]);

  // Standard rate.
  NSString *standardRateSample = [util exampleShortNumberForCost:NBEShortNumberCostStandardRate
                                                      regionCode:@"FR"];
  XCTAssertEqual(NBEShortNumberCostStandardRate,
      [util expectedCostOfPhoneNumber:[util parse:standardRateSample defaultRegion:@"FR" error:nil]
                            forRegion:@"FR"]);

  NBPhoneNumber *standardRateNumber = [[NBPhoneNumber alloc] init];
  standardRateNumber.countryCode = @33;
  standardRateNumber.nationalNumber = @([standardRateSample integerValue]);
  XCTAssertEqual(NBEShortNumberCostStandardRate, [util expectedCostOfPhoneNumber:standardRateNumber
                                                                       forRegion:@"FR"]);

  // Toll free.
  NSString *tollFreeSample = [util exampleShortNumberForCost:NBEShortNumberCostTollFree
                                                  regionCode:@"FR"];
  XCTAssertEqual(NBEShortNumberCostTollFree,
      [util expectedCostOfPhoneNumber:[util parse:tollFreeSample defaultRegion:@"FR" error:nil]
                            forRegion:@"FR"]);

  NBPhoneNumber *tollFreeNumber = [[NBPhoneNumber alloc] init];
  tollFreeNumber.countryCode = @33;
  tollFreeNumber.nationalNumber = @([tollFreeSample integerValue]);
  XCTAssertEqual(NBEShortNumberCostTollFree, [util expectedCostOfPhoneNumber:tollFreeNumber
                                                                   forRegion:@"FR"]);

  // Unknown cost.
  XCTAssertEqual(NBEShortNumberCostUnknown,
      [util expectedCostOfPhoneNumber:[util parse:@"12345" defaultRegion:@"FR" error:nil]
                            forRegion:@"FR"]);
  NBPhoneNumber *unknownCostNumber = [[NBPhoneNumber alloc] init];
  unknownCostNumber.countryCode = @33;
  unknownCostNumber.nationalNumber = @12345;
  XCTAssertEqual(NBEShortNumberCostUnknown, [util expectedCostOfPhoneNumber:unknownCostNumber
                                                                  forRegion:@"FR"]);

  // Test that an invalid number may nevertheless have a cost other than UNKNOWN_COST.
  NBPhoneNumber *invalidShortNumber = [util parse:@"116123" defaultRegion:@"FR" error:nil];
  XCTAssertFalse([util isValidShortNumber:invalidShortNumber forRegion:@"FR"]);
  XCTAssertEqual(NBEShortNumberCostTollFree, [util expectedCostOfPhoneNumber:invalidShortNumber
                                                                   forRegion:@"FR"]);

  NBPhoneNumber *invalidShortNumber2 = [[NBPhoneNumber alloc] init];
  invalidShortNumber2.countryCode = @33;
  invalidShortNumber2.nationalNumber = @116123;
  XCTAssertFalse([util isValidShortNumber:invalidShortNumber2 forRegion:@"FR"]);
  XCTAssertEqual(NBEShortNumberCostTollFree, [util expectedCostOfPhoneNumber:invalidShortNumber2
                                                                   forRegion:@"FR"]);

  // Test a nonexistent country code.
  NBPhoneNumber *usNumber = [util parse:@"911" defaultRegion:@"US" error:nil];
  XCTAssertEqual(NBEShortNumberCostUnknown, [util expectedCostOfPhoneNumber:usNumber
                                                                  forRegion:@"ZZ"]);
  NBPhoneNumber *unknownNumber2 = [[NBPhoneNumber alloc] init];
  unknownNumber2.countryCode = @123;
  unknownNumber2.nationalNumber = @911;
  XCTAssertEqual(NBEShortNumberCostUnknown, [util expectedCostOfPhoneNumber:unknownNumber2]);
}

- (void)testExpectedCostForSharedCountryCallingCode {
  NBPhoneNumberUtil *util = [[NBPhoneNumberUtil alloc] init];

  NSString *ambiguousPremiumRateString = @"1234";
  NBPhoneNumber *ambiguousPremiumRateNumber = [[NBPhoneNumber alloc] init];
  ambiguousPremiumRateNumber.countryCode = @61;
  ambiguousPremiumRateNumber.nationalNumber = @1234;

  NSString *ambiguousStandardRateString = @"1194";
  NBPhoneNumber *ambiguousStandardRateNumber = [[NBPhoneNumber alloc] init];
  ambiguousStandardRateNumber.countryCode = @61;
  ambiguousStandardRateNumber.nationalNumber = @1194;

  NSString *ambiguousTollFreeString = @"733";
  NBPhoneNumber *ambiguousTollFreeNumber = [[NBPhoneNumber alloc] init];
  ambiguousTollFreeNumber.countryCode = @61;
  ambiguousTollFreeNumber.nationalNumber = @733;

  XCTAssertTrue([util isValidShortNumber:ambiguousPremiumRateNumber]);
  XCTAssertTrue([util isValidShortNumber:ambiguousStandardRateNumber]);
  XCTAssertTrue([util isValidShortNumber:ambiguousTollFreeNumber]);

  XCTAssertTrue([util isValidShortNumber:[util parse:ambiguousPremiumRateString
                                       defaultRegion:@"AU"
                                               error:nil] forRegion:@"AU"]);
  XCTAssertEqual(NBEShortNumberCostPremiumRate,
      [util expectedCostOfPhoneNumber:[util parse:ambiguousPremiumRateString
                                    defaultRegion:@"AU"
                                            error:nil] forRegion:@"AU"]);
  XCTAssertFalse([util isValidShortNumber:[util parse:ambiguousPremiumRateString
                                        defaultRegion:@"CX"
                                                error:nil] forRegion:@"CX"]);
  XCTAssertEqual(NBEShortNumberCostUnknown,
      [util expectedCostOfPhoneNumber:[util parse:ambiguousPremiumRateString
                                    defaultRegion:@"CX"
                                            error:nil] forRegion:@"CX"]);
  // PREMIUM_RATE takes precedence over UNKNOWN_COST.
  XCTAssertEqual(NBEShortNumberCostPremiumRate,
      [util expectedCostOfPhoneNumber:ambiguousPremiumRateNumber]);

  XCTAssertTrue([util isValidShortNumber:[util parse:ambiguousStandardRateString
                                       defaultRegion:@"AU"
                                               error:nil] forRegion:@"AU"]);
  XCTAssertEqual(NBEShortNumberCostStandardRate,
      [util expectedCostOfPhoneNumber:[util parse:ambiguousStandardRateString
                                    defaultRegion:@"AU"
                                            error:nil] forRegion:@"AU"]);
  XCTAssertFalse([util isValidShortNumber:[util parse:ambiguousStandardRateString
                                        defaultRegion:@"CX"
                                                error:nil] forRegion:@"CX"]);
  XCTAssertEqual(NBEShortNumberCostUnknown,
      [util expectedCostOfPhoneNumber:[util parse:ambiguousStandardRateString
                                    defaultRegion:@"CX"
                                            error:nil] forRegion:@"CX"]);
  XCTAssertEqual(NBEShortNumberCostUnknown,
      [util expectedCostOfPhoneNumber:ambiguousStandardRateNumber]);

  XCTAssertTrue([util isValidShortNumber:[util parse:ambiguousTollFreeString
                                       defaultRegion:@"AU"
                                               error:nil] forRegion:@"AU"]);
  XCTAssertEqual(NBEShortNumberCostTollFree,
      [util expectedCostOfPhoneNumber:[util parse:ambiguousTollFreeString
                                    defaultRegion:@"AU"
                                            error:nil] forRegion:@"AU"]);
  XCTAssertFalse([util isValidShortNumber:[util parse:ambiguousTollFreeString
                                        defaultRegion:@"CX"
                                                error:nil] forRegion:@"CX"]);
  XCTAssertEqual(NBEShortNumberCostUnknown,
      [util expectedCostOfPhoneNumber:[util parse:ambiguousTollFreeString
                                    defaultRegion:@"CX"
                                            error:nil] forRegion:@"CX"]);
  XCTAssertEqual(NBEShortNumberCostUnknown,
      [util expectedCostOfPhoneNumber:ambiguousTollFreeNumber]);
}

- (void)testGetExampleShortNumber {
  NBPhoneNumberUtil *util = [[NBPhoneNumberUtil alloc] init];

  XCTAssertEqualObjects(@"8711", [util exampleShortNumberWithRegionCode:@"AM"]);
  XCTAssertEqualObjects(@"1010", [util exampleShortNumberWithRegionCode:@"FR"]);
  XCTAssertEqualObjects(@"", [util exampleShortNumberWithRegionCode:@"UN001"]);
}

- (void)testGetExampleShortNumberForCost {
  NBPhoneNumberUtil *util = [[NBPhoneNumberUtil alloc] init];

  XCTAssertEqualObjects(@"3010", [util exampleShortNumberForCost:NBEShortNumberCostTollFree
                                                      regionCode:@"FR"]);
  XCTAssertEqualObjects(@"1023", [util exampleShortNumberForCost:NBEShortNumberCostStandardRate
                                                      regionCode:@"FR"]);
  XCTAssertEqualObjects(@"42000", [util exampleShortNumberForCost:NBEShortNumberCostPremiumRate
                                                      regionCode:@"FR"]);
  XCTAssertEqualObjects(@"", [util exampleShortNumberForCost:NBEShortNumberCostUnknown
                                                      regionCode:@"FR"]);
}

- (void)testConnectsToEmergencyNumber_US {
  NBPhoneNumberUtil *util = [[NBPhoneNumberUtil alloc] init];

  XCTAssertTrue([util connectsToEmergencyNumberFromString:@"911" forRegion:@"US"]);
  XCTAssertTrue([util connectsToEmergencyNumberFromString:@"112" forRegion:@"US"]);
  XCTAssertFalse([util connectsToEmergencyNumberFromString:@"999" forRegion:@"US"]);
}

- (void)testConnectsToEmergencyNumberLongNumber_US {
  NBPhoneNumberUtil *util = [[NBPhoneNumberUtil alloc] init];

  XCTAssertTrue([util connectsToEmergencyNumberFromString:@"9116666666" forRegion:@"US"]);
  XCTAssertTrue([util connectsToEmergencyNumberFromString:@"1126666666" forRegion:@"US"]);
  XCTAssertFalse([util connectsToEmergencyNumberFromString:@"9996666666" forRegion:@"US"]);
}

- (void)testConnectsToEmergencyNumberWithFormatting_US {
  NBPhoneNumberUtil *util = [[NBPhoneNumberUtil alloc] init];

  XCTAssertTrue([util connectsToEmergencyNumberFromString:@"9-1-1" forRegion:@"US"]);
  XCTAssertTrue([util connectsToEmergencyNumberFromString:@"1-1-2" forRegion:@"US"]);
  XCTAssertFalse([util connectsToEmergencyNumberFromString:@"9-9-9" forRegion:@"US"]);
}

- (void)testConnectsToEmergencyNumberWithPlusSign_US {
  NBPhoneNumberUtil *util = [[NBPhoneNumberUtil alloc] init];

  XCTAssertFalse([util connectsToEmergencyNumberFromString:@"+911" forRegion:@"US"]);
  XCTAssertFalse([util connectsToEmergencyNumberFromString:@"\uFF0B911" forRegion:@"US"]);
  XCTAssertFalse([util connectsToEmergencyNumberFromString:@" +911" forRegion:@"US"]);
  XCTAssertFalse([util connectsToEmergencyNumberFromString:@"+112" forRegion:@"US"]);
  XCTAssertFalse([util connectsToEmergencyNumberFromString:@"+999" forRegion:@"US"]);
}

- (void)testConnectsToEmergencyNumber_BR {
  NBPhoneNumberUtil *util = [[NBPhoneNumberUtil alloc] init];

  XCTAssertTrue([util connectsToEmergencyNumberFromString:@"911" forRegion:@"BR"]);
  XCTAssertTrue([util connectsToEmergencyNumberFromString:@"190" forRegion:@"BR"]);
  XCTAssertFalse([util connectsToEmergencyNumberFromString:@"999" forRegion:@"BR"]);
}

- (void)testConnectsToEmergencyNumberLongNumber_BR {
  NBPhoneNumberUtil *util = [[NBPhoneNumberUtil alloc] init];

  // Brazilian emergency numbers don't work when additional digits are appended.
  XCTAssertFalse([util connectsToEmergencyNumberFromString:@"9111" forRegion:@"BR"]);
  XCTAssertFalse([util connectsToEmergencyNumberFromString:@"1900" forRegion:@"BR"]);
  XCTAssertFalse([util connectsToEmergencyNumberFromString:@"9996" forRegion:@"BR"]);
}

- (void)testConnectsToEmergencyNumber_CL {
  NBPhoneNumberUtil *util = [[NBPhoneNumberUtil alloc] init];

  XCTAssertTrue([util connectsToEmergencyNumberFromString:@"131" forRegion:@"CL"]);
  XCTAssertTrue([util connectsToEmergencyNumberFromString:@"133" forRegion:@"CL"]);
}

- (void)testConnectsToEmergencyNumberLongNumber_CL {
  NBPhoneNumberUtil *util = [[NBPhoneNumberUtil alloc] init];

  // Chilean emergency numbers don't work when additional digits are appended.
  XCTAssertFalse([util connectsToEmergencyNumberFromString:@"1313" forRegion:@"CL"]);
  XCTAssertFalse([util connectsToEmergencyNumberFromString:@"1330" forRegion:@"CL"]);
}

- (void)testConnectsToEmergencyNumber_AO {
  NBPhoneNumberUtil *util = [[NBPhoneNumberUtil alloc] init];

  // Angola doesn't have any metadata for emergency numbers.
  XCTAssertFalse([util connectsToEmergencyNumberFromString:@"911" forRegion:@"AO"]);
  XCTAssertFalse([util connectsToEmergencyNumberFromString:@"222123456" forRegion:@"AO"]);
  XCTAssertFalse([util connectsToEmergencyNumberFromString:@"923123456" forRegion:@"AO"]);
}

- (void)testConnectsToEmergencyNumber_ZW {
  NBPhoneNumberUtil *util = [[NBPhoneNumberUtil alloc] init];

  // Zimbabwe doesn't have any metadata.
  XCTAssertFalse([util connectsToEmergencyNumberFromString:@"911" forRegion:@"ZW"]);
  XCTAssertFalse([util connectsToEmergencyNumberFromString:@"01312345" forRegion:@"ZW"]);
  XCTAssertFalse([util connectsToEmergencyNumberFromString:@"0711234567" forRegion:@"ZW"]);
}

- (void)testIsEmergencyNumber_US {
  NBPhoneNumberUtil *util = [[NBPhoneNumberUtil alloc] init];

  XCTAssertTrue([util isEmergencyNumber:@"911" forRegion:@"US"]);
  XCTAssertTrue([util isEmergencyNumber:@"112" forRegion:@"US"]);
  XCTAssertFalse([util isEmergencyNumber:@"999" forRegion:@"US"]);
}

- (void)testIsEmergencyNumberLongNumber_US {
  NBPhoneNumberUtil *util = [[NBPhoneNumberUtil alloc] init];

  XCTAssertFalse([util isEmergencyNumber:@"9116666666" forRegion:@"US"]);
  XCTAssertFalse([util isEmergencyNumber:@"1126666666" forRegion:@"US"]);
  XCTAssertFalse([util isEmergencyNumber:@"9996666666" forRegion:@"US"]);
}

- (void)testIsEmergencyNumberWithFormatting_US {
  NBPhoneNumberUtil *util = [[NBPhoneNumberUtil alloc] init];

  XCTAssertTrue([util isEmergencyNumber:@"9-1-1" forRegion:@"US"]);
  XCTAssertTrue([util isEmergencyNumber:@"*911" forRegion:@"US"]);
  XCTAssertTrue([util isEmergencyNumber:@"1-1-2" forRegion:@"US"]);
  XCTAssertTrue([util isEmergencyNumber:@"*112" forRegion:@"US"]);
  XCTAssertFalse([util isEmergencyNumber:@"9-9-9" forRegion:@"US"]);
  XCTAssertFalse([util isEmergencyNumber:@"*999" forRegion:@"US"]);
}

- (void)testIsEmergencyNumberWithPlusSign_US {
  NBPhoneNumberUtil *util = [[NBPhoneNumberUtil alloc] init];

  XCTAssertFalse([util isEmergencyNumber:@"+911" forRegion:@"US"]);
  XCTAssertFalse([util isEmergencyNumber:@"\uFF0B911" forRegion:@"US"]);
  XCTAssertFalse([util isEmergencyNumber:@" +911" forRegion:@"US"]);
  XCTAssertFalse([util isEmergencyNumber:@"+112" forRegion:@"US"]);
  XCTAssertFalse([util isEmergencyNumber:@"+999" forRegion:@"US"]);
}

- (void)testIsEmergencyNumber_BR {
  NBPhoneNumberUtil *util = [[NBPhoneNumberUtil alloc] init];

  XCTAssertTrue([util connectsToEmergencyNumberFromString:@"911" forRegion:@"BR"]);
  XCTAssertTrue([util connectsToEmergencyNumberFromString:@"190" forRegion:@"BR"]);
  XCTAssertFalse([util connectsToEmergencyNumberFromString:@"999" forRegion:@"BR"]);
}

- (void)testIsEmergencyNumberLongNumber_BR {
  NBPhoneNumberUtil *util = [[NBPhoneNumberUtil alloc] init];

  // Brazilian emergency numbers don't work when additional digits are appended.
  XCTAssertFalse([util connectsToEmergencyNumberFromString:@"9111" forRegion:@"BR"]);
  XCTAssertFalse([util connectsToEmergencyNumberFromString:@"1900" forRegion:@"BR"]);
  XCTAssertFalse([util connectsToEmergencyNumberFromString:@"9996" forRegion:@"BR"]);
}

- (void)testIsEmergencyNumber_AO {
  NBPhoneNumberUtil *util = [[NBPhoneNumberUtil alloc] init];

  // Angola doesn't have any metadata for emergency numbers.
  XCTAssertFalse([util connectsToEmergencyNumberFromString:@"911" forRegion:@"AO"]);
  XCTAssertFalse([util connectsToEmergencyNumberFromString:@"222123456" forRegion:@"AO"]);
  XCTAssertFalse([util connectsToEmergencyNumberFromString:@"923123456" forRegion:@"AO"]);
}

- (void)testIsEmergencyNumber_ZW {
  NBPhoneNumberUtil *util = [[NBPhoneNumberUtil alloc] init];

  // Zimbabwe doesn't have any metadata.
  XCTAssertFalse([util connectsToEmergencyNumberFromString:@"911" forRegion:@"ZW"]);
  XCTAssertFalse([util connectsToEmergencyNumberFromString:@"01312345" forRegion:@"ZW"]);
  XCTAssertFalse([util connectsToEmergencyNumberFromString:@"0711234567" forRegion:@"ZW"]);
}

- (void)testEmergencyNumberForSharedCountryCallingCode {
  NBPhoneNumberUtil *util = [[NBPhoneNumberUtil alloc] init];

  // Test the emergency number 112, which is valid in both Australia and the Christmas Islands.
  NBPhoneNumber *auEmergencyNumber = [util parse:@"112" defaultRegion:@"AU" error:nil];
  XCTAssertTrue([util isEmergencyNumber:@"112" forRegion:@"AU"]);
  XCTAssertTrue([util isValidShortNumber:auEmergencyNumber forRegion:@"AU"]);
  XCTAssertEqual(NBEShortNumberCostTollFree,
      [util expectedCostOfPhoneNumber:auEmergencyNumber forRegion:@"AU"]);

  XCTAssertTrue([util isEmergencyNumber:@"112" forRegion:@"CX"]);
  XCTAssertTrue([util isValidShortNumber:auEmergencyNumber forRegion:@"CX"]);
  XCTAssertEqual(NBEShortNumberCostTollFree,
      [util expectedCostOfPhoneNumber:auEmergencyNumber forRegion:@"CX"]);

  NBPhoneNumber *sharedEmergencyNumber = [[NBPhoneNumber alloc] init];
  sharedEmergencyNumber.countryCode = @61;
  sharedEmergencyNumber.nationalNumber = @112;
  XCTAssertTrue([util isValidShortNumber:sharedEmergencyNumber]);
  XCTAssertEqual(NBEShortNumberCostTollFree,
      [util expectedCostOfPhoneNumber:sharedEmergencyNumber]);
}

- (void)testOverlappingNANPANumber {
  // 211 is an emergency number in Barbados, while it is a toll-free information line in Canada
  // and the USA.
  NBPhoneNumberUtil *util = [[NBPhoneNumberUtil alloc] init];

  NBPhoneNumber *bb211 = [util parse:@"211" defaultRegion:@"BB" error:nil];
  NBPhoneNumber *us211 = [util parse:@"211" defaultRegion:@"US" error:nil];
  NBPhoneNumber *ca211 = [util parse:@"211" defaultRegion:@"CA" error:nil];

  XCTAssertTrue([util isEmergencyNumber:@"211" forRegion:@"BB"]);
  XCTAssertEqual(NBEShortNumberCostTollFree,
      [util expectedCostOfPhoneNumber:bb211 forRegion:@"BB"]);
  XCTAssertFalse([util isEmergencyNumber:@"211" forRegion:@"US"]);
  XCTAssertEqual(NBEShortNumberCostUnknown,
      [util expectedCostOfPhoneNumber:us211 forRegion:@"US"]);
  XCTAssertFalse([util isEmergencyNumber:@"211" forRegion:@"CA"]);
  XCTAssertEqual(NBEShortNumberCostTollFree,
      [util expectedCostOfPhoneNumber:ca211 forRegion:@"CA"]);
}

- (void)testCountryCallingCodeIsNotIgnored {
  NBPhoneNumberUtil *util = [[NBPhoneNumberUtil alloc] init];

  // +46 is the country calling code for Sweden (SE), and 40404 is a valid short number in the US.
  NBPhoneNumber *seNumber = [util parse:@"+4640404" defaultRegion:@"SE" error:nil];
  XCTAssertFalse([util isPossibleShortNumber:seNumber forRegion:@"US"]);
  XCTAssertFalse([util isValidShortNumber:seNumber forRegion:@"US"]);
  XCTAssertEqual(NBEShortNumberCostUnknown,
      [util expectedCostOfPhoneNumber:seNumber forRegion:@"US"]);
}

@end

#endif // SHORT_NUMBER_SUPPORT
