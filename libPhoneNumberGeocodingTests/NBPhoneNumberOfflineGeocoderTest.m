//
//  NBPhoneNumberOfflineGeocoderTest.m
//  libPhoneNumberGeocodingTests
//
//  Created by Rastaar Haghi on 6/23/20.
//  Copyright © 2020 Google LLC. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "NBGeocoderMetadataHelper.h"
#import "NBPhoneNumber.h"
#import "NBPhoneNumberOfflineGeocoder.h"
#import "NBPhoneNumberUtil.h"

@interface NBPhoneNumberOfflineGeocoderTest : XCTestCase

@property(nonatomic, strong) NBPhoneNumberOfflineGeocoder *geocoder;
@property(nonatomic, readonly, copy) NBPhoneNumber *koreanPhoneNumber1;
@property(nonatomic, readonly, copy) NBPhoneNumber *koreanPhoneNumber2;
@property(nonatomic, readonly, copy) NBPhoneNumber *koreanPhoneNumber3;
@property(nonatomic, readonly, copy) NBPhoneNumber *invalidKoreanPhoneNumber;
@property(nonatomic, readonly, copy) NBPhoneNumber *koreanMobilePhoneNumber;
@property(nonatomic, readonly, copy) NBPhoneNumber *unitedStatesPhoneNumber1;
@property(nonatomic, readonly, copy) NBPhoneNumber *unitedStatesPhoneNumber2;
@property(nonatomic, readonly, copy) NBPhoneNumber *unitedStatesPhoneNumber3;
@property(nonatomic, readonly, copy) NBPhoneNumber *unitedStatesPhoneNumber4;
@property(nonatomic, readonly, copy) NBPhoneNumber *invalidUSPhoneNumber;
@property(nonatomic, readonly, copy) NBPhoneNumber *tollFreeNANPAPhoneNumber;
@property(nonatomic, readonly, copy) NBPhoneNumber *bahamasPhoneNumber;
@property(nonatomic, readonly, copy) NBPhoneNumber *australianPhoneNumber;
@property(nonatomic, readonly, copy) NBPhoneNumber *germanPhoneNumber;
@property(nonatomic, readonly, copy) NBPhoneNumber *italianPhoneNumber;
@property(nonatomic, readonly, copy) NBPhoneNumber *saudiArabianPhoneNumber;
@property(nonatomic, readonly, copy) NBPhoneNumber *invalidCountryCodePhoneNumber;
@property(nonatomic, readonly, copy) NBPhoneNumber *internationalTollFreePhoneNumber;

@end

@implementation NBPhoneNumberOfflineGeocoderTest

- (void)setUp {
  [super setUp];
  // For testing purposes, this set-up will pass in a testing database.
  NSBundle *bundle = [NSBundle bundleForClass:self.classForCoder];
  NSURL *resourceURL = [[bundle resourceURL] URLByAppendingPathComponent:@"TestingSource.bundle"];
  NSBundle *testDatabaseBundle = [NSBundle bundleWithURL:resourceURL];

  NBPhoneNumberUtil *phoneNumberUtil = [NBPhoneNumberUtil sharedInstance];

  self.geocoder = [[NBPhoneNumberOfflineGeocoder alloc]
      initWithMetadataHelperFactory:^NBGeocoderMetadataHelper *(NSNumber *_Nonnull countryCode,
                                                                NSString *_Nonnull language) {
        return [[NBGeocoderMetadataHelper alloc] initWithCountryCode:countryCode
                                                        withLanguage:language
                                                          withBundle:testDatabaseBundle];
      }
                    phoneNumberUtil:phoneNumberUtil];
}

- (NBPhoneNumber *)koreanPhoneNumber1 {
  NBPhoneNumber *alphaNumbericNumber = [[NBPhoneNumber alloc] init];
  alphaNumbericNumber.countryCode = @82;
  alphaNumbericNumber.nationalNumber = @22123456;
  return alphaNumbericNumber;
}

- (NBPhoneNumber *)koreanPhoneNumber2 {
  NBPhoneNumber *alphaNumbericNumber = [[NBPhoneNumber alloc] init];
  alphaNumbericNumber.countryCode = @82;
  alphaNumbericNumber.nationalNumber = @322123456;
  return alphaNumbericNumber;
}

