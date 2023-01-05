//
//  NBAsYouTypeFormatterTest.m
//  libPhoneNumber
//
//  Created by ishtar on 13. 3. 5..
//

#import <XCTest/XCTest.h>
#import "NBAsYouTypeFormatter.h"
#import "NBMetadataHelper.h"
#import "NBPhoneNumberUtil.h"

#import "NBTestingMetaData.h"

@interface NBAsYouTypeFormatterTest : XCTestCase
@end

@implementation NBAsYouTypeFormatterTest {
 @private
  NBMetadataHelper *_helper;
}

- (void)setUp {
  [super setUp];

  NSBundle *bundle = [NSBundle bundleForClass:[self class]];
  NSString *path = [bundle pathForResource:@"libPhoneNumberMetadataForTesting" ofType:nil];
  NSData *data = [NSData dataWithContentsOfFile:path];
  _helper =
      [[NBMetadataHelper alloc] initWithZippedData:data
                                    expandedLength:kPhoneNumberMetaDataForTestingExpandedLength];
}

- (void)testInvalidRegion {
  NBAsYouTypeFormatter *f = [[NBAsYouTypeFormatter alloc] initWithRegionCode:NB_UNKNOWN_REGION
                                                              metadataHelper:_helper];
  XCTAssertEqualObjects(@"+", [f inputDigit:@"+"]);
  XCTAssertEqualObjects(@"+4", [f inputDigit:@"4"]);
  XCTAssertEqualObjects(@"+48 ", [f inputDigit:@"8"]);
  XCTAssertEqualObjects(@"+48 8", [f inputDigit:@"8"]);
  XCTAssertEqualObjects(@"+48 88", [f inputDigit:@"8"]);
  XCTAssertEqualObjects(@"+48 88 1", [f inputDigit:@"1"]);
  XCTAssertEqualObjects(@"+48 88 12", [f inputDigit:@"2"]);
  XCTAssertEqualObjects(@"+48 88 123", [f inputDigit:@"3"]);
  XCTAssertEqualObjects(@"+48 88 123 1", [f inputDigit:@"1"]);
  XCTAssertEqualObjects(@"+48 88 123 12", [f inputDigit:@"2"]);

  [f clear];
  XCTAssertEqualObjects(@"6", [f inputDigit:@"6"]);
  XCTAssertEqualObjects(@"65", [f inputDigit:@"5"]);
  XCTAssertEqualObjects(@"650", [f inputDigit:@"0"]);
  XCTAssertEqualObjects(@"6502", [f inputDigit:@"2"]);
  XCTAssertEqualObjects(@"65025", [f inputDigit:@"5"]);
  XCTAssertEqualObjects(@"650253", [f inputDigit:@"3"]);
}

- (void)testInvalidPlusSign {
  NBAsYouTypeFormatter *f = [[NBAsYouTypeFormatter alloc] initWithRegionCode:NB_UNKNOWN_REGION
                                                              metadataHelper:_helper];
  XCTAssertEqualObjects(@"+", [f inputDigit:@"+"]);
  XCTAssertEqualObjects(@"+4", [f inputDigit:@"4"]);
  XCTAssertEqualObjects(@"+48 ", [f inputDigit:@"8"]);
  XCTAssertEqualObjects(@"+48 8", [f inputDigit:@"8"]);
  XCTAssertEqualObjects(@"+48 88", [f inputDigit:@"8"]);
  XCTAssertEqualObjects(@"+48 88 1", [f inputDigit:@"1"]);
  XCTAssertEqualObjects(@"+48 88 12", [f inputDigit:@"2"]);
  XCTAssertEqualObjects(@"+48 88 123", [f inputDigit:@"3"]);
  XCTAssertEqualObjects(@"+48 88 123 1", [f inputDigit:@"1"]);
  // A plus sign can only appear at the beginning of the number;
  // otherwise, no formatting is applied.
  XCTAssertEqualObjects(@"+48881231+", [f inputDigit:@"+"]);
  XCTAssertEqualObjects(@"+48881231+2", [f inputDigit:@"2"]);

  XCTAssertEqualObjects(@"+48881231+", [f removeLastDigit]);
  XCTAssertEqualObjects(@"+48 88 123 1", [f removeLastDigit]);
  XCTAssertEqualObjects(@"+48 88 123", [f removeLastDigit]);
  XCTAssertEqualObjects(@"+48 88 12", [f removeLastDigit]);
  XCTAssertEqualObjects(@"+48 88 1", [f removeLastDigit]);
  XCTAssertEqualObjects(@"+48 88", [f removeLastDigit]);
  XCTAssertEqualObjects(@"+48 8", [f removeLastDigit]);
  XCTAssertEqualObjects(@"+48 ", [f removeLastDigit]);
  XCTAssertEqualObjects(@"+4", [f removeLastDigit]);
  XCTAssertEqualObjects(@"+", [f removeLastDigit]);
  XCTAssertEqualObjects(@"", [f removeLastDigit]);
}

- (void)testTooLongNumberMatchingMultipleLeadingDigits {
  // See http://code.google.com/p/libphonenumber/issues/detail?id=36
  // The bug occurred last time for countries which have two formatting rules
  // with exactly the same leading digits pattern but differ in length.
  NBAsYouTypeFormatter *f = [[NBAsYouTypeFormatter alloc] initWithRegionCode:NB_UNKNOWN_REGION
                                                              metadataHelper:_helper];
  XCTAssertEqualObjects(@"+", [f inputDigit:@"+"]);
  XCTAssertEqualObjects(@"+8", [f inputDigit:@"8"]);
  XCTAssertEqualObjects(@"+81 ", [f inputDigit:@"1"]);
  XCTAssertEqualObjects(@"+81 9", [f inputDigit:@"9"]);
  XCTAssertEqualObjects(@"+81 90", [f inputDigit:@"0"]);
  XCTAssertEqualObjects(@"+81 90 1", [f inputDigit:@"1"]);
  XCTAssertEqualObjects(@"+81 90 12", [f inputDigit:@"2"]);
  XCTAssertEqualObjects(@"+81 90 123", [f inputDigit:@"3"]);
  XCTAssertEqualObjects(@"+81 90 1234", [f inputDigit:@"4"]);
  XCTAssertEqualObjects(@"+81 90 1234 5", [f inputDigit:@"5"]);
  XCTAssertEqualObjects(@"+81 90 1234 56", [f inputDigit:@"6"]);
  XCTAssertEqualObjects(@"+81 90 1234 567", [f inputDigit:@"7"]);
  XCTAssertEqualObjects(@"+81 90 1234 5678", [f inputDigit:@"8"]);
  XCTAssertEqualObjects(@"+81 90 12 345 6789", [f inputDigit:@"9"]);
  XCTAssertEqualObjects(@"+81901234567890", [f inputDigit:@"0"]);
  XCTAssertEqualObjects(@"+819012345678901", [f inputDigit:@"1"]);
}

- (void)testCountryWithSpaceInNationalPrefixFormattingRule {
  NBAsYouTypeFormatter *f = [[NBAsYouTypeFormatter alloc] initWithRegionCode:@"BY"
                                                              metadataHelper:_helper];
  XCTAssertEqualObjects(@"8", [f inputDigit:@"8"]);
  XCTAssertEqualObjects(@"88", [f inputDigit:@"8"]);
  XCTAssertEqualObjects(@"881", [f inputDigit:@"1"]);
  XCTAssertEqualObjects(@"8 819", [f inputDigit:@"9"]);
  XCTAssertEqualObjects(@"8 8190", [f inputDigit:@"0"]);
  // The formatting rule for 5 digit numbers states that no space should be
  // present after the national prefix.
  XCTAssertEqualObjects(@"881 901", [f inputDigit:@"1"]);
  XCTAssertEqualObjects(@"8 819 012", [f inputDigit:@"2"]);
  // Too long, no formatting rule applies.
  XCTAssertEqualObjects(@"88190123", [f inputDigit:@"3"]);
}

- (void)testCountryWithSpaceInNationalPrefixFormattingRuleAndLongNdd {
  NBAsYouTypeFormatter *f = [[NBAsYouTypeFormatter alloc] initWithRegionCode:@"BY"
                                                              metadataHelper:_helper];
  XCTAssertEqualObjects(@"9", [f inputDigit:@"9"]);
  XCTAssertEqualObjects(@"99", [f inputDigit:@"9"]);
  XCTAssertEqualObjects(@"999", [f inputDigit:@"9"]);
  XCTAssertEqualObjects(@"9999", [f inputDigit:@"9"]);
  XCTAssertEqualObjects(@"99999 ", [f inputDigit:@"9"]);
  XCTAssertEqualObjects(@"99999 1", [f inputDigit:@"1"]);
  XCTAssertEqualObjects(@"99999 12", [f inputDigit:@"2"]);
  XCTAssertEqualObjects(@"99999 123", [f inputDigit:@"3"]);
  XCTAssertEqualObjects(@"99999 1234", [f inputDigit:@"4"]);
  XCTAssertEqualObjects(@"99999 12 345", [f inputDigit:@"5"]);
}

