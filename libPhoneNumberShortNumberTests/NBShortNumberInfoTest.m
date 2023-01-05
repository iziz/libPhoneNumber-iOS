//
//  NBShortNumberInfoTest.m
//  libPhoneNumberShortNumber
//
//  Created by Paween Itthipalkul on 11/29/17.
//  Copyright © 2017 Google LLC. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "NBMetadataHelper.h"
#import "NBPhoneMetaData.h"
#import "NBPhoneNumber.h"
#import "NBPhoneNumberDesc.h"
#import "NBShortNumberUtil.h"

#import "NBShortNumberMetadataHelper.h"
#import "NBShortNumberTestHelper.h"
#import "NBTestingMetaData.h"

@interface NBShortNumberInfoTest : XCTestCase

@property(nonatomic, strong) NBShortNumberUtil *shortNumberUtil;
@property(nonatomic, strong) NBPhoneNumberUtil *phoneNumberUtil;
@property(nonatomic, strong) NBShortNumberTestHelper *testHelper;

@end

@implementation NBShortNumberInfoTest

- (void)setUp {
  [super setUp];
  if (self != nil) {
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];

    NSString *metadataPath = [bundle pathForResource:@"libPhoneNumberMetadataForTesting"
                                              ofType:nil];
    NSData *metadataData = [NSData dataWithContentsOfFile:metadataPath];
    NBMetadataHelper *helper =
        [[NBMetadataHelper alloc] initWithZippedData:metadataData
                                      expandedLength:kPhoneNumberMetaDataForTestingExpandedLength];
    _phoneNumberUtil = [[NBPhoneNumberUtil alloc] initWithMetadataHelper:helper];
    _testHelper = [[NBShortNumberTestHelper alloc] init];
    _shortNumberUtil =
        [[NBShortNumberUtil alloc] initWithMetadataHelper:[[NBShortNumberMetadataHelper alloc] init]
                                          phoneNumberUtil:_phoneNumberUtil];
  }
}

- (void)testMetadataParsing_US {
  NBShortNumberMetadataHelper *metadataHelper = [[NBShortNumberMetadataHelper alloc] init];

  NBPhoneMetaData *metadata = [metadataHelper shortNumberMetadataForRegion:@"US"];
  XCTAssertNotNil(metadata.shortCode);
  XCTAssertNotNil(metadata.standardRate);
  XCTAssertNotNil(metadata.carrierSpecific);
  XCTAssertNotNil(metadata.smsServices);
}

- (void)testIsPossibleShortNumber {
  NBPhoneNumber *possibleNumber = [[NBPhoneNumber alloc] init];
  possibleNumber.countryCode = @33;
  possibleNumber.nationalNumber = @123456;
  XCTAssertTrue([_shortNumberUtil isPossibleShortNumber:possibleNumber]);

  NBPhoneNumber *impossibleNumber = [[NBPhoneNumber alloc] init];
  impossibleNumber.countryCode = @33;
  impossibleNumber.nationalNumber = @9;
  XCTAssertFalse([_shortNumberUtil isPossibleShortNumber:impossibleNumber]);

  // Note that GB and GG share the country calling code 44, and that this number is possible but
  // not valid.
  NBPhoneNumber *possibleButInvalid = [[NBPhoneNumber alloc] init];
  possibleButInvalid.countryCode = @44;
  possibleButInvalid.nationalNumber = @11001;
  XCTAssertTrue([_shortNumberUtil isPossibleShortNumber:possibleButInvalid]);
}

