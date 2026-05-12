#import <XCTest/XCTest.h>

#import "NBPhoneNumber.h"
#import "NBPhoneNumberToTimeZonesMapper.h"

@interface NBPhoneNumberToTimeZonesMapperTest : XCTestCase
@end

@implementation NBPhoneNumberToTimeZonesMapperTest {
 @private
  NBPhoneNumberToTimeZonesMapper *_mapper;
}

- (void)setUp {
  [super setUp];
  _mapper = [NBPhoneNumberToTimeZonesMapper sharedInstance];
}

- (NBPhoneNumber *)numberWithCountryCode:(NSNumber *)countryCode
                          nationalNumber:(NSNumber *)nationalNumber {
  NBPhoneNumber *number = [[NBPhoneNumber alloc] init];
  number.countryCode = countryCode;
  number.nationalNumber = nationalNumber;
  return number;
}

- (void)testTimeZonesForValidGeographicalNumbers {
  XCTAssertEqualObjects(@[ @"Australia/Sydney" ],
                        [_mapper timeZonesForNumber:[self numberWithCountryCode:@61
                                                                  nationalNumber:@236618300]]);
  XCTAssertEqualObjects(@[ @"Asia/Seoul" ],
                        [_mapper timeZonesForNumber:[self numberWithCountryCode:@82
                                                                  nationalNumber:@22123456]]);
  XCTAssertEqualObjects(@[ @"America/Vancouver" ],
                        [_mapper timeZonesForNumber:[self numberWithCountryCode:@1
                                                                  nationalNumber:@6048406565]]);
  XCTAssertEqualObjects(@[ @"America/Los_Angeles" ],
                        [_mapper timeZonesForNumber:[self numberWithCountryCode:@1
                                                                  nationalNumber:@6509600000]]);
  XCTAssertEqualObjects(@[ @"America/New_York" ],
                        [_mapper timeZonesForNumber:[self numberWithCountryCode:@1
                                                                  nationalNumber:@2128120000]]);
}

- (void)testInvalidNumbersReturnUnknownForCheckedLookup {
  XCTAssertEqualObjects(@[ [NBPhoneNumberToTimeZonesMapper unknownTimeZone] ],
                        [_mapper timeZonesForNumber:[self numberWithCountryCode:@1
                                                                  nationalNumber:@123456789]]);
  XCTAssertEqualObjects(@[ [NBPhoneNumberToTimeZonesMapper unknownTimeZone] ],
                        [_mapper timeZonesForNumber:[self numberWithCountryCode:@82
                                                                  nationalNumber:@1234]]);
  XCTAssertEqualObjects(@[ [NBPhoneNumberToTimeZonesMapper unknownTimeZone] ],
                        [_mapper timeZonesForNumber:[self numberWithCountryCode:@999
                                                                  nationalNumber:@2423651234]]);
}

- (void)testGeographicalLookupFallsBackToCountryLevelPrefix {
  NSArray<NSString *> *nanpaTimeZones =
      [_mapper timeZonesForGeographicalNumber:[self numberWithCountryCode:@1
                                                            nationalNumber:@123456789]];
  XCTAssertTrue([nanpaTimeZones containsObject:@"America/Los_Angeles"]);
  XCTAssertTrue([nanpaTimeZones containsObject:@"America/New_York"]);

  XCTAssertEqualObjects(@[ @"Asia/Seoul" ],
                        [_mapper timeZonesForGeographicalNumber:
                                     [self numberWithCountryCode:@82 nationalNumber:@1234]]);
}

- (void)testNonGeographicalNumbersReturnUnknownWhenCountryLevelMetadataIsMissing {
  XCTAssertEqualObjects(@[ [NBPhoneNumberToTimeZonesMapper unknownTimeZone] ],
                        [_mapper timeZonesForNumber:[self numberWithCountryCode:@800
                                                                  nationalNumber:@12345678]]);
}

@end
