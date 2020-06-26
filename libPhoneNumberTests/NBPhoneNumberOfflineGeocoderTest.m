//
//  NBPhoneNumberOfflineGeocoderTest.m
//  libPhoneNumberGeocodingTests
//
//  Created by Rastaar Haghi on 6/23/20.
//  Copyright © 2020 Google LLC. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "NBPhoneNumber.h"
#import "NBPhoneNumberOfflineGeocoder.h"
#import "NBPhoneNumberUtil.h"

@interface NBPhoneNumberOfflineGeocoderTest : XCTestCase

@property(nonatomic, strong) NBPhoneNumberOfflineGeocoder *geocoder;

@property(nonatomic, readonly, copy) NBPhoneNumber *KO_NUMBER1;
@property(nonatomic, readonly, copy) NBPhoneNumber *KO_NUMBER2;
@property(nonatomic, readonly, copy) NBPhoneNumber *KO_NUMBER3;
@property(nonatomic, readonly, copy) NBPhoneNumber *KO_INVALID_NUMBER;
@property(nonatomic, readonly, copy) NBPhoneNumber *KO_MOBILE;
@property(nonatomic, readonly, copy) NBPhoneNumber *US_NUMBER1;
@property(nonatomic, readonly, copy) NBPhoneNumber *US_NUMBER2;
@property(nonatomic, readonly, copy) NBPhoneNumber *US_NUMBER3;
@property(nonatomic, readonly, copy) NBPhoneNumber *US_NUMBER4;
@property(nonatomic, readonly, copy) NBPhoneNumber *US_INVALID_NUMBER;
@property(nonatomic, readonly, copy) NBPhoneNumber *NANPA_TOLL_FREE;
@property(nonatomic, readonly, copy) NBPhoneNumber *BS_NUMBER1;
@property(nonatomic, readonly, copy) NBPhoneNumber *AU_NUMBER;
@property(nonatomic, readonly, copy) NBPhoneNumber *GERMAN_NUMBER;
@property(nonatomic, readonly, copy) NBPhoneNumber *ITALIAN_NUMBER;
@property(nonatomic, readonly, copy) NBPhoneNumber *AR_MOBILE_NUMBER;
@property(nonatomic, readonly, copy) NBPhoneNumber *NUMBER_WITH_INVALID_COUNTRY_CODE;
@property(nonatomic, readonly, copy) NBPhoneNumber *INTERNATIONAL_TOLL_FREE;

@end

@implementation NBPhoneNumberOfflineGeocoderTest

- (void)setUp {
  // Put setup code here. This method is called before the invocation of each test method in the
  // class.
    self.geocoder = NBPhoneNumberOfflineGeocoder.sharedInstance;
}

- (void)tearDown {
  // Put teardown code here. This method is called after the invocation of each test method in the
  // class.
}

- (NBPhoneNumber *)KO_NUMBER1 {
  NBPhoneNumber *alphaNumbericNumber = [[NBPhoneNumber alloc] init];
  alphaNumbericNumber.countryCode = @82;
  alphaNumbericNumber.nationalNumber = @22123456;
  return alphaNumbericNumber;
}

- (NBPhoneNumber *)KO_NUMBER2 {
  NBPhoneNumber *alphaNumbericNumber = [[NBPhoneNumber alloc] init];
  alphaNumbericNumber.countryCode = @82;
  alphaNumbericNumber.nationalNumber = @322123456;
  return alphaNumbericNumber;
}

- (NBPhoneNumber *)KO_NUMBER3 {
  NBPhoneNumber *alphaNumbericNumber = [[NBPhoneNumber alloc] init];
  alphaNumbericNumber.countryCode = @82;
  alphaNumbericNumber.nationalNumber = @6421234567;
  return alphaNumbericNumber;
}

- (NBPhoneNumber *)KO_INVALID_NUMBER {
  NBPhoneNumber *alphaNumbericNumber = [[NBPhoneNumber alloc] init];
  alphaNumbericNumber.countryCode = @82;
  alphaNumbericNumber.nationalNumber = @1234;
  return alphaNumbericNumber;
}