- (void)testIsValidShortNumber {
  NBPhoneNumber *valid = [[NBPhoneNumber alloc] init];
  valid.countryCode = @33;
  valid.nationalNumber = @1010;
  XCTAssertTrue([_shortNumberUtil isValidShortNumber:valid]);

  NBPhoneNumber *validWithRegion = [_phoneNumberUtil parse:@"1010" defaultRegion:@"FR" error:nil];
  XCTAssertNotNil(validWithRegion);
  XCTAssertTrue([_shortNumberUtil isValidShortNumber:validWithRegion forRegion:@"FR"]);

  NBPhoneNumber *invalid = [[NBPhoneNumber alloc] init];
  invalid.countryCode = @33;
  invalid.nationalNumber = @123456;
  XCTAssertFalse([_shortNumberUtil isValidShortNumber:invalid]);

  NBPhoneNumber *invalidWithRegion = [_phoneNumberUtil parse:@"123456"
                                               defaultRegion:@"FR"
                                                       error:nil];
  XCTAssertNotNil(invalidWithRegion);
  XCTAssertFalse([_shortNumberUtil isValidShortNumber:invalidWithRegion forRegion:@"FR"]);

  // Note that GB and GG share the country calling code 44.
  NBPhoneNumber *valid2 = [[NBPhoneNumber alloc] init];
  valid2.countryCode = @44;
  valid2.nationalNumber = @18001;
  XCTAssertTrue([_shortNumberUtil isValidShortNumber:valid2]);
}

- (void)testIsCarrierSpecific {
  NBPhoneNumber *carrierSpecificNumber = [[NBPhoneNumber alloc] init];
  carrierSpecificNumber.countryCode = @1;
  carrierSpecificNumber.nationalNumber = @33669;
  XCTAssertTrue([_shortNumberUtil isPhoneNumberCarrierSpecific:carrierSpecificNumber]);
  XCTAssertTrue([_shortNumberUtil isPhoneNumberCarrierSpecific:[_phoneNumberUtil parse:@"33669"
                                                                         defaultRegion:@"US"
                                                                                 error:nil]
                                                     forRegion:@"US"]);

  NBPhoneNumber *notCarrierSpecific = [[NBPhoneNumber alloc] init];
  notCarrierSpecific.countryCode = @1;
  notCarrierSpecific.nationalNumber = @911;
  XCTAssertFalse([_shortNumberUtil isPhoneNumberCarrierSpecific:notCarrierSpecific]);
  XCTAssertFalse([_shortNumberUtil isPhoneNumberCarrierSpecific:[_phoneNumberUtil parse:@"911"
                                                                          defaultRegion:@"US"
                                                                                  error:nil]
                                                      forRegion:@"US"]);

  NBPhoneNumber *carrierSpecificForSomeRegion = [[NBPhoneNumber alloc] init];
  carrierSpecificForSomeRegion.countryCode = @1;
  carrierSpecificForSomeRegion.nationalNumber = @211;
  XCTAssertTrue([_shortNumberUtil isPhoneNumberCarrierSpecific:carrierSpecificForSomeRegion]);
  XCTAssertTrue([_shortNumberUtil isPhoneNumberCarrierSpecific:carrierSpecificForSomeRegion
                                                     forRegion:@"US"]);
  XCTAssertFalse([_shortNumberUtil isPhoneNumberCarrierSpecific:carrierSpecificForSomeRegion
                                                      forRegion:@"BB"]);
}