- (NBPhoneNumber *)koreanPhoneNumber3 {
  NBPhoneNumber *alphaNumbericNumber = [[NBPhoneNumber alloc] init];
  alphaNumbericNumber.countryCode = @82;
  alphaNumbericNumber.nationalNumber = @6421234567;
  return alphaNumbericNumber;
}

- (NBPhoneNumber *)invalidKoreanPhoneNumber {
  NBPhoneNumber *alphaNumbericNumber = [[NBPhoneNumber alloc] init];
  alphaNumbericNumber.countryCode = @82;
  alphaNumbericNumber.nationalNumber = @1234;
  return alphaNumbericNumber;
}

- (NBPhoneNumber *)koreanMobilePhoneNumber {
  NBPhoneNumber *alphaNumbericNumber = [[NBPhoneNumber alloc] init];
  alphaNumbericNumber.countryCode = @82;
  alphaNumbericNumber.nationalNumber = @101234567;
  return alphaNumbericNumber;
}

- (NBPhoneNumber *)unitedStatesPhoneNumber1 {
  NBPhoneNumber *alphaNumbericNumber = [[NBPhoneNumber alloc] init];
  alphaNumbericNumber.countryCode = @1;
  alphaNumbericNumber.nationalNumber = @6501234567;
  return alphaNumbericNumber;
}

- (NBPhoneNumber *)unitedStatesPhoneNumber2 {
  NBPhoneNumber *alphaNumbericNumber = [[NBPhoneNumber alloc] init];
  alphaNumbericNumber.countryCode = @1;
  alphaNumbericNumber.nationalNumber = @6509600000;
  return alphaNumbericNumber;
}

- (NBPhoneNumber *)unitedStatesPhoneNumber3 {
  NBPhoneNumber *alphaNumbericNumber = [[NBPhoneNumber alloc] init];
  alphaNumbericNumber.countryCode = @1;
  alphaNumbericNumber.nationalNumber = @2128120000;
  return alphaNumbericNumber;
}

- (NBPhoneNumber *)unitedStatesPhoneNumber4 {
  NBPhoneNumber *alphaNumbericNumber = [[NBPhoneNumber alloc] init];
  alphaNumbericNumber.countryCode = @1;
  alphaNumbericNumber.nationalNumber = @9097111234;
  return alphaNumbericNumber;
}

- (NBPhoneNumber *)invalidUSPhoneNumber {
  NBPhoneNumber *alphaNumbericNumber = [[NBPhoneNumber alloc] init];
  alphaNumbericNumber.countryCode = @1;
  alphaNumbericNumber.nationalNumber = @123456789;
  return alphaNumbericNumber;
}

- (NBPhoneNumber *)tollFreeNANPAPhoneNumber {
  NBPhoneNumber *alphaNumbericNumber = [[NBPhoneNumber alloc] init];
  alphaNumbericNumber.countryCode = @1;
  alphaNumbericNumber.nationalNumber = @8002431234;
  return alphaNumbericNumber;
}

- (NBPhoneNumber *)bahamasPhoneNumber {
  NBPhoneNumber *alphaNumbericNumber = [[NBPhoneNumber alloc] init];
  alphaNumbericNumber.countryCode = @1;
  alphaNumbericNumber.nationalNumber = @2423651234;
  return alphaNumbericNumber;
}

- (NBPhoneNumber *)australianPhoneNumber {
  NBPhoneNumber *alphaNumbericNumber = [[NBPhoneNumber alloc] init];
  alphaNumbericNumber.countryCode = @61;
  alphaNumbericNumber.nationalNumber = @236618300;
  return alphaNumbericNumber;
}

- (NBPhoneNumber *)saudiArabianPhoneNumber {
  NBPhoneNumber *alphaNumbericNumber = [[NBPhoneNumber alloc] init];
  alphaNumbericNumber.countryCode = @54;
  alphaNumbericNumber.nationalNumber = @2214000000;
  return alphaNumbericNumber;
}

- (NBPhoneNumber *)germanPhoneNumber {
  NBPhoneNumber *alphaNumbericNumber = [[NBPhoneNumber alloc] init];
  alphaNumbericNumber.countryCode = @43;
  alphaNumbericNumber.nationalNumber = @25721234;
  return alphaNumbericNumber;
}