- (NBPhoneNumber *)KO_MOBILE {
  NBPhoneNumber *alphaNumbericNumber = [[NBPhoneNumber alloc] init];
  alphaNumbericNumber.countryCode = @82;
  alphaNumbericNumber.nationalNumber = @101234567;
  return alphaNumbericNumber;
}

- (NBPhoneNumber *)US_NUMBER1 {
  NBPhoneNumber *alphaNumbericNumber = [[NBPhoneNumber alloc] init];
  alphaNumbericNumber.countryCode = @1;
  alphaNumbericNumber.nationalNumber = @6501234567;
  return alphaNumbericNumber;
}

- (NBPhoneNumber *)US_NUMBER2 {
  NBPhoneNumber *alphaNumbericNumber = [[NBPhoneNumber alloc] init];
  alphaNumbericNumber.countryCode = @1;
  alphaNumbericNumber.nationalNumber = @6509600000;
  return alphaNumbericNumber;
}

- (NBPhoneNumber *)US_NUMBER3 {
  NBPhoneNumber *alphaNumbericNumber = [[NBPhoneNumber alloc] init];
  alphaNumbericNumber.countryCode = @1;
  alphaNumbericNumber.nationalNumber = @2128120000;
  return alphaNumbericNumber;
}

- (NBPhoneNumber *)US_NUMBER4 {
  NBPhoneNumber *alphaNumbericNumber = [[NBPhoneNumber alloc] init];
  alphaNumbericNumber.countryCode = @1;
  alphaNumbericNumber.nationalNumber = @9097111234;
  return alphaNumbericNumber;
}

- (NBPhoneNumber *)US_INVALID_NUMBER {
  NBPhoneNumber *alphaNumbericNumber = [[NBPhoneNumber alloc] init];
  alphaNumbericNumber.countryCode = @1;
  alphaNumbericNumber.nationalNumber = @123456789;
  return alphaNumbericNumber;
}

- (NBPhoneNumber *)NANPA_TOLL_FREE {
  NBPhoneNumber *alphaNumbericNumber = [[NBPhoneNumber alloc] init];
  alphaNumbericNumber.countryCode = @1;
  alphaNumbericNumber.nationalNumber = @8002431234;
  return alphaNumbericNumber;
}

- (NBPhoneNumber *)BS_NUMBER1 {
  NBPhoneNumber *alphaNumbericNumber = [[NBPhoneNumber alloc] init];
  alphaNumbericNumber.countryCode = @1;
  alphaNumbericNumber.nationalNumber = @2423651234;
  return alphaNumbericNumber;
}

- (NBPhoneNumber *)AU_NUMBER {
  NBPhoneNumber *alphaNumbericNumber = [[NBPhoneNumber alloc] init];
  alphaNumbericNumber.countryCode = @61;
  alphaNumbericNumber.nationalNumber = @236618300;
  return alphaNumbericNumber;
}

- (NBPhoneNumber *)AR_MOBILE_NUMBER {
  NBPhoneNumber *alphaNumbericNumber = [[NBPhoneNumber alloc] init];
  alphaNumbericNumber.countryCode = @54;
  alphaNumbericNumber.nationalNumber = @2214000000;
  return alphaNumbericNumber;
}

- (NBPhoneNumber *)GERMAN_NUMBER {
  NBPhoneNumber *alphaNumbericNumber = [[NBPhoneNumber alloc] init];
  alphaNumbericNumber.countryCode = @43;
  alphaNumbericNumber.nationalNumber = @25721234;
  return alphaNumbericNumber;
}

- (NBPhoneNumber *)ITALIAN_NUMBER {
  NBPhoneNumber *alpha = [NBPhoneNumberUtil.new parse:@"+39016100000"
                                        defaultRegion:@"IT"
                                                error:nil];
  return alpha;
}

- (NBPhoneNumber *)NUMBER_WITH_INVALID_COUNTRY_CODE {
  NBPhoneNumber *alphaNumbericNumber = [[NBPhoneNumber alloc] init];
  alphaNumbericNumber.countryCode = @999;
  alphaNumbericNumber.nationalNumber = @2423651234;
  return alphaNumbericNumber;
}