- (void)testExpectedCost {
  // Premium rate.
  NSString *premiumRateSample = [_testHelper exampleShortNumberForCost:NBEShortNumberCostPremiumRate
                                                            regionCode:@"FR"];
  XCTAssertEqual(
      NBEShortNumberCostPremiumRate,
      [_shortNumberUtil expectedCostOfPhoneNumber:[_phoneNumberUtil parse:premiumRateSample
                                                            defaultRegion:@"FR"
                                                                    error:nil]
                                        forRegion:@"FR"]);

  NBPhoneNumber *premiumRateNumber = [[NBPhoneNumber alloc] init];
  premiumRateNumber.countryCode = @33;
  premiumRateNumber.nationalNumber = @([premiumRateSample integerValue]);
  XCTAssertEqual(NBEShortNumberCostPremiumRate,
                 [_shortNumberUtil expectedCostOfPhoneNumber:premiumRateNumber forRegion:@"FR"]);

  // Standard rate.
  NSString *standardRateSample =
      [_testHelper exampleShortNumberForCost:NBEShortNumberCostStandardRate regionCode:@"FR"];
  XCTAssertEqual(
      NBEShortNumberCostStandardRate,
      [_shortNumberUtil expectedCostOfPhoneNumber:[_phoneNumberUtil parse:standardRateSample
                                                            defaultRegion:@"FR"
                                                                    error:nil]
                                        forRegion:@"FR"]);

  NBPhoneNumber *standardRateNumber = [[NBPhoneNumber alloc] init];
  standardRateNumber.countryCode = @33;
  standardRateNumber.nationalNumber = @([standardRateSample integerValue]);
  XCTAssertEqual(NBEShortNumberCostStandardRate,
                 [_shortNumberUtil expectedCostOfPhoneNumber:standardRateNumber forRegion:@"FR"]);

  // Toll free.
  NSString *tollFreeSample = [_testHelper exampleShortNumberForCost:NBEShortNumberCostTollFree
                                                         regionCode:@"FR"];
  XCTAssertEqual(NBEShortNumberCostTollFree,
                 [_shortNumberUtil expectedCostOfPhoneNumber:[_phoneNumberUtil parse:tollFreeSample
                                                                       defaultRegion:@"FR"
                                                                               error:nil]
                                                   forRegion:@"FR"]);

  NBPhoneNumber *tollFreeNumber = [[NBPhoneNumber alloc] init];
  tollFreeNumber.countryCode = @33;
  tollFreeNumber.nationalNumber = @([tollFreeSample integerValue]);
  XCTAssertEqual(NBEShortNumberCostTollFree,
                 [_shortNumberUtil expectedCostOfPhoneNumber:tollFreeNumber forRegion:@"FR"]);

  // Unknown cost.
  XCTAssertEqual(NBEShortNumberCostUnknown,
                 [_shortNumberUtil expectedCostOfPhoneNumber:[_phoneNumberUtil parse:@"12345"
                                                                       defaultRegion:@"FR"
                                                                               error:nil]
                                                   forRegion:@"FR"]);
  NBPhoneNumber *unknownCostNumber = [[NBPhoneNumber alloc] init];
  unknownCostNumber.countryCode = @33;
  unknownCostNumber.nationalNumber = @12345;
  XCTAssertEqual(NBEShortNumberCostUnknown,
                 [_shortNumberUtil expectedCostOfPhoneNumber:unknownCostNumber forRegion:@"FR"]);

  // Test that an invalid number may nevertheless have a cost other than UNKNOWN_COST.
  NBPhoneNumber *invalidShortNumber = [_phoneNumberUtil parse:@"116123"
                                                defaultRegion:@"FR"
                                                        error:nil];
  XCTAssertFalse([_shortNumberUtil isValidShortNumber:invalidShortNumber forRegion:@"FR"]);
  XCTAssertEqual(NBEShortNumberCostTollFree,
                 [_shortNumberUtil expectedCostOfPhoneNumber:invalidShortNumber forRegion:@"FR"]);

  NBPhoneNumber *invalidShortNumber2 = [[NBPhoneNumber alloc] init];
  invalidShortNumber2.countryCode = @33;
  invalidShortNumber2.nationalNumber = @116123;
  XCTAssertFalse([_shortNumberUtil isValidShortNumber:invalidShortNumber2 forRegion:@"FR"]);
  XCTAssertEqual(NBEShortNumberCostTollFree,
                 [_shortNumberUtil expectedCostOfPhoneNumber:invalidShortNumber2 forRegion:@"FR"]);

  // Test a nonexistent country code.
  NBPhoneNumber *usNumber = [_phoneNumberUtil parse:@"911" defaultRegion:@"US" error:nil];
  XCTAssertEqual(NBEShortNumberCostUnknown, [_shortNumberUtil expectedCostOfPhoneNumber:usNumber
                                                                              forRegion:@"ZZ"]);
  NBPhoneNumber *unknownNumber2 = [[NBPhoneNumber alloc] init];
  unknownNumber2.countryCode = @123;
  unknownNumber2.nationalNumber = @911;
  XCTAssertEqual(NBEShortNumberCostUnknown,
                 [_shortNumberUtil expectedCostOfPhoneNumber:unknownNumber2]);
}