- (void)testAYTFUS {
  NBAsYouTypeFormatter *f = [[NBAsYouTypeFormatter alloc] initWithRegionCode:@"US"
                                                              metadataHelper:_helper];
  XCTAssertEqualObjects(@"6", [f inputDigit:@"6"]);
  XCTAssertEqualObjects(@"65", [f inputDigit:@"5"]);
  XCTAssertEqualObjects(@"650", [f inputDigit:@"0"]);
  XCTAssertEqualObjects(@"650 2", [f inputDigit:@"2"]);
  XCTAssertEqualObjects(@"650 25", [f inputDigit:@"5"]);
  XCTAssertEqualObjects(@"650 253", [f inputDigit:@"3"]);
  // Note this is how a US local number (without area code) should be formatted.
  XCTAssertEqualObjects(@"650 2532", [f inputDigit:@"2"]);
  XCTAssertEqualObjects(@"650 253 22", [f inputDigit:@"2"]);
  XCTAssertEqualObjects(@"650 253 222", [f inputDigit:@"2"]);
  XCTAssertEqualObjects(@"650 253 2222", [f inputDigit:@"2"]);

  [f clear];
  XCTAssertEqualObjects(@"1", [f inputDigit:@"1"]);
  XCTAssertEqualObjects(@"16", [f inputDigit:@"6"]);
  XCTAssertEqualObjects(@"1 65", [f inputDigit:@"5"]);
  XCTAssertEqualObjects(@"1 650", [f inputDigit:@"0"]);
  XCTAssertEqualObjects(@"1 650 2", [f inputDigit:@"2"]);
  XCTAssertEqualObjects(@"1 650 25", [f inputDigit:@"5"]);
  XCTAssertEqualObjects(@"1 650 253", [f inputDigit:@"3"]);
  XCTAssertEqualObjects(@"1 650 253 2", [f inputDigit:@"2"]);
  XCTAssertEqualObjects(@"1 650 253 22", [f inputDigit:@"2"]);
  XCTAssertEqualObjects(@"1 650 253 222", [f inputDigit:@"2"]);
  XCTAssertEqualObjects(@"1 650 253 2222", [f inputDigit:@"2"]);

  [f clear];
  XCTAssertEqualObjects(@"0", [f inputDigit:@"0"]);
  XCTAssertEqualObjects(@"01", [f inputDigit:@"1"]);
  XCTAssertEqualObjects(@"011 ", [f inputDigit:@"1"]);
  XCTAssertEqualObjects(@"011 4", [f inputDigit:@"4"]);
  XCTAssertEqualObjects(@"011 44 ", [f inputDigit:@"4"]);
  XCTAssertEqualObjects(@"011 44 6", [f inputDigit:@"6"]);
  XCTAssertEqualObjects(@"011 44 61", [f inputDigit:@"1"]);
  XCTAssertEqualObjects(@"011 44 6 12", [f inputDigit:@"2"]);
  XCTAssertEqualObjects(@"011 44 6 123", [f inputDigit:@"3"]);
  XCTAssertEqualObjects(@"011 44 6 123 1", [f inputDigit:@"1"]);
  XCTAssertEqualObjects(@"011 44 6 123 12", [f inputDigit:@"2"]);
  XCTAssertEqualObjects(@"011 44 6 123 123", [f inputDigit:@"3"]);
  XCTAssertEqualObjects(@"011 44 6 123 123 1", [f inputDigit:@"1"]);
  XCTAssertEqualObjects(@"011 44 6 123 123 12", [f inputDigit:@"2"]);
  XCTAssertEqualObjects(@"011 44 6 123 123 123", [f inputDigit:@"3"]);

  [f clear];
  XCTAssertEqualObjects(@"0", [f inputDigit:@"0"]);
  XCTAssertEqualObjects(@"01", [f inputDigit:@"1"]);
  XCTAssertEqualObjects(@"011 ", [f inputDigit:@"1"]);
  XCTAssertEqualObjects(@"011 5", [f inputDigit:@"5"]);
  XCTAssertEqualObjects(@"011 54 ", [f inputDigit:@"4"]);
  XCTAssertEqualObjects(@"011 54 9", [f inputDigit:@"9"]);
  XCTAssertEqualObjects(@"011 54 91", [f inputDigit:@"1"]);
  XCTAssertEqualObjects(@"011 54 9 11", [f inputDigit:@"1"]);
  XCTAssertEqualObjects(@"011 54 9 11 2", [f inputDigit:@"2"]);
  XCTAssertEqualObjects(@"011 54 9 11 23", [f inputDigit:@"3"]);
  XCTAssertEqualObjects(@"011 54 9 11 231", [f inputDigit:@"1"]);
  XCTAssertEqualObjects(@"011 54 9 11 2312", [f inputDigit:@"2"]);
  XCTAssertEqualObjects(@"011 54 9 11 2312 1", [f inputDigit:@"1"]);
  XCTAssertEqualObjects(@"011 54 9 11 2312 12", [f inputDigit:@"2"]);
  XCTAssertEqualObjects(@"011 54 9 11 2312 123", [f inputDigit:@"3"]);
  XCTAssertEqualObjects(@"011 54 9 11 2312 1234", [f inputDigit:@"4"]);

  [f clear];
  XCTAssertEqualObjects(@"0", [f inputDigit:@"0"]);
  XCTAssertEqualObjects(@"01", [f inputDigit:@"1"]);
  XCTAssertEqualObjects(@"011 ", [f inputDigit:@"1"]);
  XCTAssertEqualObjects(@"011 2", [f inputDigit:@"2"]);
  XCTAssertEqualObjects(@"011 24", [f inputDigit:@"4"]);
  XCTAssertEqualObjects(@"011 244 ", [f inputDigit:@"4"]);
  XCTAssertEqualObjects(@"011 244 2", [f inputDigit:@"2"]);
  XCTAssertEqualObjects(@"011 244 28", [f inputDigit:@"8"]);
  XCTAssertEqualObjects(@"011 244 280", [f inputDigit:@"0"]);
  XCTAssertEqualObjects(@"011 244 280 0", [f inputDigit:@"0"]);
  XCTAssertEqualObjects(@"011 244 280 00", [f inputDigit:@"0"]);
  XCTAssertEqualObjects(@"011 244 280 000", [f inputDigit:@"0"]);
  XCTAssertEqualObjects(@"011 244 280 000 0", [f inputDigit:@"0"]);
  XCTAssertEqualObjects(@"011 244 280 000 00", [f inputDigit:@"0"]);
  XCTAssertEqualObjects(@"011 244 280 000 000", [f inputDigit:@"0"]);

  [f clear];
  XCTAssertEqualObjects(@"+", [f inputDigit:@"+"]);
  XCTAssertEqualObjects(@"+4", [f inputDigit:@"4"]);
  XCTAssertEqualObjects(@"+48 ", [f inputDigit:@"8"]);
  XCTAssertEqualObjects(@"+48 8", [f inputDigit:@"8"]);
  XCTAssertEqualObjects(@"+48 88", [f inputDigit:@"8"]);
  XCTAssertEqualObjects(@"+48 88 1", [f inputDigit:@"1"]);
  XCTAssertEqualObjects(@"+48 88 12", [f inputDigit:@"2"]);
  XCTAssertEqualObjects(@"+48 88 123", [f inputDigit:@"3"]);
  XCTAssertEqualObjects(@"+48 88 123 1", [f inputDigit:@"1"]);
  XCTAssertEqualObjects(@"+48 88 123 12", [f inputDigit:@"2"]);
  XCTAssertEqualObjects(@"+48 88 123 12 1", [f inputDigit:@"1"]);
  XCTAssertEqualObjects(@"+48 88 123 12 12", [f inputDigit:@"2"]);
}

- (void)testAYTFUSFullWidthCharacters {
  NBAsYouTypeFormatter *f = [[NBAsYouTypeFormatter alloc] initWithRegionCode:@"US"
                                                              metadataHelper:_helper];
  XCTAssertEqualObjects(@"\uFF16", [f inputDigit:@"\uFF16"]);
  XCTAssertEqualObjects(@"\uFF16\uFF15", [f inputDigit:@"\uFF15"]);
  XCTAssertEqualObjects(@"650", [f inputDigit:@"\uFF10"]);
  XCTAssertEqualObjects(@"650 2", [f inputDigit:@"\uFF12"]);
  XCTAssertEqualObjects(@"650 25", [f inputDigit:@"\uFF15"]);
  XCTAssertEqualObjects(@"650 253", [f inputDigit:@"\uFF13"]);
  XCTAssertEqualObjects(@"650 2532", [f inputDigit:@"\uFF12"]);
  XCTAssertEqualObjects(@"650 253 22", [f inputDigit:@"\uFF12"]);
  XCTAssertEqualObjects(@"650 253 222", [f inputDigit:@"\uFF12"]);
  XCTAssertEqualObjects(@"650 253 2222", [f inputDigit:@"\uFF12"]);
}

- (void)testAYTFUSMobileShortCode {
  NBAsYouTypeFormatter *f = [[NBAsYouTypeFormatter alloc] initWithRegionCode:@"US"
                                                              metadataHelper:_helper];
  XCTAssertEqualObjects(@"*", [f inputDigit:@"*"]);
  XCTAssertEqualObjects(@"*1", [f inputDigit:@"1"]);
  XCTAssertEqualObjects(@"*12", [f inputDigit:@"2"]);
  XCTAssertEqualObjects(@"*121", [f inputDigit:@"1"]);
  XCTAssertEqualObjects(@"*121#", [f inputDigit:@"#"]);
}

- (void)testAYTFUSVanityNumber {
  NBAsYouTypeFormatter *f = [[NBAsYouTypeFormatter alloc] initWithRegionCode:@"US"
                                                              metadataHelper:_helper];
  XCTAssertEqualObjects(@"8", [f inputDigit:@"8"]);
  XCTAssertEqualObjects(@"80", [f inputDigit:@"0"]);
  XCTAssertEqualObjects(@"800", [f inputDigit:@"0"]);
  XCTAssertEqualObjects(@"800 ", [f inputDigit:@" "]);
  XCTAssertEqualObjects(@"800 M", [f inputDigit:@"M"]);
  XCTAssertEqualObjects(@"800 MY", [f inputDigit:@"Y"]);
  XCTAssertEqualObjects(@"800 MY ", [f inputDigit:@" "]);
  XCTAssertEqualObjects(@"800 MY A", [f inputDigit:@"A"]);
  XCTAssertEqualObjects(@"800 MY AP", [f inputDigit:@"P"]);
  XCTAssertEqualObjects(@"800 MY APP", [f inputDigit:@"P"]);
  XCTAssertEqualObjects(@"800 MY APPL", [f inputDigit:@"L"]);
  XCTAssertEqualObjects(@"800 MY APPLE", [f inputDigit:@"E"]);
}