- (NBPhoneNumber *)INTERNATIONAL_TOLL_FREE {
  NBPhoneNumber *alphaNumbericNumber = [[NBPhoneNumber alloc] init];
  alphaNumbericNumber.countryCode = @800;
  alphaNumbericNumber.nationalNumber = @12345678;
  return alphaNumbericNumber;
}

- (void)testGetDescriptionForNumberWithNoDataFile {
  // No data file containing mappings for US numbers is available in Chinese for the unittests. As
  // a result, the country name of United States in simplified Chinese is returned.
  XCTAssertEqualObjects(@"\u7F8E\u56FD", [self.geocoder descriptionForNumber:self.US_NUMBER2
                                                            withLanguageCode:@"zh"]);
  XCTAssertEqualObjects(@"Abaco Island", [self.geocoder descriptionForNumber:self.BS_NUMBER1
                                                            withLanguageCode:@"en"]);
  XCTAssertEqualObjects(@"Australia", [self.geocoder descriptionForNumber:self.AU_NUMBER
                                                         withLanguageCode:@"en"]);
  XCTAssertEqualObjects(nil,
                        [self.geocoder descriptionForNumber:self.NUMBER_WITH_INVALID_COUNTRY_CODE
                                           withLanguageCode:@"en"]);
  XCTAssertEqualObjects(nil, [self.geocoder descriptionForNumber:self.INTERNATIONAL_TOLL_FREE
                                                withLanguageCode:@"en"]);
}

- (void)testGetDescriptionForNumberWithNoDatabaseEntry {
  // Test that the name of the country is returned when the number passed in is valid but not
  // covered by the geocoding data file.
  XCTAssertEqualObjects(@"Estados Unidos", [self.geocoder descriptionForNumber:self.US_NUMBER4
                                                              withLanguageCode:@"es"]);
}

- (void)testGetDescriptionForNumberBelongingToMultipleCountriesIsEmpty {
  // Test that nothing is returned when the number passed in is valid but not
  // covered by the geocoding data file and belongs to multiple countries
  XCTAssertEqualObjects(nil, [self.geocoder descriptionForNumber:self.NANPA_TOLL_FREE
                                                withLanguageCode:@"en"]);
}

- (void)testGetDescriptionForNumber_en_US {
  //    XCTAssertEqualObjects(@"California", [self.geocoder descriptionForNumber: self.US_NUMBER1
  //    withLanguageCode:@"en"]);
  XCTAssertEqualObjects(@"Mountain View, CA", [self.geocoder descriptionForNumber:self.US_NUMBER2
                                                                 withLanguageCode:@"en"]);
  XCTAssertEqualObjects(@"New York, NY", [self.geocoder descriptionForNumber:self.US_NUMBER3
                                                            withLanguageCode:@"en"]);
}

- (void)testGetDescriptionForKoreanNumber {
  XCTAssertEqualObjects(@"Seoul", [self.geocoder descriptionForNumber:self.KO_NUMBER1
                                                     withLanguageCode:@"en"]);
  XCTAssertEqualObjects(@"Incheon", [self.geocoder descriptionForNumber:self.KO_NUMBER2
                                                       withLanguageCode:@"en"]);
  XCTAssertEqualObjects(@"Jeju", [self.geocoder descriptionForNumber:self.KO_NUMBER3
                                                    withLanguageCode:@"en"]);
  XCTAssertEqualObjects(@"\uC11C\uC6B8", [self.geocoder descriptionForNumber:self.KO_NUMBER1
                                                            withLanguageCode:@"ko"]);
  XCTAssertEqualObjects(@"\uC778\uCC9C", [self.geocoder descriptionForNumber:self.KO_NUMBER2
                                                            withLanguageCode:@"ko"]);
}

- (void)testGetDescriptionForArgentinianMobileNumber {
  XCTAssertEqualObjects(@"La Plata, Buenos Aires",
                        [self.geocoder descriptionForNumber:self.AR_MOBILE_NUMBER
                                           withLanguageCode:@"en"]);
}