- (void)testExpectedCostForSharedCountryCallingCode {
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

  XCTAssertTrue([_shortNumberUtil isValidShortNumber:ambiguousPremiumRateNumber]);
  XCTAssertTrue([_shortNumberUtil isValidShortNumber:ambiguousStandardRateNumber]);
  XCTAssertTrue([_shortNumberUtil isValidShortNumber:ambiguousTollFreeNumber]);

  XCTAssertTrue([_shortNumberUtil
      isValidShortNumber:[_phoneNumberUtil parse:ambiguousPremiumRateString
                                   defaultRegion:@"AU"
                                           error:nil]
               forRegion:@"AU"]);
  XCTAssertEqual(
      NBEShortNumberCostPremiumRate,
      [_shortNumberUtil expectedCostOfPhoneNumber:[_phoneNumberUtil parse:ambiguousPremiumRateString
                                                            defaultRegion:@"AU"
                                                                    error:nil]
                                        forRegion:@"AU"]);
  XCTAssertFalse([_shortNumberUtil
      isValidShortNumber:[_phoneNumberUtil parse:ambiguousPremiumRateString
                                   defaultRegion:@"CX"
                                           error:nil]
               forRegion:@"CX"]);
  XCTAssertEqual(
      NBEShortNumberCostUnknown,
      [_shortNumberUtil expectedCostOfPhoneNumber:[_phoneNumberUtil parse:ambiguousPremiumRateString
                                                            defaultRegion:@"CX"
                                                                    error:nil]
                                        forRegion:@"CX"]);
  // PREMIUM_RATE takes precedence over UNKNOWN_COST.
  XCTAssertEqual(NBEShortNumberCostPremiumRate,
                 [_shortNumberUtil expectedCostOfPhoneNumber:ambiguousPremiumRateNumber]);

  XCTAssertTrue([_shortNumberUtil
      isValidShortNumber:[_phoneNumberUtil parse:ambiguousStandardRateString
                                   defaultRegion:@"AU"
                                           error:nil]
               forRegion:@"AU"]);
  XCTAssertEqual(NBEShortNumberCostStandardRate,
                 [_shortNumberUtil
                     expectedCostOfPhoneNumber:[_phoneNumberUtil parse:ambiguousStandardRateString
                                                         defaultRegion:@"AU"
                                                                 error:nil]
                                     forRegion:@"AU"]);
  XCTAssertFalse([_shortNumberUtil
      isValidShortNumber:[_phoneNumberUtil parse:ambiguousStandardRateString
                                   defaultRegion:@"CX"
                                           error:nil]
               forRegion:@"CX"]);
  XCTAssertEqual(NBEShortNumberCostUnknown,
                 [_shortNumberUtil
                     expectedCostOfPhoneNumber:[_phoneNumberUtil parse:ambiguousStandardRateString
                                                         defaultRegion:@"CX"
                                                                 error:nil]
                                     forRegion:@"CX"]);
  XCTAssertEqual(NBEShortNumberCostUnknown,
                 [_shortNumberUtil expectedCostOfPhoneNumber:ambiguousStandardRateNumber]);

  XCTAssertTrue([_shortNumberUtil isValidShortNumber:[_phoneNumberUtil parse:ambiguousTollFreeString
                                                               defaultRegion:@"AU"
                                                                       error:nil]
                                           forRegion:@"AU"]);
  XCTAssertEqual(
      NBEShortNumberCostTollFree,
      [_shortNumberUtil expectedCostOfPhoneNumber:[_phoneNumberUtil parse:ambiguousTollFreeString
                                                            defaultRegion:@"AU"
                                                                    error:nil]
                                        forRegion:@"AU"]);
  XCTAssertFalse([_shortNumberUtil
      isValidShortNumber:[_phoneNumberUtil parse:ambiguousTollFreeString
                                   defaultRegion:@"CX"
                                           error:nil]
               forRegion:@"CX"]);
  XCTAssertEqual(
      NBEShortNumberCostUnknown,
      [_shortNumberUtil expectedCostOfPhoneNumber:[_phoneNumberUtil parse:ambiguousTollFreeString
                                                            defaultRegion:@"CX"
                                                                    error:nil]
                                        forRegion:@"CX"]);
  XCTAssertEqual(NBEShortNumberCostUnknown,
                 [_shortNumberUtil expectedCostOfPhoneNumber:ambiguousTollFreeNumber]);
}