- (void)testAYTFAndRememberPositionUS {
  NBAsYouTypeFormatter *f = [[NBAsYouTypeFormatter alloc] initWithRegionCode:@"US"
                                                              metadataHelper:_helper];
  XCTAssertEqualObjects(@"1", [f inputDigitAndRememberPosition:@"1"]);
  XCTAssertEqual(1, [f getRememberedPosition]);
  XCTAssertEqualObjects(@"16", [f inputDigit:@"6"]);
  XCTAssertEqualObjects(@"1 65", [f inputDigit:@"5"]);
  XCTAssertEqual(1, [f getRememberedPosition]);
  XCTAssertEqualObjects(@"1 650", [f inputDigitAndRememberPosition:@"0"]);
  XCTAssertEqual(5, [f getRememberedPosition]);
  XCTAssertEqualObjects(@"1 650 2", [f inputDigit:@"2"]);
  XCTAssertEqualObjects(@"1 650 25", [f inputDigit:@"5"]);
  // Note the remembered position for digit '0' changes from 4 to 5, because a
  // space is now inserted in the front.
  XCTAssertEqual(5, [f getRememberedPosition]);
  XCTAssertEqualObjects(@"1 650 253", [f inputDigit:@"3"]);
  XCTAssertEqualObjects(@"1 650 253 2", [f inputDigit:@"2"]);
  XCTAssertEqualObjects(@"1 650 253 22", [f inputDigit:@"2"]);
  XCTAssertEqual(5, [f getRememberedPosition]);
  XCTAssertEqualObjects(@"1 650 253 222", [f inputDigitAndRememberPosition:@"2"]);
  XCTAssertEqual(13, [f getRememberedPosition]);
  XCTAssertEqualObjects(@"1 650 253 2222", [f inputDigit:@"2"]);
  XCTAssertEqual(13, [f getRememberedPosition]);
  XCTAssertEqualObjects(@"165025322222", [f inputDigit:@"2"]);
  XCTAssertEqual(10, [f getRememberedPosition]);
  XCTAssertEqualObjects(@"1650253222222", [f inputDigit:@"2"]);
  XCTAssertEqual(10, [f getRememberedPosition]);

  [f clear];
  XCTAssertEqualObjects(@"1", [f inputDigit:@"1"]);
  XCTAssertEqualObjects(@"16", [f inputDigitAndRememberPosition:@"6"]);
  XCTAssertEqual(2, [f getRememberedPosition]);
  XCTAssertEqualObjects(@"1 65", [f inputDigit:@"5"]);
  XCTAssertEqualObjects(@"1 650", [f inputDigit:@"0"]);
  XCTAssertEqual(3, [f getRememberedPosition]);
  XCTAssertEqualObjects(@"1 650 2", [f inputDigit:@"2"]);
  XCTAssertEqualObjects(@"1 650 25", [f inputDigit:@"5"]);
  XCTAssertEqual(3, [f getRememberedPosition]);
  XCTAssertEqualObjects(@"1 650 253", [f inputDigit:@"3"]);
  XCTAssertEqualObjects(@"1 650 253 2", [f inputDigit:@"2"]);
  XCTAssertEqualObjects(@"1 650 253 22", [f inputDigit:@"2"]);
  XCTAssertEqual(3, [f getRememberedPosition]);
  XCTAssertEqualObjects(@"1 650 253 222", [f inputDigit:@"2"]);
  XCTAssertEqualObjects(@"1 650 253 2222", [f inputDigit:@"2"]);
  XCTAssertEqualObjects(@"165025322222", [f inputDigit:@"2"]);
  XCTAssertEqual(2, [f getRememberedPosition]);
  XCTAssertEqualObjects(@"1650253222222", [f inputDigit:@"2"]);
  XCTAssertEqual(2, [f getRememberedPosition]);

  [f clear];
  XCTAssertEqualObjects(@"6", [f inputDigit:@"6"]);
  XCTAssertEqualObjects(@"65", [f inputDigit:@"5"]);
  XCTAssertEqualObjects(@"650", [f inputDigit:@"0"]);
  XCTAssertEqualObjects(@"650 2", [f inputDigit:@"2"]);
  XCTAssertEqualObjects(@"650 25", [f inputDigit:@"5"]);
  XCTAssertEqualObjects(@"650 253", [f inputDigit:@"3"]);
  XCTAssertEqualObjects(@"650 2532", [f inputDigitAndRememberPosition:@"2"]);
  XCTAssertEqual(8, [f getRememberedPosition]);
  XCTAssertEqualObjects(@"650 253 22", [f inputDigit:@"2"]);
  XCTAssertEqual(9, [f getRememberedPosition]);
  XCTAssertEqualObjects(@"650 253 222", [f inputDigit:@"2"]);
  // No more formatting when semicolon is entered.
  XCTAssertEqualObjects(@"650253222;", [f inputDigit:@";"]);
  XCTAssertEqual(7, [f getRememberedPosition]);
  XCTAssertEqualObjects(@"650253222;2", [f inputDigit:@"2"]);

  [f clear];
  XCTAssertEqualObjects(@"6", [f inputDigit:@"6"]);
  XCTAssertEqualObjects(@"65", [f inputDigit:@"5"]);
  XCTAssertEqualObjects(@"650", [f inputDigit:@"0"]);
  // No more formatting when users choose to do their own formatting.
  XCTAssertEqualObjects(@"650-", [f inputDigit:@"-"]);
  XCTAssertEqualObjects(@"650-2", [f inputDigitAndRememberPosition:@"2"]);
  XCTAssertEqual(5, [f getRememberedPosition]);
  XCTAssertEqualObjects(@"650-25", [f inputDigit:@"5"]);
  XCTAssertEqual(5, [f getRememberedPosition]);
  XCTAssertEqualObjects(@"650-253", [f inputDigit:@"3"]);
  XCTAssertEqual(5, [f getRememberedPosition]);
  XCTAssertEqualObjects(@"650-253-", [f inputDigit:@"-"]);
  XCTAssertEqualObjects(@"650-253-2", [f inputDigit:@"2"]);
  XCTAssertEqualObjects(@"650-253-22", [f inputDigit:@"2"]);
  XCTAssertEqualObjects(@"650-253-222", [f inputDigit:@"2"]);
  XCTAssertEqualObjects(@"650-253-2222", [f inputDigit:@"2"]);

  [f clear];
  XCTAssertEqualObjects(@"0", [f inputDigit:@"0"]);
  XCTAssertEqualObjects(@"01", [f inputDigit:@"1"]);
  XCTAssertEqualObjects(@"011 ", [f inputDigit:@"1"]);
  XCTAssertEqualObjects(@"011 4", [f inputDigitAndRememberPosition:@"4"]);
  XCTAssertEqualObjects(@"011 48 ", [f inputDigit:@"8"]);
  XCTAssertEqual(5, [f getRememberedPosition]);
  XCTAssertEqualObjects(@"011 48 8", [f inputDigit:@"8"]);
  XCTAssertEqual(5, [f getRememberedPosition]);
  XCTAssertEqualObjects(@"011 48 88", [f inputDigit:@"8"]);
  XCTAssertEqualObjects(@"011 48 88 1", [f inputDigit:@"1"]);
  XCTAssertEqualObjects(@"011 48 88 12", [f inputDigit:@"2"]);
  XCTAssertEqual(5, [f getRememberedPosition]);
  XCTAssertEqualObjects(@"011 48 88 123", [f inputDigit:@"3"]);
  XCTAssertEqualObjects(@"011 48 88 123 1", [f inputDigit:@"1"]);
  XCTAssertEqualObjects(@"011 48 88 123 12", [f inputDigit:@"2"]);
  XCTAssertEqualObjects(@"011 48 88 123 12 1", [f inputDigit:@"1"]);
  XCTAssertEqualObjects(@"011 48 88 123 12 12", [f inputDigit:@"2"]);

  [f clear];
  XCTAssertEqualObjects(@"+", [f inputDigit:@"+"]);
  XCTAssertEqualObjects(@"+1", [f inputDigit:@"1"]);
  XCTAssertEqualObjects(@"+1 6", [f inputDigitAndRememberPosition:@"6"]);
  XCTAssertEqualObjects(@"+1 65", [f inputDigit:@"5"]);
  XCTAssertEqualObjects(@"+1 650", [f inputDigit:@"0"]);
  XCTAssertEqual(4, [f getRememberedPosition]);
  XCTAssertEqualObjects(@"+1 650 2", [f inputDigit:@"2"]);
  XCTAssertEqual(4, [f getRememberedPosition]);
  XCTAssertEqualObjects(@"+1 650 25", [f inputDigit:@"5"]);
  XCTAssertEqualObjects(@"+1 650 253", [f inputDigitAndRememberPosition:@"3"]);
  XCTAssertEqualObjects(@"+1 650 253 2", [f inputDigit:@"2"]);
  XCTAssertEqualObjects(@"+1 650 253 22", [f inputDigit:@"2"]);
  XCTAssertEqualObjects(@"+1 650 253 222", [f inputDigit:@"2"]);
  XCTAssertEqual(10, [f getRememberedPosition]);

  [f clear];
  XCTAssertEqualObjects(@"+", [f inputDigit:@"+"]);
  XCTAssertEqualObjects(@"+1", [f inputDigit:@"1"]);
  XCTAssertEqualObjects(@"+1 6", [f inputDigitAndRememberPosition:@"6"]);
  XCTAssertEqualObjects(@"+1 65", [f inputDigit:@"5"]);
  XCTAssertEqualObjects(@"+1 650", [f inputDigit:@"0"]);
  XCTAssertEqual(4, [f getRememberedPosition]);
  XCTAssertEqualObjects(@"+1 650 2", [f inputDigit:@"2"]);
  XCTAssertEqual(4, [f getRememberedPosition]);
  XCTAssertEqualObjects(@"+1 650 25", [f inputDigit:@"5"]);
  XCTAssertEqualObjects(@"+1 650 253", [f inputDigit:@"3"]);
  XCTAssertEqualObjects(@"+1 650 253 2", [f inputDigit:@"2"]);
  XCTAssertEqualObjects(@"+1 650 253 22", [f inputDigit:@"2"]);
  XCTAssertEqualObjects(@"+1 650 253 222", [f inputDigit:@"2"]);
  XCTAssertEqualObjects(@"+1650253222;", [f inputDigit:@";"]);
  XCTAssertEqual(3, [f getRememberedPosition]);
}

- (void)testAYTFGBFixedLine {
  NBAsYouTypeFormatter *f = [[NBAsYouTypeFormatter alloc] initWithRegionCode:@"GB"
                                                              metadataHelper:_helper];
  XCTAssertEqualObjects(@"0", [f inputDigit:@"0"]);
  XCTAssertEqualObjects(@"02", [f inputDigit:@"2"]);
  XCTAssertEqualObjects(@"020", [f inputDigit:@"0"]);
  XCTAssertEqualObjects(@"020 7", [f inputDigitAndRememberPosition:@"7"]);
  XCTAssertEqual(5, [f getRememberedPosition]);
  XCTAssertEqualObjects(@"020 70", [f inputDigit:@"0"]);
  XCTAssertEqualObjects(@"020 703", [f inputDigit:@"3"]);
  XCTAssertEqual(5, [f getRememberedPosition]);
  XCTAssertEqualObjects(@"020 7031", [f inputDigit:@"1"]);
  XCTAssertEqualObjects(@"020 7031 3", [f inputDigit:@"3"]);
  XCTAssertEqualObjects(@"020 7031 30", [f inputDigit:@"0"]);
  XCTAssertEqualObjects(@"020 7031 300", [f inputDigit:@"0"]);
  XCTAssertEqualObjects(@"020 7031 3000", [f inputDigit:@"0"]);
}

- (void)testAYTFGBTollFree {
  NBAsYouTypeFormatter *f = [[NBAsYouTypeFormatter alloc] initWithRegionCode:@"GB"
                                                              metadataHelper:_helper];
  XCTAssertEqualObjects(@"0", [f inputDigit:@"0"]);
  XCTAssertEqualObjects(@"08", [f inputDigit:@"8"]);
  XCTAssertEqualObjects(@"080", [f inputDigit:@"0"]);
  XCTAssertEqualObjects(@"080 7", [f inputDigit:@"7"]);
  XCTAssertEqualObjects(@"080 70", [f inputDigit:@"0"]);
  XCTAssertEqualObjects(@"080 703", [f inputDigit:@"3"]);
  XCTAssertEqualObjects(@"080 7031", [f inputDigit:@"1"]);
  XCTAssertEqualObjects(@"080 7031 3", [f inputDigit:@"3"]);
  XCTAssertEqualObjects(@"080 7031 30", [f inputDigit:@"0"]);
  XCTAssertEqualObjects(@"080 7031 300", [f inputDigit:@"0"]);
  XCTAssertEqualObjects(@"080 7031 3000", [f inputDigit:@"0"]);
}

