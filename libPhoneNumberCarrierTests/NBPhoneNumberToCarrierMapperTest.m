#import <XCTest/XCTest.h>

#import "NBPhoneNumber.h"
#import "NBPhoneNumberToCarrierMapper.h"
@interface NBPhoneNumberToCarrierMapperTest : XCTestCase
@end

@implementation NBPhoneNumberToCarrierMapperTest {
 @private
  NBPhoneNumberToCarrierMapper *_mapper;
}

- (void)setUp {
  [super setUp];
  _mapper = [NBPhoneNumberToCarrierMapper sharedInstance];
}

- (NBPhoneNumber *)numberWithCountryCode:(NSNumber *)countryCode
                          nationalNumber:(NSNumber *)nationalNumber {
  NBPhoneNumber *number = [[NBPhoneNumber alloc] init];
  number.countryCode = countryCode;
  number.nationalNumber = nationalNumber;
  return number;
}

- (void)testGetNameForNumber {
  XCTAssertEqualObjects(@"Movicel",
                        [_mapper nameForNumber:[self numberWithCountryCode:@244
                                                             nationalNumber:@917654321]
                                    localeCode:@"en"]);
  XCTAssertEqualObjects(@"Vodafone",
                        [_mapper nameForNumber:[self numberWithCountryCode:@44
                                                             nationalNumber:@7387654321]
                                    localeCode:@"en"]);
}

- (void)testGetNameForValidNumberCanReturnFixedLineMetadata {
  XCTAssertEqualObjects(@"KT",
                        [_mapper nameForValidNumber:[self numberWithCountryCode:@82
                                                                  nationalNumber:@1025123456]
                                         localeCode:@"ko"]);
}

- (void)testGetNameForNumberIgnoresFixedLineAndInvalidNumbers {
  XCTAssertEqualObjects(@"",
                        [_mapper nameForNumber:[self numberWithCountryCode:@44
                                                             nationalNumber:@1123456789]
                                    localeCode:@"en"]);
  XCTAssertEqualObjects(@"",
                        [_mapper nameForNumber:[self numberWithCountryCode:@999
                                                             nationalNumber:@2423651234]
                                    localeCode:@"en"]);
}

- (void)testLocaleFallback {
  XCTAssertEqualObjects(@"Vodafone",
                        [_mapper nameForNumber:[self numberWithCountryCode:@44
                                                             nationalNumber:@7387654321]
                                    localeCode:@"fr"]);
  XCTAssertEqualObjects(@"",
                        [_mapper nameForNumber:[self numberWithCountryCode:@44
                                                             nationalNumber:@7387654321]
                                    localeCode:@"ko"]);
}

- (void)testSafeDisplayNameHonorsMobileNumberPortability {
  XCTAssertEqualObjects(@"",
                        [_mapper safeDisplayNameForNumber:[self numberWithCountryCode:@44
                                                                    nationalNumber:@7387654321]
                                               localeCode:@"en"]);
  XCTAssertEqualObjects(@"Movicel",
                        [_mapper safeDisplayNameForNumber:[self numberWithCountryCode:@244
                                                                    nationalNumber:@917654321]
                                               localeCode:@"en"]);
}

@end