- (void)testGetDescriptionForFallBack {
  // No fallback, as the location name for the given phone number is available in the requested
  // language.
  XCTAssertEqualObjects(@"Mistelbach", [self.geocoder descriptionForNumber:self.GERMAN_NUMBER
                                                          withLanguageCode:@"de"]);
  XCTAssertEqualObjects(@"New York, NY", [self.geocoder descriptionForNumber:self.US_NUMBER3
                                                            withLanguageCode:@"en"]);
  XCTAssertEqualObjects(@"Vercelli", [self.geocoder descriptionForNumber:self.ITALIAN_NUMBER
                                                        withLanguageCode:@"it"]);
  XCTAssertEqualObjects(@"\uc81c\uc8fc", [self.geocoder descriptionForNumber:self.KO_NUMBER3
                                                            withLanguageCode:@"ko"]);
}

- (void)testGetDescriptionForNumberWithUserRegion {
  // User in Italy, American number. We should just show United States, in Spanish, and not more
  // detailed information.
  XCTAssertEqualObjects(@"Estados Unidos", [self.geocoder descriptionForNumber:self.US_NUMBER2
                                                              withLanguageCode:@"es"
                                                                withUserRegion:@"IT"]);
  // Unknown region - should just show country name.
  XCTAssertEqualObjects(@"Estados Unidos", [self.geocoder descriptionForNumber:self.US_NUMBER2
                                                              withLanguageCode:@"es"
                                                                withUserRegion:@"ZZ"]);
  // User in the States, language German, should show detailed data.
  XCTAssertEqualObjects(@"Vereinigte Staaten", [self.geocoder descriptionForNumber:self.US_NUMBER2
                                                                  withLanguageCode:@"de"
                                                                    withUserRegion:@"US"]);
  //     User in the States, language French, no data for French, so we fallback to English detailed
  // data.
  XCTAssertEqualObjects(@"États-Unis", [self.geocoder descriptionForNumber:self.US_NUMBER2
                                                          withLanguageCode:@"fr"
                                                            withUserRegion:@"US"]);
  // An invalid phone number is expected to return nil
  XCTAssertEqualObjects(nil, [self.geocoder descriptionForNumber:self.US_INVALID_NUMBER
                                                withLanguageCode:@"en"
                                                  withUserRegion:@"US"]);
}

- (void)testGetDescriptionForInvalidNumber {
  // This is an example of a functional test case.
  // Use XCTAssert and related functions to verify your tests produce the correct results.
  XCTAssertEqualObjects(nil, [self.geocoder descriptionForNumber:self.KO_INVALID_NUMBER
                                                withLanguageCode:@"en"]);
  XCTAssertEqualObjects(nil, [self.geocoder descriptionForNumber:self.US_INVALID_NUMBER
                                                withLanguageCode:@"en"]);
}

- (void)testGetDescriptionForNonGeographicalNumber {
  // This phone number should return the country name rather than searching for a region description
  // since the phone number is nongeographical.
  XCTAssertEqualObjects(@"South Korea", [self.geocoder descriptionForNumber:self.KO_MOBILE
                                                           withLanguageCode:@"en"]);
}

//#pragma mark - Convenience method tests

// This set of tests utilizes the convenience methods, assuming that the current device's language
// is set to English

- (void)testConvenienceGetDescriptionForNumberWithNoDataFile {
  XCTAssertEqualObjects(@"Abaco Island", [self.geocoder descriptionForNumber:self.BS_NUMBER1]);
  XCTAssertEqualObjects(@"Australia", [self.geocoder descriptionForNumber:self.AU_NUMBER]);
  XCTAssertEqualObjects(nil,
                        [self.geocoder descriptionForNumber:self.NUMBER_WITH_INVALID_COUNTRY_CODE]);
  XCTAssertEqualObjects(nil, [self.geocoder descriptionForNumber:self.INTERNATIONAL_TOLL_FREE]);
}