- (void)testAYTFGBPremiumRate {
  NBAsYouTypeFormatter *f = [[NBAsYouTypeFormatter alloc] initWithRegionCode:@"GB"
                                                              metadataHelper:_helper];
  XCTAssertEqualObjects(@"0", [f inputDigit:@"0"]);
  XCTAssertEqualObjects(@"09", [f inputDigit:@"9"]);
  XCTAssertEqualObjects(@"090", [f inputDigit:@"0"]);
  XCTAssertEqualObjects(@"090 7", [f inputDigit:@"7"]);
  XCTAssertEqualObjects(@"090 70", [f inputDigit:@"0"]);
  XCTAssertEqualObjects(@"090 703", [f inputDigit:@"3"]);
  XCTAssertEqualObjects(@"090 7031", [f inputDigit:@"1"]);
  XCTAssertEqualObjects(@"090 7031 3", [f inputDigit:@"3"]);
  XCTAssertEqualObjects(@"090 7031 30", [f inputDigit:@"0"]);
  XCTAssertEqualObjects(@"090 7031 300", [f inputDigit:@"0"]);
  XCTAssertEqualObjects(@"090 7031 3000", [f inputDigit:@"0"]);
}

- (void)testAYTFNZMobile {
  NBAsYouTypeFormatter *f = [[NBAsYouTypeFormatter alloc] initWithRegionCode:@"NZ"
                                                              metadataHelper:_helper];
  XCTAssertEqualObjects(@"0", [f inputDigit:@"0"]);
  XCTAssertEqualObjects(@"02", [f inputDigit:@"2"]);
  XCTAssertEqualObjects(@"021", [f inputDigit:@"1"]);
  XCTAssertEqualObjects(@"02-11", [f inputDigit:@"1"]);
  XCTAssertEqualObjects(@"02-112", [f inputDigit:@"2"]);
  // Note the unittest is using fake metadata which might produce non-ideal
  // results.
  XCTAssertEqualObjects(@"02-112 3", [f inputDigit:@"3"]);
  XCTAssertEqualObjects(@"02-112 34", [f inputDigit:@"4"]);
  XCTAssertEqualObjects(@"02-112 345", [f inputDigit:@"5"]);
  XCTAssertEqualObjects(@"02-112 3456", [f inputDigit:@"6"]);
}

- (void)testAYTFDE {
  NBAsYouTypeFormatter *f = [[NBAsYouTypeFormatter alloc] initWithRegionCode:@"DE"
                                                              metadataHelper:_helper];
  XCTAssertEqualObjects(@"0", [f inputDigit:@"0"]);
  XCTAssertEqualObjects(@"03", [f inputDigit:@"3"]);
  XCTAssertEqualObjects(@"030", [f inputDigit:@"0"]);
  XCTAssertEqualObjects(@"030/1", [f inputDigit:@"1"]);
  XCTAssertEqualObjects(@"030/12", [f inputDigit:@"2"]);
  XCTAssertEqualObjects(@"030/123", [f inputDigit:@"3"]);
  XCTAssertEqualObjects(@"030/1234", [f inputDigit:@"4"]);

  // 04134 1234
  [f clear];
  XCTAssertEqualObjects(@"0", [f inputDigit:@"0"]);
  XCTAssertEqualObjects(@"04", [f inputDigit:@"4"]);
  XCTAssertEqualObjects(@"041", [f inputDigit:@"1"]);
  XCTAssertEqualObjects(@"041 3", [f inputDigit:@"3"]);
  XCTAssertEqualObjects(@"041 34", [f inputDigit:@"4"]);
  XCTAssertEqualObjects(@"04134 1", [f inputDigit:@"1"]);
  XCTAssertEqualObjects(@"04134 12", [f inputDigit:@"2"]);
  XCTAssertEqualObjects(@"04134 123", [f inputDigit:@"3"]);
  XCTAssertEqualObjects(@"04134 1234", [f inputDigit:@"4"]);

  // 08021 2345
  [f clear];
  XCTAssertEqualObjects(@"0", [f inputDigit:@"0"]);
  XCTAssertEqualObjects(@"08", [f inputDigit:@"8"]);
  XCTAssertEqualObjects(@"080", [f inputDigit:@"0"]);
  XCTAssertEqualObjects(@"080 2", [f inputDigit:@"2"]);
  XCTAssertEqualObjects(@"080 21", [f inputDigit:@"1"]);
  XCTAssertEqualObjects(@"08021 2", [f inputDigit:@"2"]);
  XCTAssertEqualObjects(@"08021 23", [f inputDigit:@"3"]);
  XCTAssertEqualObjects(@"08021 234", [f inputDigit:@"4"]);
  XCTAssertEqualObjects(@"08021 2345", [f inputDigit:@"5"]);

  // 00 1 650 253 2250
  [f clear];
  XCTAssertEqualObjects(@"0", [f inputDigit:@"0"]);
  XCTAssertEqualObjects(@"00", [f inputDigit:@"0"]);
  XCTAssertEqualObjects(@"00 1 ", [f inputDigit:@"1"]);
  XCTAssertEqualObjects(@"00 1 6", [f inputDigit:@"6"]);
  XCTAssertEqualObjects(@"00 1 65", [f inputDigit:@"5"]);
  XCTAssertEqualObjects(@"00 1 650", [f inputDigit:@"0"]);
  XCTAssertEqualObjects(@"00 1 650 2", [f inputDigit:@"2"]);
  XCTAssertEqualObjects(@"00 1 650 25", [f inputDigit:@"5"]);
  XCTAssertEqualObjects(@"00 1 650 253", [f inputDigit:@"3"]);
  XCTAssertEqualObjects(@"00 1 650 253 2", [f inputDigit:@"2"]);
  XCTAssertEqualObjects(@"00 1 650 253 22", [f inputDigit:@"2"]);
  XCTAssertEqualObjects(@"00 1 650 253 222", [f inputDigit:@"2"]);
  XCTAssertEqualObjects(@"00 1 650 253 2222", [f inputDigit:@"2"]);
}

- (void)testAYTFAR {
  NBAsYouTypeFormatter *f = [[NBAsYouTypeFormatter alloc] initWithRegionCode:@"AR"
                                                              metadataHelper:_helper];
  XCTAssertEqualObjects(@"0", [f inputDigit:@"0"]);
  XCTAssertEqualObjects(@"01", [f inputDigit:@"1"]);
  XCTAssertEqualObjects(@"011", [f inputDigit:@"1"]);
  XCTAssertEqualObjects(@"011 7", [f inputDigit:@"7"]);
  XCTAssertEqualObjects(@"011 70", [f inputDigit:@"0"]);
  XCTAssertEqualObjects(@"011 703", [f inputDigit:@"3"]);
  XCTAssertEqualObjects(@"011 7031", [f inputDigit:@"1"]);
  XCTAssertEqualObjects(@"011 7031-3", [f inputDigit:@"3"]);
  XCTAssertEqualObjects(@"011 7031-30", [f inputDigit:@"0"]);
  XCTAssertEqualObjects(@"011 7031-300", [f inputDigit:@"0"]);
  XCTAssertEqualObjects(@"011 7031-3000", [f inputDigit:@"0"]);
}

- (void)testAYTFARMobile {
  NBAsYouTypeFormatter *f = [[NBAsYouTypeFormatter alloc] initWithRegionCode:@"AR"
                                                              metadataHelper:_helper];
  XCTAssertEqualObjects(@"+", [f inputDigit:@"+"]);
  XCTAssertEqualObjects(@"+5", [f inputDigit:@"5"]);
  XCTAssertEqualObjects(@"+54 ", [f inputDigit:@"4"]);
  XCTAssertEqualObjects(@"+54 9", [f inputDigit:@"9"]);
  XCTAssertEqualObjects(@"+54 91", [f inputDigit:@"1"]);
  XCTAssertEqualObjects(@"+54 9 11", [f inputDigit:@"1"]);
  XCTAssertEqualObjects(@"+54 9 11 2", [f inputDigit:@"2"]);
  XCTAssertEqualObjects(@"+54 9 11 23", [f inputDigit:@"3"]);
  XCTAssertEqualObjects(@"+54 9 11 231", [f inputDigit:@"1"]);
  XCTAssertEqualObjects(@"+54 9 11 2312", [f inputDigit:@"2"]);
  XCTAssertEqualObjects(@"+54 9 11 2312 1", [f inputDigit:@"1"]);
  XCTAssertEqualObjects(@"+54 9 11 2312 12", [f inputDigit:@"2"]);
  XCTAssertEqualObjects(@"+54 9 11 2312 123", [f inputDigit:@"3"]);
  XCTAssertEqualObjects(@"+54 9 11 2312 1234", [f inputDigit:@"4"]);
}