- (void)testGetExampleShortNumber {
  XCTAssertEqualObjects(@"100", [_testHelper exampleShortNumberWithRegionCode:@"AM"]);
  XCTAssertEqualObjects(@"15", [_testHelper exampleShortNumberWithRegionCode:@"FR"]);
  XCTAssertEqualObjects(@"", [_testHelper exampleShortNumberWithRegionCode:@"UN001"]);
}

- (void)testGetExampleShortNumberForCost {
  XCTAssertEqualObjects(@"15", [_testHelper exampleShortNumberForCost:NBEShortNumberCostTollFree
                                                           regionCode:@"FR"]);
  XCTAssertEqualObjects(@"611",
                        [_testHelper exampleShortNumberForCost:NBEShortNumberCostStandardRate
                                                    regionCode:@"FR"]);
  XCTAssertEqualObjects(@"36665",
                        [_testHelper exampleShortNumberForCost:NBEShortNumberCostPremiumRate
                                                    regionCode:@"FR"]);
  XCTAssertEqualObjects(@"", [_testHelper exampleShortNumberForCost:NBEShortNumberCostUnknown
                                                         regionCode:@"FR"]);
}

- (void)testConnectsToEmergencyNumber_US {
  XCTAssertTrue([_shortNumberUtil connectsToEmergencyNumberFromString:@"911" forRegion:@"US"]);
  XCTAssertTrue([_shortNumberUtil connectsToEmergencyNumberFromString:@"112" forRegion:@"US"]);
  XCTAssertFalse([_shortNumberUtil connectsToEmergencyNumberFromString:@"999" forRegion:@"US"]);
}

- (void)testConnectsToEmergencyNumberLongNumber_US {
  XCTAssertTrue([_shortNumberUtil connectsToEmergencyNumberFromString:@"9116666666"
                                                            forRegion:@"US"]);
  XCTAssertTrue([_shortNumberUtil connectsToEmergencyNumberFromString:@"1126666666"
                                                            forRegion:@"US"]);
  XCTAssertFalse([_shortNumberUtil connectsToEmergencyNumberFromString:@"9996666666"
                                                             forRegion:@"US"]);
}

- (void)testConnectsToEmergencyNumberWithFormatting_US {
  XCTAssertTrue([_shortNumberUtil connectsToEmergencyNumberFromString:@"9-1-1" forRegion:@"US"]);
  XCTAssertTrue([_shortNumberUtil connectsToEmergencyNumberFromString:@"1-1-2" forRegion:@"US"]);
  XCTAssertFalse([_shortNumberUtil connectsToEmergencyNumberFromString:@"9-9-9" forRegion:@"US"]);
}