- (void)testConvenienceGetDescriptionForNumberWithNoDatabaseEntry {
  // Test that the name of the country is returned when the number passed in is valid but not
  // covered by the geocoding data file.
  XCTAssertEqualObjects(@"Australia", [self.geocoder descriptionForNumber:self.AU_NUMBER]);
}

- (void)testConvenienceGetDescriptionForNumberBelongingToMultipleCountriesIsEmpty {
  // Test that nothing is returned when the number passed in is valid but not
  // covered by the geocoding data file and belongs to multiple countries
  XCTAssertEqualObjects(nil, [self.geocoder descriptionForNumber:self.NANPA_TOLL_FREE]);
}

- (void)testConvenienceGetDescriptionForNumber_en_US {
  XCTAssertEqualObjects(@"Mountain View, CA", [self.geocoder descriptionForNumber:self.US_NUMBER2]);
  XCTAssertEqualObjects(@"New York, NY", [self.geocoder descriptionForNumber:self.US_NUMBER3]);
}

- (void)testConvenienceGetDescriptionForKoreanNumber {
  XCTAssertEqualObjects(@"Seoul", [self.geocoder descriptionForNumber:self.KO_NUMBER1]);
  XCTAssertEqualObjects(@"Incheon", [self.geocoder descriptionForNumber:self.KO_NUMBER2]);
  XCTAssertEqualObjects(@"Jeju", [self.geocoder descriptionForNumber:self.KO_NUMBER3]);
}

- (void)testConvenienceGetDescriptionForArgentinianMobileNumber {
  XCTAssertEqualObjects(@"La Plata, Buenos Aires",
                        [self.geocoder descriptionForNumber:self.AR_MOBILE_NUMBER]);
}

- (void)testConvenienceGetDescriptionForFallBack {
  // No fallback, as the location name for the given phone number is available in the requested
  // language.
  XCTAssertEqualObjects(@"New York, NY", [self.geocoder descriptionForNumber:self.US_NUMBER3]);
}

- (void)testConvenienceGetDescriptionForNumberWithUserRegion {
  // User in Italy, American number. We should just show United States, in Spanish, and not more
  // detailed information.
  XCTAssertEqualObjects(@"Estados Unidos", [self.geocoder descriptionForNumber:self.US_NUMBER2
                                                              withLanguageCode:@"es"
                                                                withUserRegion:@"IT"]);
  // Unknown region - should just show country name.
  XCTAssertEqualObjects(@"Estados Unidos", [self.geocoder descriptionForNumber:self.US_NUMBER2
                                                              withLanguageCode:@"es"
                                                                withUserRegion:@"ZZ"]);
  // User in the States, language German, should show detailed data.
  XCTAssertEqualObjects(@"Vereinigte Staaten", [self.geocoder descriptionForNumber:self.US_NUMBER2
                                                                  withLanguageCode:@"de"
                                                                    withUserRegion:@"US"]);
  //     User in the States, language French, no data for French, so we fallback to English detailed
  // data.
  XCTAssertEqualObjects(@"Australia", [self.geocoder descriptionForNumber:self.AU_NUMBER
                                                           withUserRegion:@"US"]);
  // An invalid phone number is expected to return nil
  XCTAssertEqualObjects(nil, [self.geocoder descriptionForNumber:self.US_INVALID_NUMBER
                                                withLanguageCode:@"en"
                                                  withUserRegion:@"US"]);
}

- (void)testConvenienceGetDescriptionForInvalidNumber {
  XCTAssertEqualObjects(nil, [self.geocoder descriptionForNumber:self.KO_INVALID_NUMBER]);
  XCTAssertEqualObjects(nil, [self.geocoder descriptionForNumber:self.US_INVALID_NUMBER]);
}

- (void)testConvenienceGetDescriptionForNonGeographicalNumber {
  // This phone number should return the country name rather than searching for a region description
  // since the phone number is nongeographical.
  XCTAssertEqualObjects(@"South Korea", [self.geocoder descriptionForNumber:self.KO_MOBILE]);
}

- (void)testPerformanceExample {
  // This is an example of a performance test case.
  [self measureBlock:^{
      // Put the code you want to measure the time of here.
  }];
}

@end