- (void)testAYTFKR {
  // +82 51 234 5678
  NBAsYouTypeFormatter *f = [[NBAsYouTypeFormatter alloc] initWithRegionCode:@"KR"
                                                              metadataHelper:_helper];
  XCTAssertEqualObjects(@"+", [f inputDigit:@"+"]);
  XCTAssertEqualObjects(@"+8", [f inputDigit:@"8"]);
  XCTAssertEqualObjects(@"+82 ", [f inputDigit:@"2"]);
  XCTAssertEqualObjects(@"+82 5", [f inputDigit:@"5"]);
  XCTAssertEqualObjects(@"+82 51", [f inputDigit:@"1"]);
  XCTAssertEqualObjects(@"+82 51-2", [f inputDigit:@"2"]);
  XCTAssertEqualObjects(@"+82 51-23", [f inputDigit:@"3"]);
  XCTAssertEqualObjects(@"+82 51-234", [f inputDigit:@"4"]);
  XCTAssertEqualObjects(@"+82 51-234-5", [f inputDigit:@"5"]);
  XCTAssertEqualObjects(@"+82 51-234-56", [f inputDigit:@"6"]);
  XCTAssertEqualObjects(@"+82 51-234-567", [f inputDigit:@"7"]);
  XCTAssertEqualObjects(@"+82 51-234-5678", [f inputDigit:@"8"]);

  // +82 2 531 5678
  [f clear];
  XCTAssertEqualObjects(@"+", [f inputDigit:@"+"]);
  XCTAssertEqualObjects(@"+8", [f inputDigit:@"8"]);
  XCTAssertEqualObjects(@"+82 ", [f inputDigit:@"2"]);
  XCTAssertEqualObjects(@"+82 2", [f inputDigit:@"2"]);
  XCTAssertEqualObjects(@"+82 25", [f inputDigit:@"5"]);
  XCTAssertEqualObjects(@"+82 2-53", [f inputDigit:@"3"]);
  XCTAssertEqualObjects(@"+82 2-531", [f inputDigit:@"1"]);
  XCTAssertEqualObjects(@"+82 2-531-5", [f inputDigit:@"5"]);
  XCTAssertEqualObjects(@"+82 2-531-56", [f inputDigit:@"6"]);
  XCTAssertEqualObjects(@"+82 2-531-567", [f inputDigit:@"7"]);
  XCTAssertEqualObjects(@"+82 2-531-5678", [f inputDigit:@"8"]);

  // +82 2 3665 5678
  [f clear];
  XCTAssertEqualObjects(@"+", [f inputDigit:@"+"]);
  XCTAssertEqualObjects(@"+8", [f inputDigit:@"8"]);
  XCTAssertEqualObjects(@"+82 ", [f inputDigit:@"2"]);
  XCTAssertEqualObjects(@"+82 2", [f inputDigit:@"2"]);
  XCTAssertEqualObjects(@"+82 23", [f inputDigit:@"3"]);
  XCTAssertEqualObjects(@"+82 2-36", [f inputDigit:@"6"]);
  XCTAssertEqualObjects(@"+82 2-366", [f inputDigit:@"6"]);
  XCTAssertEqualObjects(@"+82 2-3665", [f inputDigit:@"5"]);
  XCTAssertEqualObjects(@"+82 2-3665-5", [f inputDigit:@"5"]);
  XCTAssertEqualObjects(@"+82 2-3665-56", [f inputDigit:@"6"]);
  XCTAssertEqualObjects(@"+82 2-3665-567", [f inputDigit:@"7"]);
  XCTAssertEqualObjects(@"+82 2-3665-5678", [f inputDigit:@"8"]);

  // 02-114
  [f clear];
  XCTAssertEqualObjects(@"0", [f inputDigit:@"0"]);
  XCTAssertEqualObjects(@"02", [f inputDigit:@"2"]);
  XCTAssertEqualObjects(@"021", [f inputDigit:@"1"]);
  XCTAssertEqualObjects(@"02-11", [f inputDigit:@"1"]);
  XCTAssertEqualObjects(@"02-114", [f inputDigit:@"4"]);

  // 02-1300
  [f clear];
  XCTAssertEqualObjects(@"0", [f inputDigit:@"0"]);
  XCTAssertEqualObjects(@"02", [f inputDigit:@"2"]);
  XCTAssertEqualObjects(@"021", [f inputDigit:@"1"]);
  XCTAssertEqualObjects(@"02-13", [f inputDigit:@"3"]);
  XCTAssertEqualObjects(@"02-130", [f inputDigit:@"0"]);
  XCTAssertEqualObjects(@"02-1300", [f inputDigit:@"0"]);

  // 011-456-7890
  [f clear];
  XCTAssertEqualObjects(@"0", [f inputDigit:@"0"]);
  XCTAssertEqualObjects(@"01", [f inputDigit:@"1"]);
  XCTAssertEqualObjects(@"011", [f inputDigit:@"1"]);
  XCTAssertEqualObjects(@"011-4", [f inputDigit:@"4"]);
  XCTAssertEqualObjects(@"011-45", [f inputDigit:@"5"]);
  XCTAssertEqualObjects(@"011-456", [f inputDigit:@"6"]);
  XCTAssertEqualObjects(@"011-456-7", [f inputDigit:@"7"]);
  XCTAssertEqualObjects(@"011-456-78", [f inputDigit:@"8"]);
  XCTAssertEqualObjects(@"011-456-789", [f inputDigit:@"9"]);
  XCTAssertEqualObjects(@"011-456-7890", [f inputDigit:@"0"]);

  // 011-9876-7890
  [f clear];
  XCTAssertEqualObjects(@"0", [f inputDigit:@"0"]);
  XCTAssertEqualObjects(@"01", [f inputDigit:@"1"]);
  XCTAssertEqualObjects(@"011", [f inputDigit:@"1"]);
  XCTAssertEqualObjects(@"011-9", [f inputDigit:@"9"]);
  XCTAssertEqualObjects(@"011-98", [f inputDigit:@"8"]);
  XCTAssertEqualObjects(@"011-987", [f inputDigit:@"7"]);
  XCTAssertEqualObjects(@"011-9876", [f inputDigit:@"6"]);
  XCTAssertEqualObjects(@"011-9876-7", [f inputDigit:@"7"]);
  XCTAssertEqualObjects(@"011-9876-78", [f inputDigit:@"8"]);
  XCTAssertEqualObjects(@"011-9876-789", [f inputDigit:@"9"]);
  XCTAssertEqualObjects(@"011-9876-7890", [f inputDigit:@"0"]);
}

- (void)testAYTF_MX {
  NBAsYouTypeFormatter *f = [[NBAsYouTypeFormatter alloc] initWithRegionCode:@"MX"
                                                              metadataHelper:_helper];

  // +52 800 123 4567
  XCTAssertEqualObjects(@"+", [f inputDigit:@"+"]);
  XCTAssertEqualObjects(@"+5", [f inputDigit:@"5"]);
  XCTAssertEqualObjects(@"+52 ", [f inputDigit:@"2"]);
  XCTAssertEqualObjects(@"+52 8", [f inputDigit:@"8"]);
  XCTAssertEqualObjects(@"+52 80", [f inputDigit:@"0"]);
  XCTAssertEqualObjects(@"+52 800", [f inputDigit:@"0"]);
  XCTAssertEqualObjects(@"+52 800 1", [f inputDigit:@"1"]);
  XCTAssertEqualObjects(@"+52 800 12", [f inputDigit:@"2"]);
  XCTAssertEqualObjects(@"+52 800 123", [f inputDigit:@"3"]);
  XCTAssertEqualObjects(@"+52 800 123 4", [f inputDigit:@"4"]);
  XCTAssertEqualObjects(@"+52 800 123 45", [f inputDigit:@"5"]);
  XCTAssertEqualObjects(@"+52 800 123 456", [f inputDigit:@"6"]);
  XCTAssertEqualObjects(@"+52 800 123 4567", [f inputDigit:@"7"]);

  // +52 55 1234 5678
  [f clear];
  XCTAssertEqualObjects(@"+", [f inputDigit:@"+"]);
  XCTAssertEqualObjects(@"+5", [f inputDigit:@"5"]);
  XCTAssertEqualObjects(@"+52 ", [f inputDigit:@"2"]);
  XCTAssertEqualObjects(@"+52 5", [f inputDigit:@"5"]);
  XCTAssertEqualObjects(@"+52 55", [f inputDigit:@"5"]);
  XCTAssertEqualObjects(@"+52 55 1", [f inputDigit:@"1"]);
  XCTAssertEqualObjects(@"+52 55 12", [f inputDigit:@"2"]);
  XCTAssertEqualObjects(@"+52 55 123", [f inputDigit:@"3"]);
  XCTAssertEqualObjects(@"+52 55 1234", [f inputDigit:@"4"]);
  XCTAssertEqualObjects(@"+52 55 1234 5", [f inputDigit:@"5"]);
  XCTAssertEqualObjects(@"+52 55 1234 56", [f inputDigit:@"6"]);
  XCTAssertEqualObjects(@"+52 55 1234 567", [f inputDigit:@"7"]);
  XCTAssertEqualObjects(@"+52 55 1234 5678", [f inputDigit:@"8"]);

  // +52 212 345 6789
  [f clear];
  XCTAssertEqualObjects(@"+", [f inputDigit:@"+"]);
  XCTAssertEqualObjects(@"+5", [f inputDigit:@"5"]);
  XCTAssertEqualObjects(@"+52 ", [f inputDigit:@"2"]);
  XCTAssertEqualObjects(@"+52 2", [f inputDigit:@"2"]);
  XCTAssertEqualObjects(@"+52 21", [f inputDigit:@"1"]);
  XCTAssertEqualObjects(@"+52 212", [f inputDigit:@"2"]);
  XCTAssertEqualObjects(@"+52 212 3", [f inputDigit:@"3"]);
  XCTAssertEqualObjects(@"+52 212 34", [f inputDigit:@"4"]);
  XCTAssertEqualObjects(@"+52 212 345", [f inputDigit:@"5"]);
  XCTAssertEqualObjects(@"+52 212 345 6", [f inputDigit:@"6"]);
  XCTAssertEqualObjects(@"+52 212 345 67", [f inputDigit:@"7"]);
  XCTAssertEqualObjects(@"+52 212 345 678", [f inputDigit:@"8"]);
  XCTAssertEqualObjects(@"+52 212 345 6789", [f inputDigit:@"9"]);

  // +52 1 55 1234 5678
  [f clear];
  XCTAssertEqualObjects(@"+", [f inputDigit:@"+"]);
  XCTAssertEqualObjects(@"+5", [f inputDigit:@"5"]);
  XCTAssertEqualObjects(@"+52 ", [f inputDigit:@"2"]);
  XCTAssertEqualObjects(@"+52 1", [f inputDigit:@"1"]);
  XCTAssertEqualObjects(@"+52 15", [f inputDigit:@"5"]);
  XCTAssertEqualObjects(@"+52 1 55", [f inputDigit:@"5"]);
  XCTAssertEqualObjects(@"+52 1 55 1", [f inputDigit:@"1"]);
  XCTAssertEqualObjects(@"+52 1 55 12", [f inputDigit:@"2"]);
  XCTAssertEqualObjects(@"+52 1 55 123", [f inputDigit:@"3"]);
  XCTAssertEqualObjects(@"+52 1 55 1234", [f inputDigit:@"4"]);
  XCTAssertEqualObjects(@"+52 1 55 1234 5", [f inputDigit:@"5"]);
  XCTAssertEqualObjects(@"+52 1 55 1234 56", [f inputDigit:@"6"]);
  XCTAssertEqualObjects(@"+52 1 55 1234 567", [f inputDigit:@"7"]);
  XCTAssertEqualObjects(@"+52 1 55 1234 5678", [f inputDigit:@"8"]);

  // +52 1 541 234 5678
  [f clear];
  XCTAssertEqualObjects(@"+", [f inputDigit:@"+"]);
  XCTAssertEqualObjects(@"+5", [f inputDigit:@"5"]);
  XCTAssertEqualObjects(@"+52 ", [f inputDigit:@"2"]);
  XCTAssertEqualObjects(@"+52 1", [f inputDigit:@"1"]);
  XCTAssertEqualObjects(@"+52 15", [f inputDigit:@"5"]);
  XCTAssertEqualObjects(@"+52 1 54", [f inputDigit:@"4"]);
  XCTAssertEqualObjects(@"+52 1 541", [f inputDigit:@"1"]);
  XCTAssertEqualObjects(@"+52 1 541 2", [f inputDigit:@"2"]);
  XCTAssertEqualObjects(@"+52 1 541 23", [f inputDigit:@"3"]);
  XCTAssertEqualObjects(@"+52 1 541 234", [f inputDigit:@"4"]);
  XCTAssertEqualObjects(@"+52 1 541 234 5", [f inputDigit:@"5"]);
  XCTAssertEqualObjects(@"+52 1 541 234 56", [f inputDigit:@"6"]);
  XCTAssertEqualObjects(@"+52 1 541 234 567", [f inputDigit:@"7"]);
  XCTAssertEqualObjects(@"+52 1 541 234 5678", [f inputDigit:@"8"]);
}