- (NBPhoneNumber *)italianPhoneNumber {
  NBPhoneNumber *alpha = [NBPhoneNumberUtil.new parse:@"+39016100000"
                                        defaultRegion:@"IT"
                                                error:nil];
  return alpha;
}

- (NBPhoneNumber *)invalidCountryCodePhoneNumber {
  NBPhoneNumber *alphaNumbericNumber = [[NBPhoneNumber alloc] init];
  alphaNumbericNumber.countryCode = @999;
  alphaNumbericNumber.nationalNumber = @2423651234;
  return alphaNumbericNumber;
}

- (NBPhoneNumber *)internationalTollFreePhoneNumber {
  NBPhoneNumber *alphaNumbericNumber = [[NBPhoneNumber alloc] init];
  alphaNumbericNumber.countryCode = @800;
  alphaNumbericNumber.nationalNumber = @12345678;
  return alphaNumbericNumber;
}

- (void)testGetDescriptionForNumberWithNoDataFile {
  // No data file containing mappings for US numbers is available in Chinese for the unittests. As
  // a result, the country name of United States in simplified Chinese is returned.
  XCTAssertEqualObjects(@"\u7F8E\u56FD",
                        [self.geocoder descriptionForNumber:self.unitedStatesPhoneNumber2
                                           withLanguageCode:@"zh"]);
  XCTAssertEqualObjects(@"Abaco Island", [self.geocoder descriptionForNumber:self.bahamasPhoneNumber
                                                            withLanguageCode:@"en"]);
  XCTAssertEqualObjects(@"Australia", [self.geocoder descriptionForNumber:self.australianPhoneNumber
                                                         withLanguageCode:@"en"]);
  XCTAssertNil([self.geocoder descriptionForNumber:self.invalidCountryCodePhoneNumber
                                  withLanguageCode:@"en"]);
  XCTAssertNil([self.geocoder descriptionForNumber:self.internationalTollFreePhoneNumber
                                  withLanguageCode:@"en"]);
}

- (void)testGetDescriptionForNumberWithNoDatabaseEntry {
  // Test that the name of the country is returned when the number passed in is valid but not
  // covered by the geocoding data file.
  XCTAssertEqualObjects(@"Estados Unidos",
                        [self.geocoder descriptionForNumber:self.unitedStatesPhoneNumber4
                                           withLanguageCode:@"es"]);
}

- (void)testGetDescriptionForNumberBelongingToMultipleCountriesIsEmpty {
  // Test that nothing is returned when the number passed in is valid but not
  // covered by the geocoding data file and belongs to multiple countries
  XCTAssertNil([self.geocoder descriptionForNumber:self.tollFreeNANPAPhoneNumber
                                  withLanguageCode:@"en"]);
}

- (void)testGetDescriptionForNumber_en_US {
  XCTAssertEqualObjects(@"Mountain View, CA",
                        [self.geocoder descriptionForNumber:self.unitedStatesPhoneNumber2
                                           withLanguageCode:@"en"]);
  XCTAssertEqualObjects(@"New York, NY",
                        [self.geocoder descriptionForNumber:self.unitedStatesPhoneNumber3
                                           withLanguageCode:@"en"]);
}

- (void)testGetDescriptionForKoreanNumber {
  XCTAssertEqualObjects(@"Seoul", [self.geocoder descriptionForNumber:self.koreanPhoneNumber1
                                                     withLanguageCode:@"en"]);
  XCTAssertEqualObjects(@"Incheon", [self.geocoder descriptionForNumber:self.koreanPhoneNumber2
                                                       withLanguageCode:@"en"]);
  XCTAssertEqualObjects(@"Jeju", [self.geocoder descriptionForNumber:self.koreanPhoneNumber3
                                                    withLanguageCode:@"en"]);
  XCTAssertEqualObjects(@"\uC11C\uC6B8", [self.geocoder descriptionForNumber:self.koreanPhoneNumber1
                                                            withLanguageCode:@"ko"]);
  XCTAssertEqualObjects(@"\uC778\uCC9C", [self.geocoder descriptionForNumber:self.koreanPhoneNumber2
                                                            withLanguageCode:@"ko"]);
}