- (void)testConnectsToEmergencyNumberWithPlusSign_US {
  XCTAssertFalse([_shortNumberUtil connectsToEmergencyNumberFromString:@"+911" forRegion:@"US"]);
  XCTAssertFalse([_shortNumberUtil connectsToEmergencyNumberFromString:@"\uFF0B911"
                                                             forRegion:@"US"]);
  XCTAssertFalse([_shortNumberUtil connectsToEmergencyNumberFromString:@" +911" forRegion:@"US"]);
  XCTAssertFalse([_shortNumberUtil connectsToEmergencyNumberFromString:@"+112" forRegion:@"US"]);
  XCTAssertFalse([_shortNumberUtil connectsToEmergencyNumberFromString:@"+999" forRegion:@"US"]);
}

- (void)testConnectsToEmergencyNumber_BR {
  XCTAssertTrue([_shortNumberUtil connectsToEmergencyNumberFromString:@"911" forRegion:@"BR"]);
  XCTAssertTrue([_shortNumberUtil connectsToEmergencyNumberFromString:@"190" forRegion:@"BR"]);
  XCTAssertFalse([_shortNumberUtil connectsToEmergencyNumberFromString:@"999" forRegion:@"BR"]);
}

- (void)testConnectsToEmergencyNumberLongNumber_BR {
  // Brazilian emergency numbers don't work when additional digits are appended.
  XCTAssertFalse([_shortNumberUtil connectsToEmergencyNumberFromString:@"9111" forRegion:@"BR"]);
  XCTAssertFalse([_shortNumberUtil connectsToEmergencyNumberFromString:@"1900" forRegion:@"BR"]);
  XCTAssertFalse([_shortNumberUtil connectsToEmergencyNumberFromString:@"9996" forRegion:@"BR"]);
}

- (void)testConnectsToEmergencyNumber_CL {
  XCTAssertTrue([_shortNumberUtil connectsToEmergencyNumberFromString:@"131" forRegion:@"CL"]);
  XCTAssertTrue([_shortNumberUtil connectsToEmergencyNumberFromString:@"133" forRegion:@"CL"]);
}

- (void)testConnectsToEmergencyNumberLongNumber_CL {
  // Chilean emergency numbers don't work when additional digits are appended.
  XCTAssertFalse([_shortNumberUtil connectsToEmergencyNumberFromString:@"1313" forRegion:@"CL"]);
  XCTAssertFalse([_shortNumberUtil connectsToEmergencyNumberFromString:@"1330" forRegion:@"CL"]);
}

- (void)testConnectsToEmergencyNumber_AO {
  // Angola doesn't have any metadata for emergency numbers.
  XCTAssertFalse([_shortNumberUtil connectsToEmergencyNumberFromString:@"911" forRegion:@"AO"]);
  XCTAssertFalse([_shortNumberUtil connectsToEmergencyNumberFromString:@"222123456"
                                                             forRegion:@"AO"]);
  XCTAssertFalse([_shortNumberUtil connectsToEmergencyNumberFromString:@"923123456"
                                                             forRegion:@"AO"]);
}

- (void)testConnectsToEmergencyNumber_ZW {
  // Zimbabwe doesn't have any metadata.
  XCTAssertFalse([_shortNumberUtil connectsToEmergencyNumberFromString:@"911" forRegion:@"ZW"]);
  XCTAssertFalse([_shortNumberUtil connectsToEmergencyNumberFromString:@"01312345"
                                                             forRegion:@"ZW"]);
  XCTAssertFalse([_shortNumberUtil connectsToEmergencyNumberFromString:@"0711234567"
                                                             forRegion:@"ZW"]);
}

- (void)testIsEmergencyNumber_US {
  XCTAssertTrue([_shortNumberUtil isEmergencyNumber:@"911" forRegion:@"US"]);
  XCTAssertTrue([_shortNumberUtil isEmergencyNumber:@"112" forRegion:@"US"]);
  XCTAssertFalse([_shortNumberUtil isEmergencyNumber:@"999" forRegion:@"US"]);
}