- (void)testAYTF_International_Toll_Free {
  NBAsYouTypeFormatter *f = [[NBAsYouTypeFormatter alloc] initWithRegionCode:@"US"
                                                              metadataHelper:_helper];
  // +800 1234 5678
  XCTAssertEqualObjects(@"+", [f inputDigit:@"+"]);
  XCTAssertEqualObjects(@"+8", [f inputDigit:@"8"]);
  XCTAssertEqualObjects(@"+80", [f inputDigit:@"0"]);
  XCTAssertEqualObjects(@"+800 ", [f inputDigit:@"0"]);
  XCTAssertEqualObjects(@"+800 1", [f inputDigit:@"1"]);
  XCTAssertEqualObjects(@"+800 12", [f inputDigit:@"2"]);
  XCTAssertEqualObjects(@"+800 123", [f inputDigit:@"3"]);
  XCTAssertEqualObjects(@"+800 1234", [f inputDigit:@"4"]);
  XCTAssertEqualObjects(@"+800 1234 5", [f inputDigit:@"5"]);
  XCTAssertEqualObjects(@"+800 1234 56", [f inputDigit:@"6"]);
  XCTAssertEqualObjects(@"+800 1234 567", [f inputDigit:@"7"]);
  XCTAssertEqualObjects(@"+800 1234 5678", [f inputDigit:@"8"]);
  XCTAssertEqualObjects(@"+800123456789", [f inputDigit:@"9"]);
}

- (void)testAYTFMultipleLeadingDigitPatterns {
  // +81 50 2345 6789
  NBAsYouTypeFormatter *f = [[NBAsYouTypeFormatter alloc] initWithRegionCode:@"JP"
                                                              metadataHelper:_helper];
  XCTAssertEqualObjects(@"+", [f inputDigit:@"+"]);
  XCTAssertEqualObjects(@"+8", [f inputDigit:@"8"]);
  XCTAssertEqualObjects(@"+81 ", [f inputDigit:@"1"]);
  XCTAssertEqualObjects(@"+81 5", [f inputDigit:@"5"]);
  XCTAssertEqualObjects(@"+81 50", [f inputDigit:@"0"]);
  XCTAssertEqualObjects(@"+81 50 2", [f inputDigit:@"2"]);
  XCTAssertEqualObjects(@"+81 50 23", [f inputDigit:@"3"]);
  XCTAssertEqualObjects(@"+81 50 234", [f inputDigit:@"4"]);
  XCTAssertEqualObjects(@"+81 50 2345", [f inputDigit:@"5"]);
  XCTAssertEqualObjects(@"+81 50 2345 6", [f inputDigit:@"6"]);
  XCTAssertEqualObjects(@"+81 50 2345 67", [f inputDigit:@"7"]);
  XCTAssertEqualObjects(@"+81 50 2345 678", [f inputDigit:@"8"]);
  XCTAssertEqualObjects(@"+81 50 2345 6789", [f inputDigit:@"9"]);

  // +81 222 12 5678
  [f clear];
  XCTAssertEqualObjects(@"+", [f inputDigit:@"+"]);
  XCTAssertEqualObjects(@"+8", [f inputDigit:@"8"]);
  XCTAssertEqualObjects(@"+81 ", [f inputDigit:@"1"]);
  XCTAssertEqualObjects(@"+81 2", [f inputDigit:@"2"]);
  XCTAssertEqualObjects(@"+81 22", [f inputDigit:@"2"]);
  XCTAssertEqualObjects(@"+81 22 2", [f inputDigit:@"2"]);
  XCTAssertEqualObjects(@"+81 22 21", [f inputDigit:@"1"]);
  XCTAssertEqualObjects(@"+81 2221 2", [f inputDigit:@"2"]);
  XCTAssertEqualObjects(@"+81 222 12 5", [f inputDigit:@"5"]);
  XCTAssertEqualObjects(@"+81 222 12 56", [f inputDigit:@"6"]);
  XCTAssertEqualObjects(@"+81 222 12 567", [f inputDigit:@"7"]);
  XCTAssertEqualObjects(@"+81 222 12 5678", [f inputDigit:@"8"]);

  // 011113
  [f clear];
  XCTAssertEqualObjects(@"0", [f inputDigit:@"0"]);
  XCTAssertEqualObjects(@"01", [f inputDigit:@"1"]);
  XCTAssertEqualObjects(@"011", [f inputDigit:@"1"]);
  XCTAssertEqualObjects(@"011 1", [f inputDigit:@"1"]);
  XCTAssertEqualObjects(@"011 11", [f inputDigit:@"1"]);
  XCTAssertEqualObjects(@"011113", [f inputDigit:@"3"]);

  // +81 3332 2 5678
  [f clear];
  XCTAssertEqualObjects(@"+", [f inputDigit:@"+"]);
  XCTAssertEqualObjects(@"+8", [f inputDigit:@"8"]);
  XCTAssertEqualObjects(@"+81 ", [f inputDigit:@"1"]);
  XCTAssertEqualObjects(@"+81 3", [f inputDigit:@"3"]);
  XCTAssertEqualObjects(@"+81 33", [f inputDigit:@"3"]);
  XCTAssertEqualObjects(@"+81 33 3", [f inputDigit:@"3"]);
  XCTAssertEqualObjects(@"+81 3332", [f inputDigit:@"2"]);
  XCTAssertEqualObjects(@"+81 3332 2", [f inputDigit:@"2"]);
  XCTAssertEqualObjects(@"+81 3332 2 5", [f inputDigit:@"5"]);
  XCTAssertEqualObjects(@"+81 3332 2 56", [f inputDigit:@"6"]);
  XCTAssertEqualObjects(@"+81 3332 2 567", [f inputDigit:@"7"]);
  XCTAssertEqualObjects(@"+81 3332 2 5678", [f inputDigit:@"8"]);
}

- (void)testAYTFLongIDD_AU {
  NBAsYouTypeFormatter *f = [[NBAsYouTypeFormatter alloc] initWithRegionCode:@"AU"
                                                              metadataHelper:_helper];
  // 0011 1 650 253 2250
  XCTAssertEqualObjects(@"0", [f inputDigit:@"0"]);
  XCTAssertEqualObjects(@"00", [f inputDigit:@"0"]);
  XCTAssertEqualObjects(@"001", [f inputDigit:@"1"]);
  XCTAssertEqualObjects(@"0011", [f inputDigit:@"1"]);
  XCTAssertEqualObjects(@"0011 1 ", [f inputDigit:@"1"]);
  XCTAssertEqualObjects(@"0011 1 6", [f inputDigit:@"6"]);
  XCTAssertEqualObjects(@"0011 1 65", [f inputDigit:@"5"]);
  XCTAssertEqualObjects(@"0011 1 650", [f inputDigit:@"0"]);
  XCTAssertEqualObjects(@"0011 1 650 2", [f inputDigit:@"2"]);
  XCTAssertEqualObjects(@"0011 1 650 25", [f inputDigit:@"5"]);
  XCTAssertEqualObjects(@"0011 1 650 253", [f inputDigit:@"3"]);
  XCTAssertEqualObjects(@"0011 1 650 253 2", [f inputDigit:@"2"]);
  XCTAssertEqualObjects(@"0011 1 650 253 22", [f inputDigit:@"2"]);
  XCTAssertEqualObjects(@"0011 1 650 253 222", [f inputDigit:@"2"]);
  XCTAssertEqualObjects(@"0011 1 650 253 2222", [f inputDigit:@"2"]);

  // 0011 81 3332 2 5678
  [f clear];
  XCTAssertEqualObjects(@"0", [f inputDigit:@"0"]);
  XCTAssertEqualObjects(@"00", [f inputDigit:@"0"]);
  XCTAssertEqualObjects(@"001", [f inputDigit:@"1"]);
  XCTAssertEqualObjects(@"0011", [f inputDigit:@"1"]);
  XCTAssertEqualObjects(@"00118", [f inputDigit:@"8"]);
  XCTAssertEqualObjects(@"0011 81 ", [f inputDigit:@"1"]);
  XCTAssertEqualObjects(@"0011 81 3", [f inputDigit:@"3"]);
  XCTAssertEqualObjects(@"0011 81 33", [f inputDigit:@"3"]);
  XCTAssertEqualObjects(@"0011 81 33 3", [f inputDigit:@"3"]);
  XCTAssertEqualObjects(@"0011 81 3332", [f inputDigit:@"2"]);
  XCTAssertEqualObjects(@"0011 81 3332 2", [f inputDigit:@"2"]);
  XCTAssertEqualObjects(@"0011 81 3332 2 5", [f inputDigit:@"5"]);
  XCTAssertEqualObjects(@"0011 81 3332 2 56", [f inputDigit:@"6"]);
  XCTAssertEqualObjects(@"0011 81 3332 2 567", [f inputDigit:@"7"]);
  XCTAssertEqualObjects(@"0011 81 3332 2 5678", [f inputDigit:@"8"]);

  // 0011 244 250 253 222
  [f clear];
  XCTAssertEqualObjects(@"0", [f inputDigit:@"0"]);
  XCTAssertEqualObjects(@"00", [f inputDigit:@"0"]);
  XCTAssertEqualObjects(@"001", [f inputDigit:@"1"]);
  XCTAssertEqualObjects(@"0011", [f inputDigit:@"1"]);
  XCTAssertEqualObjects(@"00112", [f inputDigit:@"2"]);
  XCTAssertEqualObjects(@"001124", [f inputDigit:@"4"]);
  XCTAssertEqualObjects(@"0011 244 ", [f inputDigit:@"4"]);
  XCTAssertEqualObjects(@"0011 244 2", [f inputDigit:@"2"]);
  XCTAssertEqualObjects(@"0011 244 25", [f inputDigit:@"5"]);
  XCTAssertEqualObjects(@"0011 244 250", [f inputDigit:@"0"]);
  XCTAssertEqualObjects(@"0011 244 250 2", [f inputDigit:@"2"]);
  XCTAssertEqualObjects(@"0011 244 250 25", [f inputDigit:@"5"]);
  XCTAssertEqualObjects(@"0011 244 250 253", [f inputDigit:@"3"]);
  XCTAssertEqualObjects(@"0011 244 250 253 2", [f inputDigit:@"2"]);
  XCTAssertEqualObjects(@"0011 244 250 253 22", [f inputDigit:@"2"]);
  XCTAssertEqualObjects(@"0011 244 250 253 222", [f inputDigit:@"2"]);
}