- (void)testGetDescriptionForArgentinianMobileNumber {
  XCTAssertEqualObjects(@"La Plata, Buenos Aires",
                        [self.geocoder descriptionForNumber:self.saudiArabianPhoneNumber
                                           withLanguageCode:@"en"]);
}

- (void)testGetDescriptionForFallBack {
  // No fallback, as the location name for the given phone number is available in the requested
  // language.
  XCTAssertEqualObjects(@"Mistelbach", [self.geocoder descriptionForNumber:self.germanPhoneNumber
                                                          withLanguageCode:@"de"]);
  XCTAssertEqualObjects(@"New York, NY",
                        [self.geocoder descriptionForNumber:self.unitedStatesPhoneNumber3
                                           withLanguageCode:@"en"]);

  // TODO: Fix the test
  // XCTAssertEqualObjects(@"Vercelli", [self.geocoder descriptionForNumber:self.italianPhoneNumber
  //                                                        withLanguageCode:@"it"]);
  XCTAssertEqualObjects(@"\uc81c\uc8fc", [self.geocoder descriptionForNumber:self.koreanPhoneNumber3
                                                            withLanguageCode:@"ko"]);
}

- (void)testGetDescriptionForNumberWithUserRegion {
  // User in Italy, American number. We should just show United States, in Spanish, and not more
  // detailed information.
  XCTAssertEqualObjects(@"Estados Unidos",
                        [self.geocoder descriptionForNumber:self.unitedStatesPhoneNumber2
                                           withLanguageCode:@"es"
                                             withUserRegion:@"IT"]);
  // Unknown region - should just show country name.
  XCTAssertEqualObjects(@"Estados Unidos",
                        [self.geocoder descriptionForNumber:self.unitedStatesPhoneNumber2
                                           withLanguageCode:@"es"
                                             withUserRegion:@"ZZ"]);
  // User in the States, language German, should show detailed data.
  XCTAssertEqualObjects(@"Vereinigte Staaten",
                        [self.geocoder descriptionForNumber:self.unitedStatesPhoneNumber2
                                           withLanguageCode:@"de"
                                             withUserRegion:@"US"]);
  // User in the States, language French, no data for French, so we fallback to English detailed
  // data.
  XCTAssertEqualObjects(@"États-Unis",
                        [self.geocoder descriptionForNumber:self.unitedStatesPhoneNumber2
                                           withLanguageCode:@"fr"
                                             withUserRegion:@"US"]);
  // An invalid phone number is expected to return nil
  XCTAssertNil([self.geocoder descriptionForNumber:self.invalidUSPhoneNumber
                                  withLanguageCode:@"en"
                                    withUserRegion:@"US"]);
}

- (void)testGetDescriptionForInvalidNumber {
  // This is an example of a functional test case.
  // Use XCTAssert and related functions to verify your tests produce the correct results.
  XCTAssertNil([self.geocoder descriptionForNumber:self.invalidKoreanPhoneNumber
                                  withLanguageCode:@"en"]);
  XCTAssertNil([self.geocoder descriptionForNumber:self.invalidUSPhoneNumber
                                  withLanguageCode:@"en"]);
}

- (void)testGetDescriptionForNonGeographicalNumber {
  // This phone number should return the country name rather than searching for a region description
  // since the phone number is nongeographical.
  XCTAssertEqualObjects(@"South Korea",
                        [self.geocoder descriptionForNumber:self.koreanMobilePhoneNumber
                                           withLanguageCode:@"en"]);
}

#pragma mark - Convenience method tests

// This set of tests utilizes the convenience methods, assuming that the current device's language
// is set to English

- (void)testConvenienceGetDescriptionForNumberWithNoDataFile {
  XCTAssertEqualObjects(@"Abaco Island",
                        [self.geocoder descriptionForNumber:self.bahamasPhoneNumber]);
  XCTAssertEqualObjects(@"Australia",
                        [self.geocoder descriptionForNumber:self.australianPhoneNumber]);
  XCTAssertNil([self.geocoder descriptionForNumber:self.invalidCountryCodePhoneNumber]);
  XCTAssertNil([self.geocoder descriptionForNumber:self.internationalTollFreePhoneNumber]);
}