- (void)testIsEmergencyNumberLongNumber_US {
  XCTAssertFalse([_shortNumberUtil isEmergencyNumber:@"9116666666" forRegion:@"US"]);
  XCTAssertFalse([_shortNumberUtil isEmergencyNumber:@"1126666666" forRegion:@"US"]);
  XCTAssertFalse([_shortNumberUtil isEmergencyNumber:@"9996666666" forRegion:@"US"]);
}

- (void)testIsEmergencyNumberWithFormatting_US {
  XCTAssertTrue([_shortNumberUtil isEmergencyNumber:@"9-1-1" forRegion:@"US"]);
  XCTAssertTrue([_shortNumberUtil isEmergencyNumber:@"*911" forRegion:@"US"]);
  XCTAssertTrue([_shortNumberUtil isEmergencyNumber:@"1-1-2" forRegion:@"US"]);
  XCTAssertTrue([_shortNumberUtil isEmergencyNumber:@"*112" forRegion:@"US"]);
  XCTAssertFalse([_shortNumberUtil isEmergencyNumber:@"9-9-9" forRegion:@"US"]);
  XCTAssertFalse([_shortNumberUtil isEmergencyNumber:@"*999" forRegion:@"US"]);
}

- (void)testIsEmergencyNumberWithPlusSign_US {
  XCTAssertFalse([_shortNumberUtil isEmergencyNumber:@"+911" forRegion:@"US"]);
  XCTAssertFalse([_shortNumberUtil isEmergencyNumber:@"\uFF0B911" forRegion:@"US"]);
  XCTAssertFalse([_shortNumberUtil isEmergencyNumber:@" +911" forRegion:@"US"]);
  XCTAssertFalse([_shortNumberUtil isEmergencyNumber:@"+112" forRegion:@"US"]);
  XCTAssertFalse([_shortNumberUtil isEmergencyNumber:@"+999" forRegion:@"US"]);
}

- (void)testIsEmergencyNumber_BR {
  XCTAssertTrue([_shortNumberUtil connectsToEmergencyNumberFromString:@"911" forRegion:@"BR"]);
  XCTAssertTrue([_shortNumberUtil connectsToEmergencyNumberFromString:@"190" forRegion:@"BR"]);
  XCTAssertFalse([_shortNumberUtil connectsToEmergencyNumberFromString:@"999" forRegion:@"BR"]);
}

- (void)testIsEmergencyNumberLongNumber_BR {
  // Brazilian emergency numbers don't work when additional digits are appended.
  XCTAssertFalse([_shortNumberUtil connectsToEmergencyNumberFromString:@"9111" forRegion:@"BR"]);
  XCTAssertFalse([_shortNumberUtil connectsToEmergencyNumberFromString:@"1900" forRegion:@"BR"]);
  XCTAssertFalse([_shortNumberUtil connectsToEmergencyNumberFromString:@"9996" forRegion:@"BR"]);
}

- (void)testIsEmergencyNumber_AO {
  // Angola doesn't have any metadata for emergency numbers.
  XCTAssertFalse([_shortNumberUtil connectsToEmergencyNumberFromString:@"911" forRegion:@"AO"]);
  XCTAssertFalse([_shortNumberUtil connectsToEmergencyNumberFromString:@"222123456"
                                                             forRegion:@"AO"]);
  XCTAssertFalse([_shortNumberUtil connectsToEmergencyNumberFromString:@"923123456"
                                                             forRegion:@"AO"]);
}

- (void)testIsEmergencyNumber_ZW {
  // Zimbabwe doesn't have any metadata.
  XCTAssertFalse([_shortNumberUtil connectsToEmergencyNumberFromString:@"911" forRegion:@"ZW"]);
  XCTAssertFalse([_shortNumberUtil connectsToEmergencyNumberFromString:@"01312345"
                                                             forRegion:@"ZW"]);
  XCTAssertFalse([_shortNumberUtil connectsToEmergencyNumberFromString:@"0711234567"
                                                             forRegion:@"ZW"]);
}