- (void)testAYTFLongIDD_KR {
  NBAsYouTypeFormatter *f = [[NBAsYouTypeFormatter alloc] initWithRegionCode:@"KR"
                                                              metadataHelper:_helper];
  // 00300 1 650 253 2222
  XCTAssertEqualObjects(@"0", [f inputDigit:@"0"]);
  XCTAssertEqualObjects(@"00", [f inputDigit:@"0"]);
  XCTAssertEqualObjects(@"003", [f inputDigit:@"3"]);
  XCTAssertEqualObjects(@"0030", [f inputDigit:@"0"]);
  XCTAssertEqualObjects(@"00300", [f inputDigit:@"0"]);
  XCTAssertEqualObjects(@"00300 1 ", [f inputDigit:@"1"]);
  XCTAssertEqualObjects(@"00300 1 6", [f inputDigit:@"6"]);
  XCTAssertEqualObjects(@"00300 1 65", [f inputDigit:@"5"]);
  XCTAssertEqualObjects(@"00300 1 650", [f inputDigit:@"0"]);
  XCTAssertEqualObjects(@"00300 1 650 2", [f inputDigit:@"2"]);
  XCTAssertEqualObjects(@"00300 1 650 25", [f inputDigit:@"5"]);
  XCTAssertEqualObjects(@"00300 1 650 253", [f inputDigit:@"3"]);
  XCTAssertEqualObjects(@"00300 1 650 253 2", [f inputDigit:@"2"]);
  XCTAssertEqualObjects(@"00300 1 650 253 22", [f inputDigit:@"2"]);
  XCTAssertEqualObjects(@"00300 1 650 253 222", [f inputDigit:@"2"]);
  XCTAssertEqualObjects(@"00300 1 650 253 2222", [f inputDigit:@"2"]);
}

- (void)testAYTFLongNDD_KR {
  NBAsYouTypeFormatter *f = [[NBAsYouTypeFormatter alloc] initWithRegionCode:@"KR"
                                                              metadataHelper:_helper];
  // 08811-9876-7890
  XCTAssertEqualObjects(@"0", [f inputDigit:@"0"]);
  XCTAssertEqualObjects(@"08", [f inputDigit:@"8"]);
  XCTAssertEqualObjects(@"088", [f inputDigit:@"8"]);
  XCTAssertEqualObjects(@"0881", [f inputDigit:@"1"]);
  XCTAssertEqualObjects(@"08811", [f inputDigit:@"1"]);
  XCTAssertEqualObjects(@"08811-9", [f inputDigit:@"9"]);
  XCTAssertEqualObjects(@"08811-98", [f inputDigit:@"8"]);
  XCTAssertEqualObjects(@"08811-987", [f inputDigit:@"7"]);
  XCTAssertEqualObjects(@"08811-9876", [f inputDigit:@"6"]);
  XCTAssertEqualObjects(@"08811-9876-7", [f inputDigit:@"7"]);
  XCTAssertEqualObjects(@"08811-9876-78", [f inputDigit:@"8"]);
  XCTAssertEqualObjects(@"08811-9876-789", [f inputDigit:@"9"]);
  XCTAssertEqualObjects(@"08811-9876-7890", [f inputDigit:@"0"]);

  // 08500 11-9876-7890
  [f clear];
  XCTAssertEqualObjects(@"0", [f inputDigit:@"0"]);
  XCTAssertEqualObjects(@"08", [f inputDigit:@"8"]);
  XCTAssertEqualObjects(@"085", [f inputDigit:@"5"]);
  XCTAssertEqualObjects(@"0850", [f inputDigit:@"0"]);
  XCTAssertEqualObjects(@"08500 ", [f inputDigit:@"0"]);
  XCTAssertEqualObjects(@"08500 1", [f inputDigit:@"1"]);
  XCTAssertEqualObjects(@"08500 11", [f inputDigit:@"1"]);
  XCTAssertEqualObjects(@"08500 11-9", [f inputDigit:@"9"]);
  XCTAssertEqualObjects(@"08500 11-98", [f inputDigit:@"8"]);
  XCTAssertEqualObjects(@"08500 11-987", [f inputDigit:@"7"]);
  XCTAssertEqualObjects(@"08500 11-9876", [f inputDigit:@"6"]);
  XCTAssertEqualObjects(@"08500 11-9876-7", [f inputDigit:@"7"]);
  XCTAssertEqualObjects(@"08500 11-9876-78", [f inputDigit:@"8"]);
  XCTAssertEqualObjects(@"08500 11-9876-789", [f inputDigit:@"9"]);
  XCTAssertEqualObjects(@"08500 11-9876-7890", [f inputDigit:@"0"]);
}

- (void)testAYTFLongNDD_SG {
  NBAsYouTypeFormatter *f = [[NBAsYouTypeFormatter alloc] initWithRegionCode:@"SG"
                                                              metadataHelper:_helper];
  // 777777 9876 7890
  XCTAssertEqualObjects(@"7", [f inputDigit:@"7"]);
  XCTAssertEqualObjects(@"77", [f inputDigit:@"7"]);
  XCTAssertEqualObjects(@"777", [f inputDigit:@"7"]);
  XCTAssertEqualObjects(@"7777", [f inputDigit:@"7"]);
  XCTAssertEqualObjects(@"77777", [f inputDigit:@"7"]);
  XCTAssertEqualObjects(@"777777 ", [f inputDigit:@"7"]);
  XCTAssertEqualObjects(@"777777 9", [f inputDigit:@"9"]);
  XCTAssertEqualObjects(@"777777 98", [f inputDigit:@"8"]);
  XCTAssertEqualObjects(@"777777 987", [f inputDigit:@"7"]);
  XCTAssertEqualObjects(@"777777 9876", [f inputDigit:@"6"]);
  XCTAssertEqualObjects(@"777777 9876 7", [f inputDigit:@"7"]);
  XCTAssertEqualObjects(@"777777 9876 78", [f inputDigit:@"8"]);
  XCTAssertEqualObjects(@"777777 9876 789", [f inputDigit:@"9"]);
  XCTAssertEqualObjects(@"777777 9876 7890", [f inputDigit:@"0"]);
}

- (void)testAYTFShortNumberFormattingFix_AU {
  // For Australia, the national prefix is not optional when formatting.
  NBAsYouTypeFormatter *f = [[NBAsYouTypeFormatter alloc] initWithRegionCode:@"AU"
                                                              metadataHelper:_helper];

  // 1234567890 - For leading digit 1, the national prefix formatting rule has
  // first group only.
  XCTAssertEqualObjects(@"1", [f inputDigit:@"1"]);
  XCTAssertEqualObjects(@"12", [f inputDigit:@"2"]);
  XCTAssertEqualObjects(@"123", [f inputDigit:@"3"]);
  XCTAssertEqualObjects(@"1234", [f inputDigit:@"4"]);
  XCTAssertEqualObjects(@"1234 5", [f inputDigit:@"5"]);
  XCTAssertEqualObjects(@"1234 56", [f inputDigit:@"6"]);
  XCTAssertEqualObjects(@"1234 567", [f inputDigit:@"7"]);
  XCTAssertEqualObjects(@"1234 567 8", [f inputDigit:@"8"]);
  XCTAssertEqualObjects(@"1234 567 89", [f inputDigit:@"9"]);
  XCTAssertEqualObjects(@"1234 567 890", [f inputDigit:@"0"]);

  // +61 1234 567 890 - Test the same number, but with the country code.
  [f clear];
  XCTAssertEqualObjects(@"+", [f inputDigit:@"+"]);
  XCTAssertEqualObjects(@"+6", [f inputDigit:@"6"]);
  XCTAssertEqualObjects(@"+61 ", [f inputDigit:@"1"]);
  XCTAssertEqualObjects(@"+61 1", [f inputDigit:@"1"]);
  XCTAssertEqualObjects(@"+61 12", [f inputDigit:@"2"]);
  XCTAssertEqualObjects(@"+61 123", [f inputDigit:@"3"]);
  XCTAssertEqualObjects(@"+61 1234", [f inputDigit:@"4"]);
  XCTAssertEqualObjects(@"+61 1234 5", [f inputDigit:@"5"]);
  XCTAssertEqualObjects(@"+61 1234 56", [f inputDigit:@"6"]);
  XCTAssertEqualObjects(@"+61 1234 567", [f inputDigit:@"7"]);
  XCTAssertEqualObjects(@"+61 1234 567 8", [f inputDigit:@"8"]);
  XCTAssertEqualObjects(@"+61 1234 567 89", [f inputDigit:@"9"]);
  XCTAssertEqualObjects(@"+61 1234 567 890", [f inputDigit:@"0"]);

  // 212345678 - For leading digit 2, the national prefix formatting rule puts
  // the national prefix before the first group.
  [f clear];
  XCTAssertEqualObjects(@"0", [f inputDigit:@"0"]);
  XCTAssertEqualObjects(@"02", [f inputDigit:@"2"]);
  XCTAssertEqualObjects(@"021", [f inputDigit:@"1"]);
  XCTAssertEqualObjects(@"02 12", [f inputDigit:@"2"]);
  XCTAssertEqualObjects(@"02 123", [f inputDigit:@"3"]);
  XCTAssertEqualObjects(@"02 1234", [f inputDigit:@"4"]);
  XCTAssertEqualObjects(@"02 1234 5", [f inputDigit:@"5"]);
  XCTAssertEqualObjects(@"02 1234 56", [f inputDigit:@"6"]);
  XCTAssertEqualObjects(@"02 1234 567", [f inputDigit:@"7"]);
  XCTAssertEqualObjects(@"02 1234 5678", [f inputDigit:@"8"]);

  // 212345678 - Test the same number, but without the leading 0.
  [f clear];
  XCTAssertEqualObjects(@"2", [f inputDigit:@"2"]);
  XCTAssertEqualObjects(@"21", [f inputDigit:@"1"]);
  XCTAssertEqualObjects(@"212", [f inputDigit:@"2"]);
  XCTAssertEqualObjects(@"2123", [f inputDigit:@"3"]);
  XCTAssertEqualObjects(@"21234", [f inputDigit:@"4"]);
  XCTAssertEqualObjects(@"212345", [f inputDigit:@"5"]);
  XCTAssertEqualObjects(@"2123456", [f inputDigit:@"6"]);
  XCTAssertEqualObjects(@"21234567", [f inputDigit:@"7"]);
  XCTAssertEqualObjects(@"212345678", [f inputDigit:@"8"]);

  // +61 2 1234 5678 - Test the same number, but with the country code.
  [f clear];
  XCTAssertEqualObjects(@"+", [f inputDigit:@"+"]);
  XCTAssertEqualObjects(@"+6", [f inputDigit:@"6"]);
  XCTAssertEqualObjects(@"+61 ", [f inputDigit:@"1"]);
  XCTAssertEqualObjects(@"+61 2", [f inputDigit:@"2"]);
  XCTAssertEqualObjects(@"+61 21", [f inputDigit:@"1"]);
  XCTAssertEqualObjects(@"+61 2 12", [f inputDigit:@"2"]);
  XCTAssertEqualObjects(@"+61 2 123", [f inputDigit:@"3"]);
  XCTAssertEqualObjects(@"+61 2 1234", [f inputDigit:@"4"]);
  XCTAssertEqualObjects(@"+61 2 1234 5", [f inputDigit:@"5"]);
  XCTAssertEqualObjects(@"+61 2 1234 56", [f inputDigit:@"6"]);
  XCTAssertEqualObjects(@"+61 2 1234 567", [f inputDigit:@"7"]);
  XCTAssertEqualObjects(@"+61 2 1234 5678", [f inputDigit:@"8"]);
}