- (void)testConvenienceGetDescriptionForNumberWithNoDatabaseEntry {
  // Test that the name of the country is returned when the number passed in is valid but not
  // covered by the geocoding data file.
  XCTAssertEqualObjects(@"Australia",
                        [self.geocoder descriptionForNumber:self.australianPhoneNumber]);
}

- (void)testConvenienceGetDescriptionForNumberBelongingToMultipleCountriesIsEmpty {
  // Test that nothing is returned when the number passed in is valid but not
  // covered by the geocoding data file and belongs to multiple countries
  XCTAssertNil([self.geocoder descriptionForNumber:self.tollFreeNANPAPhoneNumber]);
}

- (void)testConvenienceGetDescriptionForNumber_en_US {
  XCTAssertEqualObjects(@"Mountain View, CA",
                        [self.geocoder descriptionForNumber:self.unitedStatesPhoneNumber2]);
  XCTAssertEqualObjects(@"New York, NY",
                        [self.geocoder descriptionForNumber:self.unitedStatesPhoneNumber3]);
}

- (void)testConvenienceGetDescriptionForKoreanNumber {
  XCTAssertEqualObjects(@"Seoul", [self.geocoder descriptionForNumber:self.koreanPhoneNumber1]);
  XCTAssertEqualObjects(@"Incheon", [self.geocoder descriptionForNumber:self.koreanPhoneNumber2]);
  XCTAssertEqualObjects(@"Jeju", [self.geocoder descriptionForNumber:self.koreanPhoneNumber3]);
}

- (void)testConvenienceGetDescriptionForArgentinianMobileNumber {
  XCTAssertEqualObjects(@"La Plata, Buenos Aires",
                        [self.geocoder descriptionForNumber:self.saudiArabianPhoneNumber]);
}

- (void)testConvenienceGetDescriptionForFallBack {
  // No fallback, as the location name for the given phone number is available in the requested
  // language.
  XCTAssertEqualObjects(@"New York, NY",
                        [self.geocoder descriptionForNumber:self.unitedStatesPhoneNumber3]);
}

- (void)testConvenienceGetDescriptionForNumberWithUserRegion {
  // User in Italy, American number. We should just show United States, in Spanish, and not more
  // detailed information.
  XCTAssertEqualObjects(@"Estados Unidos",
                        [self.geocoder descriptionForNumber:self.unitedStatesPhoneNumber2
                                           withLanguageCode:@"es"
                                             withUserRegion:@"IT"]);
  // Unknown region - should just show country name.
  XCTAssertEqualObjects(@"Estados Unidos",
                        [self.geocoder descriptionForNumber:self.unitedStatesPhoneNumber2
                                           withLanguageCode:@"es"
                                             withUserRegion:@"ZZ"]);
  // User in the States, language German, should show detailed data.
  XCTAssertEqualObjects(@"Vereinigte Staaten",
                        [self.geocoder descriptionForNumber:self.unitedStatesPhoneNumber2
                                           withLanguageCode:@"de"
                                             withUserRegion:@"US"]);
  // User in the States, language French, no data for French, so we fallback to English detailed
  // data.
  XCTAssertEqualObjects(@"Australia", [self.geocoder descriptionForNumber:self.australianPhoneNumber
                                                           withUserRegion:@"US"]);
  // An invalid phone number is expected to return nil
  XCTAssertNil([self.geocoder descriptionForNumber:self.invalidUSPhoneNumber
                                  withLanguageCode:@"en"
                                    withUserRegion:@"US"]);
}

- (void)testConvenienceGetDescriptionForInvalidNumber {
  XCTAssertNil([self.geocoder descriptionForNumber:self.invalidKoreanPhoneNumber]);
  XCTAssertNil([self.geocoder descriptionForNumber:self.invalidUSPhoneNumber]);
}

- (void)testConvenienceGetDescriptionForNonGeographicalNumber {
  // This phone number should return the country name rather than searching for a region description
  // since the phone number is nongeographical.
  XCTAssertEqualObjects(@"South Korea",
                        [self.geocoder descriptionForNumber:self.koreanMobilePhoneNumber]);
}

@end