- (void)testEmergencyNumberForSharedCountryCallingCode {
  // Test the emergency number 112, which is valid in both Australia and the Christmas Islands.
  NBPhoneNumber *auEmergencyNumber = [_phoneNumberUtil parse:@"112" defaultRegion:@"AU" error:nil];
  XCTAssertTrue([_shortNumberUtil isEmergencyNumber:@"112" forRegion:@"AU"]);
  XCTAssertTrue([_shortNumberUtil isValidShortNumber:auEmergencyNumber forRegion:@"AU"]);
  XCTAssertEqual(NBEShortNumberCostTollFree,
                 [_shortNumberUtil expectedCostOfPhoneNumber:auEmergencyNumber forRegion:@"AU"]);

  XCTAssertTrue([_shortNumberUtil isEmergencyNumber:@"112" forRegion:@"CX"]);
  XCTAssertTrue([_shortNumberUtil isValidShortNumber:auEmergencyNumber forRegion:@"CX"]);
  XCTAssertEqual(NBEShortNumberCostTollFree,
                 [_shortNumberUtil expectedCostOfPhoneNumber:auEmergencyNumber forRegion:@"CX"]);

  NBPhoneNumber *sharedEmergencyNumber = [[NBPhoneNumber alloc] init];
  sharedEmergencyNumber.countryCode = @61;
  sharedEmergencyNumber.nationalNumber = @112;
  XCTAssertTrue([_shortNumberUtil isValidShortNumber:sharedEmergencyNumber]);
  XCTAssertEqual(NBEShortNumberCostTollFree,
                 [_shortNumberUtil expectedCostOfPhoneNumber:sharedEmergencyNumber]);
}

- (void)testOverlappingNANPANumber {
  // 211 is an emergency number in Barbados, while it is a toll-free information line in Canada
  // and the USA.

  NBPhoneNumber *bb211 = [_phoneNumberUtil parse:@"211" defaultRegion:@"BB" error:nil];
  NBPhoneNumber *us211 = [_phoneNumberUtil parse:@"211" defaultRegion:@"US" error:nil];
  NBPhoneNumber *ca211 = [_phoneNumberUtil parse:@"211" defaultRegion:@"CA" error:nil];

  XCTAssertTrue([_shortNumberUtil isEmergencyNumber:@"211" forRegion:@"BB"]);
  XCTAssertEqual(NBEShortNumberCostTollFree, [_shortNumberUtil expectedCostOfPhoneNumber:bb211
                                                                               forRegion:@"BB"]);
  XCTAssertFalse([_shortNumberUtil isEmergencyNumber:@"211" forRegion:@"US"]);
  XCTAssertEqual(NBEShortNumberCostUnknown, [_shortNumberUtil expectedCostOfPhoneNumber:us211
                                                                              forRegion:@"US"]);
  XCTAssertFalse([_shortNumberUtil isEmergencyNumber:@"211" forRegion:@"CA"]);
  XCTAssertEqual(NBEShortNumberCostTollFree, [_shortNumberUtil expectedCostOfPhoneNumber:ca211
                                                                               forRegion:@"CA"]);
}

- (void)testCountryCallingCodeIsNotIgnored {
  // +46 is the country calling code for Sweden (SE), and 40404 is a valid short number in the US.
  NBPhoneNumber *seNumber = [_phoneNumberUtil parse:@"+4640404" defaultRegion:@"SE" error:nil];
  XCTAssertFalse([_shortNumberUtil isPossibleShortNumber:seNumber forRegion:@"US"]);
  XCTAssertFalse([_shortNumberUtil isValidShortNumber:seNumber forRegion:@"US"]);
  XCTAssertEqual(NBEShortNumberCostUnknown, [_shortNumberUtil expectedCostOfPhoneNumber:seNumber
                                                                              forRegion:@"US"]);
}

@end