- (void)testAYTFShortNumberFormattingFix_KR {
  // For Korea, the national prefix is not optional when formatting, and the
  // national prefix formatting rule doesn't consist of only the first group.
  NBAsYouTypeFormatter *f = [[NBAsYouTypeFormatter alloc] initWithRegionCode:@"KR"
                                                              metadataHelper:_helper];

  // 111
  XCTAssertEqualObjects(@"1", [f inputDigit:@"1"]);
  XCTAssertEqualObjects(@"11", [f inputDigit:@"1"]);
  XCTAssertEqualObjects(@"111", [f inputDigit:@"1"]);

  // 114
  [f clear];
  XCTAssertEqualObjects(@"1", [f inputDigit:@"1"]);
  XCTAssertEqualObjects(@"11", [f inputDigit:@"1"]);
  XCTAssertEqualObjects(@"114", [f inputDigit:@"4"]);

  // 13121234 - Test a mobile number without the national prefix. Even though it
  // is not an emergency number, it should be formatted as a block.
  [f clear];
  XCTAssertEqualObjects(@"1", [f inputDigit:@"1"]);
  XCTAssertEqualObjects(@"13", [f inputDigit:@"3"]);
  XCTAssertEqualObjects(@"131", [f inputDigit:@"1"]);
  XCTAssertEqualObjects(@"1312", [f inputDigit:@"2"]);
  XCTAssertEqualObjects(@"13121", [f inputDigit:@"1"]);
  XCTAssertEqualObjects(@"131212", [f inputDigit:@"2"]);
  XCTAssertEqualObjects(@"1312123", [f inputDigit:@"3"]);
  XCTAssertEqualObjects(@"13121234", [f inputDigit:@"4"]);

  // +82 131-2-1234 - Test the same number, but with the country code.
  [f clear];
  XCTAssertEqualObjects(@"+", [f inputDigit:@"+"]);
  XCTAssertEqualObjects(@"+8", [f inputDigit:@"8"]);
  XCTAssertEqualObjects(@"+82 ", [f inputDigit:@"2"]);
  XCTAssertEqualObjects(@"+82 1", [f inputDigit:@"1"]);
  XCTAssertEqualObjects(@"+82 13", [f inputDigit:@"3"]);
  XCTAssertEqualObjects(@"+82 131", [f inputDigit:@"1"]);
  XCTAssertEqualObjects(@"+82 131-2", [f inputDigit:@"2"]);
  XCTAssertEqualObjects(@"+82 131-2-1", [f inputDigit:@"1"]);
  XCTAssertEqualObjects(@"+82 131-2-12", [f inputDigit:@"2"]);
  XCTAssertEqualObjects(@"+82 131-2-123", [f inputDigit:@"3"]);
  XCTAssertEqualObjects(@"+82 131-2-1234", [f inputDigit:@"4"]);
}

- (void)testAYTFShortNumberFormattingFix_MX {
  // For Mexico, the national prefix is optional when formatting.
  NBAsYouTypeFormatter *f = [[NBAsYouTypeFormatter alloc] initWithRegionCode:@"MX"
                                                              metadataHelper:_helper];

  // 911
  XCTAssertEqualObjects(@"9", [f inputDigit:@"9"]);
  XCTAssertEqualObjects(@"91", [f inputDigit:@"1"]);
  XCTAssertEqualObjects(@"911", [f inputDigit:@"1"]);

  // 800 123 4567 - Test a toll-free number, which should have a formatting rule
  // applied to it even though it doesn't begin with the national prefix.
  [f clear];
  XCTAssertEqualObjects(@"8", [f inputDigit:@"8"]);
  XCTAssertEqualObjects(@"80", [f inputDigit:@"0"]);
  XCTAssertEqualObjects(@"800", [f inputDigit:@"0"]);
  XCTAssertEqualObjects(@"800 1", [f inputDigit:@"1"]);
  XCTAssertEqualObjects(@"800 12", [f inputDigit:@"2"]);
  XCTAssertEqualObjects(@"800 123", [f inputDigit:@"3"]);
  XCTAssertEqualObjects(@"800 123 4", [f inputDigit:@"4"]);
  XCTAssertEqualObjects(@"800 123 45", [f inputDigit:@"5"]);
  XCTAssertEqualObjects(@"800 123 456", [f inputDigit:@"6"]);
  XCTAssertEqualObjects(@"800 123 4567", [f inputDigit:@"7"]);

  // +52 800 123 4567 - Test the same number, but with the country code.
  [f clear];
  XCTAssertEqualObjects(@"+", [f inputDigit:@"+"]);
  XCTAssertEqualObjects(@"+5", [f inputDigit:@"5"]);
  XCTAssertEqualObjects(@"+52 ", [f inputDigit:@"2"]);
  XCTAssertEqualObjects(@"+52 8", [f inputDigit:@"8"]);
  XCTAssertEqualObjects(@"+52 80", [f inputDigit:@"0"]);
  XCTAssertEqualObjects(@"+52 800", [f inputDigit:@"0"]);
  XCTAssertEqualObjects(@"+52 800 1", [f inputDigit:@"1"]);
  XCTAssertEqualObjects(@"+52 800 12", [f inputDigit:@"2"]);
  XCTAssertEqualObjects(@"+52 800 123", [f inputDigit:@"3"]);
  XCTAssertEqualObjects(@"+52 800 123 4", [f inputDigit:@"4"]);
  XCTAssertEqualObjects(@"+52 800 123 45", [f inputDigit:@"5"]);
  XCTAssertEqualObjects(@"+52 800 123 456", [f inputDigit:@"6"]);
  XCTAssertEqualObjects(@"+52 800 123 4567", [f inputDigit:@"7"]);
}

- (void)testAYTFNoNationalPrefix {
  NBAsYouTypeFormatter *f = [[NBAsYouTypeFormatter alloc] initWithRegionCode:@"IT"
                                                              metadataHelper:_helper];
  XCTAssertEqualObjects(@"3", [f inputDigit:@"3"]);
  XCTAssertEqualObjects(@"33", [f inputDigit:@"3"]);
  XCTAssertEqualObjects(@"333", [f inputDigit:@"3"]);
  XCTAssertEqualObjects(@"333 3", [f inputDigit:@"3"]);
  XCTAssertEqualObjects(@"333 33", [f inputDigit:@"3"]);
  XCTAssertEqualObjects(@"333 333", [f inputDigit:@"3"]);
}

- (void)testAYTFShortNumberFormattingFix_US {
  // For the US, an initial 1 is treated specially.
  NBAsYouTypeFormatter *f = [[NBAsYouTypeFormatter alloc] initWithRegionCode:@"US"
                                                              metadataHelper:_helper];

  // 101 - Test that the initial 1 is not treated as a national prefix.
  XCTAssertEqualObjects(@"1", [f inputDigit:@"1"]);
  XCTAssertEqualObjects(@"10", [f inputDigit:@"0"]);
  XCTAssertEqualObjects(@"101", [f inputDigit:@"1"]);

  // 112 - Test that the initial 1 is not treated as a national prefix.
  [f clear];
  XCTAssertEqualObjects(@"1", [f inputDigit:@"1"]);
  XCTAssertEqualObjects(@"11", [f inputDigit:@"1"]);
  XCTAssertEqualObjects(@"112", [f inputDigit:@"2"]);

  // 122 - Test that the initial 1 is treated as a national prefix.
  [f clear];
  XCTAssertEqualObjects(@"1", [f inputDigit:@"1"]);
  XCTAssertEqualObjects(@"12", [f inputDigit:@"2"]);
  XCTAssertEqualObjects(@"1 22", [f inputDigit:@"2"]);
}

- (void)testAYTFDescription {
  NBAsYouTypeFormatter *f = [[NBAsYouTypeFormatter alloc] initWithRegionCode:@"US"
                                                              metadataHelper:_helper];

  [f inputDigit:@"1"];
  [f inputDigit:@"6"];
  [f inputDigit:@"5"];
  [f inputDigit:@"0"];
  [f inputDigit:@"2"];
  [f inputDigit:@"5"];
  [f inputDigit:@"3"];
  [f inputDigit:@"2"];
  [f inputDigit:@"2"];
  [f inputDigit:@"2"];
  [f inputDigit:@"2"];
  XCTAssertEqualObjects(@"1 650 253 2222", [f description]);

  [f removeLastDigit];
  XCTAssertEqualObjects(@"1 650 253 222", [f description]);

  [f removeLastDigit];
  XCTAssertEqualObjects(@"1 650 253 22", [f description]);

  [f removeLastDigit];
  XCTAssertEqualObjects(@"1 650 253 2", [f description]);

  [f removeLastDigit];
  XCTAssertEqualObjects(@"1 650 253", [f description]);

  [f removeLastDigit];
  XCTAssertEqualObjects(@"1 650 25", [f description]);

  [f removeLastDigit];
  XCTAssertEqualObjects(@"1 650 2", [f description]);

  [f removeLastDigit];
  XCTAssertEqualObjects(@"1 650", [f description]);

  [f removeLastDigit];
  XCTAssertEqualObjects(@"1 65", [f description]);

  [f removeLastDigit];
  XCTAssertEqualObjects(@"16", [f description]);

  [f removeLastDigit];
  XCTAssertEqualObjects(@"1", [f description]);

  [f removeLastDigit];
  XCTAssertEqualObjects(@"", [f description]);

  [f inputString:@"16502532222"];
  XCTAssertEqualObjects(@"1 650 253 2222", [f description]);
}

- (void)testAYTFNumberPatternsBecomingInvalidShouldNotResultInDigitLoss {
  NBAsYouTypeFormatter *f = [[NBAsYouTypeFormatter alloc] initWithRegionCode:@"CN"
                                                              metadataHelper:_helper];

  XCTAssertEqualObjects(@"+", [f inputDigit:@"+"]);
  XCTAssertEqualObjects(@"+8", [f inputDigit:@"8"]);
  XCTAssertEqualObjects(@"+86 ", [f inputDigit:@"6"]);
  XCTAssertEqualObjects(@"+86 9", [f inputDigit:@"9"]);
  XCTAssertEqualObjects(@"+86 98", [f inputDigit:@"8"]);
  XCTAssertEqualObjects(@"+86 988", [f inputDigit:@"8"]);
  XCTAssertEqualObjects(@"+86 988 1", [f inputDigit:@"1"]);
  // Now the number pattern is no longer valid because there are multiple leading digit patterns;
  // when we try again to extract a country code we should ensure we use the last leading digit
  // pattern, rather than the first one such that it *thinks* it's found a valid formatting rule
  // again.
  // https://code.google.com/p/libphonenumber/issues/detail?id=437
  XCTAssertEqualObjects(@"+8698812", [f inputDigit:@"2"]);
  XCTAssertEqualObjects(@"+86988123", [f inputDigit:@"3"]);
  XCTAssertEqualObjects(@"+869881234", [f inputDigit:@"4"]);
  XCTAssertEqualObjects(@"+8698812345", [f inputDigit:@"5"]);
}

@end
