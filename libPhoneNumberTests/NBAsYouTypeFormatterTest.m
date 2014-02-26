//
//  NBAsYouTypeFormatterTest.m
//  libPhoneNumber
//
//  Created by ishtar on 13. 3. 5..
//

#import "NBAsYouTypeFormatterTest.h"
#import "NBAsYouTypeFormatter.h"

@implementation NBAsYouTypeFormatterTest

- (void)setUp
{
    [super setUp];
    
    // ...
}

- (void)tearDown
{
    // ...
    
    [super tearDown];
}

- (void)testNSDictionaryalbeKey
{
    //testInvalidRegion()
    {
        /** @type {i18n.phonenumbers.AsYouTypeFormatter} */
        NBAsYouTypeFormatter *f = [[NBAsYouTypeFormatter alloc] initWithRegionCodeForTest:@"ZZ"];
        STAssertEqualObjects(@"+", [f inputDigit:@"+"], nil);
        STAssertEqualObjects(@"+4", [f inputDigit:@"4"], nil);
        STAssertEqualObjects(@"+48 ", [f inputDigit:@"8"], nil);
        STAssertEqualObjects(@"+48 8", [f inputDigit:@"8"], nil);
        STAssertEqualObjects(@"+48 88", [f inputDigit:@"8"], nil);
        STAssertEqualObjects(@"+48 88 1", [f inputDigit:@"1"], nil);
        STAssertEqualObjects(@"+48 88 12", [f inputDigit:@"2"], nil);
        STAssertEqualObjects(@"+48 88 123", [f inputDigit:@"3"], nil);
        STAssertEqualObjects(@"+48 88 123 1", [f inputDigit:@"1"], nil);
        STAssertEqualObjects(@"+48 88 123 12", [f inputDigit:@"2"], nil);
        
        [f clear];
        STAssertEqualObjects(@"6", [f inputDigit:@"6"], nil);
        STAssertEqualObjects(@"65", [f inputDigit:@"5"], nil);
        STAssertEqualObjects(@"650", [f inputDigit:@"0"], nil);
        STAssertEqualObjects(@"6502", [f inputDigit:@"2"], nil);
        STAssertEqualObjects(@"65025", [f inputDigit:@"5"], nil);
        STAssertEqualObjects(@"650253", [f inputDigit:@"3"], nil);
    }
    
    //testInvalidPlusSign()
    {
        /** @type {i18n.phonenumbers.AsYouTypeFormatter} */
        NBAsYouTypeFormatter *f = [[NBAsYouTypeFormatter alloc] initWithRegionCodeForTest:@"ZZ"];
        STAssertEqualObjects(@"+", [f inputDigit:@"+"], nil);
        STAssertEqualObjects(@"+4", [f inputDigit:@"4"], nil);
        STAssertEqualObjects(@"+48 ", [f inputDigit:@"8"], nil);
        STAssertEqualObjects(@"+48 8", [f inputDigit:@"8"], nil);
        STAssertEqualObjects(@"+48 88", [f inputDigit:@"8"], nil);
        STAssertEqualObjects(@"+48 88 1", [f inputDigit:@"1"], nil);
        STAssertEqualObjects(@"+48 88 12", [f inputDigit:@"2"], nil);
        STAssertEqualObjects(@"+48 88 123", [f inputDigit:@"3"], nil);
        STAssertEqualObjects(@"+48 88 123 1", [f inputDigit:@"1"], nil);
        // A plus sign can only appear at the beginning of the number;
        // otherwise, no formatting is applied.
        STAssertEqualObjects(@"+48881231+", [f inputDigit:@"+"], nil);
        STAssertEqualObjects(@"+48881231+2", [f inputDigit:@"2"], nil);
        
        STAssertEqualObjects(@"+48881231+", [f removeLastDigit], nil);
        STAssertEqualObjects(@"+48 88 123 1", [f removeLastDigit], nil);
        STAssertEqualObjects(@"+48 88 123", [f removeLastDigit], nil);
        STAssertEqualObjects(@"+48 88 12", [f removeLastDigit], nil);
        STAssertEqualObjects(@"+48 88 1", [f removeLastDigit], nil);
        STAssertEqualObjects(@"+48 88", [f removeLastDigit], nil);
        STAssertEqualObjects(@"+48 8", [f removeLastDigit], nil);
        STAssertEqualObjects(@"+48 ", [f removeLastDigit], nil);
        STAssertEqualObjects(@"+4", [f removeLastDigit], nil);
        STAssertEqualObjects(@"+", [f removeLastDigit], nil);
        STAssertEqualObjects(@"", [f removeLastDigit], nil);
    }
    
    //testTooLongNumberMatchingMultipleLeadingDigits()
    {
        // See http://code.google.com/p/libphonenumber/issues/detail?id=36
        // The bug occurred last time for countries which have two formatting rules
        // with exactly the same leading digits pattern but differ in length.
        /** @type {i18n.phonenumbers.AsYouTypeFormatter} */
        NBAsYouTypeFormatter *f = [[NBAsYouTypeFormatter alloc] initWithRegionCodeForTest:@"ZZ"];
        STAssertEqualObjects(@"+", [f inputDigit:@"+"], nil);
        STAssertEqualObjects(@"+8", [f inputDigit:@"8"], nil);
        STAssertEqualObjects(@"+81 ", [f inputDigit:@"1"], nil);
        STAssertEqualObjects(@"+81 9", [f inputDigit:@"9"], nil);
        STAssertEqualObjects(@"+81 90", [f inputDigit:@"0"], nil);
        STAssertEqualObjects(@"+81 90 1", [f inputDigit:@"1"], nil);
        STAssertEqualObjects(@"+81 90 12", [f inputDigit:@"2"], nil);
        STAssertEqualObjects(@"+81 90 123", [f inputDigit:@"3"], nil);
        STAssertEqualObjects(@"+81 90 1234", [f inputDigit:@"4"], nil);
        STAssertEqualObjects(@"+81 90 1234 5", [f inputDigit:@"5"], nil);
        STAssertEqualObjects(@"+81 90 1234 56", [f inputDigit:@"6"], nil);
        STAssertEqualObjects(@"+81 90 1234 567", [f inputDigit:@"7"], nil);
        STAssertEqualObjects(@"+81 90 1234 5678", [f inputDigit:@"8"], nil);
        STAssertEqualObjects(@"+81 90 12 345 6789", [f inputDigit:@"9"], nil);
        STAssertEqualObjects(@"+81901234567890", [f inputDigit:@"0"], nil);
        STAssertEqualObjects(@"+819012345678901", [f inputDigit:@"1"], nil);
    }
    
    // testCountryWithSpaceInNationalPrefixFormattingRule()
    {
        /** @type {i18n.phonenumbers.AsYouTypeFormatter} */
        NBAsYouTypeFormatter *f = [[NBAsYouTypeFormatter alloc] initWithRegionCodeForTest:@"BY"];
        STAssertEqualObjects(@"8", [f inputDigit:@"8"], nil);
        STAssertEqualObjects(@"88", [f inputDigit:@"8"], nil);
        STAssertEqualObjects(@"881", [f inputDigit:@"1"], nil);
        STAssertEqualObjects(@"8 819", [f inputDigit:@"9"], nil);
        STAssertEqualObjects(@"8 8190", [f inputDigit:@"0"], nil);
        // The formatting rule for 5 digit numbers states that no space should be
        // present after the national prefix.
        STAssertEqualObjects(@"881 901", [f inputDigit:@"1"], nil);
        STAssertEqualObjects(@"8 819 012", [f inputDigit:@"2"], nil);
        // Too long, no formatting rule applies.
        STAssertEqualObjects(@"88190123", [f inputDigit:@"3"], nil);
    }
    
    // testCountryWithSpaceInNationalPrefixFormattingRuleAndLongNdd()
    {
        /** @type {i18n.phonenumbers.AsYouTypeFormatter} */
        NBAsYouTypeFormatter *f = [[NBAsYouTypeFormatter alloc] initWithRegionCodeForTest:@"BY"];
        STAssertEqualObjects(@"9", [f inputDigit:@"9"], nil);
        STAssertEqualObjects(@"99", [f inputDigit:@"9"], nil);
        STAssertEqualObjects(@"999", [f inputDigit:@"9"], nil);
        STAssertEqualObjects(@"9999", [f inputDigit:@"9"], nil);
        STAssertEqualObjects(@"99999 ", [f inputDigit:@"9"], nil);
        STAssertEqualObjects(@"99999 1", [f inputDigit:@"1"], nil);
        STAssertEqualObjects(@"99999 12", [f inputDigit:@"2"], nil);
        STAssertEqualObjects(@"99999 123", [f inputDigit:@"3"], nil);
        STAssertEqualObjects(@"99999 1234", [f inputDigit:@"4"], nil);
        STAssertEqualObjects(@"99999 12 345", [f inputDigit:@"5"], nil);
    }
    
    // testAYTFUS()
    {
        /** @type {i18n.phonenumbers.AsYouTypeFormatter} */
        NBAsYouTypeFormatter *f = [[NBAsYouTypeFormatter alloc] initWithRegionCodeForTest:@"US"];
        STAssertEqualObjects(@"6", [f inputDigit:@"6"], nil);
        STAssertEqualObjects(@"65", [f inputDigit:@"5"], nil);
        STAssertEqualObjects(@"650", [f inputDigit:@"0"], nil);
        STAssertEqualObjects(@"650 2", [f inputDigit:@"2"], nil);
        STAssertEqualObjects(@"650 25", [f inputDigit:@"5"], nil);
        STAssertEqualObjects(@"650 253", [f inputDigit:@"3"], nil);
        // Note this is how a US local number (without area code) should be formatted.
        STAssertEqualObjects(@"650 2532", [f inputDigit:@"2"], nil);
        STAssertEqualObjects(@"650 253 22", [f inputDigit:@"2"], nil);
        STAssertEqualObjects(@"650 253 222", [f inputDigit:@"2"], nil);
        STAssertEqualObjects(@"650 253 2222", [f inputDigit:@"2"], nil);
        
        [f clear];
        STAssertEqualObjects(@"1", [f inputDigit:@"1"], nil);
        STAssertEqualObjects(@"16", [f inputDigit:@"6"], nil);
        STAssertEqualObjects(@"1 65", [f inputDigit:@"5"], nil);
        STAssertEqualObjects(@"1 650", [f inputDigit:@"0"], nil);
        STAssertEqualObjects(@"1 650 2", [f inputDigit:@"2"], nil);
        STAssertEqualObjects(@"1 650 25", [f inputDigit:@"5"], nil);
        STAssertEqualObjects(@"1 650 253", [f inputDigit:@"3"], nil);
        STAssertEqualObjects(@"1 650 253 2", [f inputDigit:@"2"], nil);
        STAssertEqualObjects(@"1 650 253 22", [f inputDigit:@"2"], nil);
        STAssertEqualObjects(@"1 650 253 222", [f inputDigit:@"2"], nil);
        STAssertEqualObjects(@"1 650 253 2222", [f inputDigit:@"2"], nil);
        
        [f clear];
        STAssertEqualObjects(@"0", [f inputDigit:@"0"], nil);
        STAssertEqualObjects(@"01", [f inputDigit:@"1"], nil);
        STAssertEqualObjects(@"011 ", [f inputDigit:@"1"], nil);
        STAssertEqualObjects(@"011 4", [f inputDigit:@"4"], nil);
        STAssertEqualObjects(@"011 44 ", [f inputDigit:@"4"], nil);
        STAssertEqualObjects(@"011 44 6", [f inputDigit:@"6"], nil);
        STAssertEqualObjects(@"011 44 61", [f inputDigit:@"1"], nil);
        STAssertEqualObjects(@"011 44 6 12", [f inputDigit:@"2"], nil);
        STAssertEqualObjects(@"011 44 6 123", [f inputDigit:@"3"], nil);
        STAssertEqualObjects(@"011 44 6 123 1", [f inputDigit:@"1"], nil);
        STAssertEqualObjects(@"011 44 6 123 12", [f inputDigit:@"2"], nil);
        STAssertEqualObjects(@"011 44 6 123 123", [f inputDigit:@"3"], nil);
        STAssertEqualObjects(@"011 44 6 123 123 1", [f inputDigit:@"1"], nil);
        STAssertEqualObjects(@"011 44 6 123 123 12", [f inputDigit:@"2"], nil);
        STAssertEqualObjects(@"011 44 6 123 123 123", [f inputDigit:@"3"], nil);
        
        [f clear];
        STAssertEqualObjects(@"0", [f inputDigit:@"0"], nil);
        STAssertEqualObjects(@"01", [f inputDigit:@"1"], nil);
        STAssertEqualObjects(@"011 ", [f inputDigit:@"1"], nil);
        STAssertEqualObjects(@"011 5", [f inputDigit:@"5"], nil);
        STAssertEqualObjects(@"011 54 ", [f inputDigit:@"4"], nil);
        STAssertEqualObjects(@"011 54 9", [f inputDigit:@"9"], nil);
        STAssertEqualObjects(@"011 54 91", [f inputDigit:@"1"], nil);
        STAssertEqualObjects(@"011 54 9 11", [f inputDigit:@"1"], nil);
        STAssertEqualObjects(@"011 54 9 11 2", [f inputDigit:@"2"], nil);
        STAssertEqualObjects(@"011 54 9 11 23", [f inputDigit:@"3"], nil);
        STAssertEqualObjects(@"011 54 9 11 231", [f inputDigit:@"1"], nil);
        STAssertEqualObjects(@"011 54 9 11 2312", [f inputDigit:@"2"], nil);
        STAssertEqualObjects(@"011 54 9 11 2312 1", [f inputDigit:@"1"], nil);
        STAssertEqualObjects(@"011 54 9 11 2312 12", [f inputDigit:@"2"], nil);
        STAssertEqualObjects(@"011 54 9 11 2312 123", [f inputDigit:@"3"], nil);
        STAssertEqualObjects(@"011 54 9 11 2312 1234", [f inputDigit:@"4"], nil);
        
        [f clear];
        STAssertEqualObjects(@"0", [f inputDigit:@"0"], nil);
        STAssertEqualObjects(@"01", [f inputDigit:@"1"], nil);
        STAssertEqualObjects(@"011 ", [f inputDigit:@"1"], nil);
        STAssertEqualObjects(@"011 2", [f inputDigit:@"2"], nil);
        STAssertEqualObjects(@"011 24", [f inputDigit:@"4"], nil);
        STAssertEqualObjects(@"011 244 ", [f inputDigit:@"4"], nil);
        STAssertEqualObjects(@"011 244 2", [f inputDigit:@"2"], nil);
        STAssertEqualObjects(@"011 244 28", [f inputDigit:@"8"], nil);
        STAssertEqualObjects(@"011 244 280", [f inputDigit:@"0"], nil);
        STAssertEqualObjects(@"011 244 280 0", [f inputDigit:@"0"], nil);
        STAssertEqualObjects(@"011 244 280 00", [f inputDigit:@"0"], nil);
        STAssertEqualObjects(@"011 244 280 000", [f inputDigit:@"0"], nil);
        STAssertEqualObjects(@"011 244 280 000 0", [f inputDigit:@"0"], nil);
        STAssertEqualObjects(@"011 244 280 000 00", [f inputDigit:@"0"], nil);
        STAssertEqualObjects(@"011 244 280 000 000", [f inputDigit:@"0"], nil);
        
        [f clear];
        STAssertEqualObjects(@"+", [f inputDigit:@"+"], nil);
        STAssertEqualObjects(@"+4", [f inputDigit:@"4"], nil);
        STAssertEqualObjects(@"+48 ", [f inputDigit:@"8"], nil);
        STAssertEqualObjects(@"+48 8", [f inputDigit:@"8"], nil);
        STAssertEqualObjects(@"+48 88", [f inputDigit:@"8"], nil);
        STAssertEqualObjects(@"+48 88 1", [f inputDigit:@"1"], nil);
        STAssertEqualObjects(@"+48 88 12", [f inputDigit:@"2"], nil);
        STAssertEqualObjects(@"+48 88 123", [f inputDigit:@"3"], nil);
        STAssertEqualObjects(@"+48 88 123 1", [f inputDigit:@"1"], nil);
        STAssertEqualObjects(@"+48 88 123 12", [f inputDigit:@"2"], nil);
        STAssertEqualObjects(@"+48 88 123 12 1", [f inputDigit:@"1"], nil);
        STAssertEqualObjects(@"+48 88 123 12 12", [f inputDigit:@"2"], nil);
    }
    
    //testAYTFUSFullWidthCharacters()
    {
        /** @type {i18n.phonenumbers.AsYouTypeFormatter} */
        NBAsYouTypeFormatter *f = [[NBAsYouTypeFormatter alloc] initWithRegionCodeForTest:@"US"];
        STAssertEqualObjects(@"\uFF16", [f inputDigit:@"\uFF16"], nil);
        STAssertEqualObjects(@"\uFF16\uFF15", [f inputDigit:@"\uFF15"], nil);
        STAssertEqualObjects(@"650", [f inputDigit:@"\uFF10"], nil);
        STAssertEqualObjects(@"650 2", [f inputDigit:@"\uFF12"], nil);
        STAssertEqualObjects(@"650 25", [f inputDigit:@"\uFF15"], nil);
        STAssertEqualObjects(@"650 253", [f inputDigit:@"\uFF13"], nil);
        STAssertEqualObjects(@"650 2532", [f inputDigit:@"\uFF12"], nil);
        STAssertEqualObjects(@"650 253 22", [f inputDigit:@"\uFF12"], nil);
        STAssertEqualObjects(@"650 253 222", [f inputDigit:@"\uFF12"], nil);
        STAssertEqualObjects(@"650 253 2222", [f inputDigit:@"\uFF12"], nil);
    }
    
    // testAYTFUSMobileShortCode()
    {
        /** @type {i18n.phonenumbers.AsYouTypeFormatter} */
        NBAsYouTypeFormatter *f = [[NBAsYouTypeFormatter alloc] initWithRegionCodeForTest:@"US"];
        STAssertEqualObjects(@"*", [f inputDigit:@"*"], nil);
        STAssertEqualObjects(@"*1", [f inputDigit:@"1"], nil);
        STAssertEqualObjects(@"*12", [f inputDigit:@"2"], nil);
        STAssertEqualObjects(@"*121", [f inputDigit:@"1"], nil);
        STAssertEqualObjects(@"*121#", [f inputDigit:@"#"], nil);
    }
    
    // testAYTFUSVanityNumber()
    {
        /** @type {i18n.phonenumbers.AsYouTypeFormatter} */
        NBAsYouTypeFormatter *f = [[NBAsYouTypeFormatter alloc] initWithRegionCodeForTest:@"US"];
        STAssertEqualObjects(@"8", [f inputDigit:@"8"], nil);
        STAssertEqualObjects(@"80", [f inputDigit:@"0"], nil);
        STAssertEqualObjects(@"800", [f inputDigit:@"0"], nil);
        STAssertEqualObjects(@"800 ", [f inputDigit:@" "], nil);
        STAssertEqualObjects(@"800 M", [f inputDigit:@"M"], nil);
        STAssertEqualObjects(@"800 MY", [f inputDigit:@"Y"], nil);
        STAssertEqualObjects(@"800 MY ", [f inputDigit:@" "], nil);
        STAssertEqualObjects(@"800 MY A", [f inputDigit:@"A"], nil);
        STAssertEqualObjects(@"800 MY AP", [f inputDigit:@"P"], nil);
        STAssertEqualObjects(@"800 MY APP", [f inputDigit:@"P"], nil);
        STAssertEqualObjects(@"800 MY APPL", [f inputDigit:@"L"], nil);
        STAssertEqualObjects(@"800 MY APPLE", [f inputDigit:@"E"], nil);
    }
    
    // testAYTFAndRememberPositionUS()
    {
        /** @type {i18n.phonenumbers.AsYouTypeFormatter} */
        NBAsYouTypeFormatter *f = [[NBAsYouTypeFormatter alloc] initWithRegionCodeForTest:@"US"];
        STAssertEqualObjects(@"1", [f inputDigitAndRememberPosition:@"1"], nil);
        STAssertEquals(1, [f getRememberedPosition], nil);
        STAssertEqualObjects(@"16", [f inputDigit:@"6"], nil);
        STAssertEqualObjects(@"1 65", [f inputDigit:@"5"], nil);
        STAssertEquals(1, [f getRememberedPosition], nil);
        STAssertEqualObjects(@"1 650", [f inputDigitAndRememberPosition:@"0"], nil);
        STAssertEquals(5, [f getRememberedPosition], nil);
        STAssertEqualObjects(@"1 650 2", [f inputDigit:@"2"], nil);
        STAssertEqualObjects(@"1 650 25", [f inputDigit:@"5"], nil);
        // Note the remembered position for digit '0' changes from 4 to 5, because a
        // space is now inserted in the front.
        STAssertEquals(5, [f getRememberedPosition], nil);
        STAssertEqualObjects(@"1 650 253", [f inputDigit:@"3"], nil);
        STAssertEqualObjects(@"1 650 253 2", [f inputDigit:@"2"], nil);
        STAssertEqualObjects(@"1 650 253 22", [f inputDigit:@"2"], nil);
        STAssertEquals(5, [f getRememberedPosition], nil);
        STAssertEqualObjects(@"1 650 253 222", [f inputDigitAndRememberPosition:@"2"], nil);
        STAssertEquals(13, [f getRememberedPosition], nil);
        STAssertEqualObjects(@"1 650 253 2222", [f inputDigit:@"2"], nil);
        STAssertEquals(13, [f getRememberedPosition], nil);
        STAssertEqualObjects(@"165025322222", [f inputDigit:@"2"], nil);
        STAssertEquals(10, [f getRememberedPosition], nil);
        STAssertEqualObjects(@"1650253222222", [f inputDigit:@"2"], nil);
        STAssertEquals(10, [f getRememberedPosition], nil);
        
        [f clear];
        STAssertEqualObjects(@"1", [f inputDigit:@"1"], nil);
        STAssertEqualObjects(@"16", [f inputDigitAndRememberPosition:@"6"], nil);
        STAssertEquals(2, [f getRememberedPosition], nil);
        STAssertEqualObjects(@"1 65", [f inputDigit:@"5"], nil);
        STAssertEqualObjects(@"1 650", [f inputDigit:@"0"], nil);
        STAssertEquals(3, [f getRememberedPosition], nil);
        STAssertEqualObjects(@"1 650 2", [f inputDigit:@"2"], nil);
        STAssertEqualObjects(@"1 650 25", [f inputDigit:@"5"], nil);
        STAssertEquals(3, [f getRememberedPosition], nil);
        STAssertEqualObjects(@"1 650 253", [f inputDigit:@"3"], nil);
        STAssertEqualObjects(@"1 650 253 2", [f inputDigit:@"2"], nil);
        STAssertEqualObjects(@"1 650 253 22", [f inputDigit:@"2"], nil);
        STAssertEquals(3, [f getRememberedPosition], nil);
        STAssertEqualObjects(@"1 650 253 222", [f inputDigit:@"2"], nil);
        STAssertEqualObjects(@"1 650 253 2222", [f inputDigit:@"2"], nil);
        STAssertEqualObjects(@"165025322222", [f inputDigit:@"2"], nil);
        STAssertEquals(2, [f getRememberedPosition], nil);
        STAssertEqualObjects(@"1650253222222", [f inputDigit:@"2"], nil);
        STAssertEquals(2, [f getRememberedPosition], nil);
        
        [f clear];
        STAssertEqualObjects(@"6", [f inputDigit:@"6"], nil);
        STAssertEqualObjects(@"65", [f inputDigit:@"5"], nil);
        STAssertEqualObjects(@"650", [f inputDigit:@"0"], nil);
        STAssertEqualObjects(@"650 2", [f inputDigit:@"2"], nil);
        STAssertEqualObjects(@"650 25", [f inputDigit:@"5"], nil);
        STAssertEqualObjects(@"650 253", [f inputDigit:@"3"], nil);
        STAssertEqualObjects(@"650 2532", [f inputDigitAndRememberPosition:@"2"], nil);
        STAssertEquals(8, [f getRememberedPosition], nil);
        STAssertEqualObjects(@"650 253 22", [f inputDigit:@"2"], nil);
        STAssertEquals(9, [f getRememberedPosition], nil);
        STAssertEqualObjects(@"650 253 222", [f inputDigit:@"2"], nil);
        // No more formatting when semicolon is entered.
        STAssertEqualObjects(@"650253222;", [f inputDigit:@";"], nil);
        STAssertEquals(7, [f getRememberedPosition], nil);
        STAssertEqualObjects(@"650253222;2", [f inputDigit:@"2"], nil);
        
        [f clear];
        STAssertEqualObjects(@"6", [f inputDigit:@"6"], nil);
        STAssertEqualObjects(@"65", [f inputDigit:@"5"], nil);
        STAssertEqualObjects(@"650", [f inputDigit:@"0"], nil);
        // No more formatting when users choose to do their own formatting.
        STAssertEqualObjects(@"650-", [f inputDigit:@"-"], nil);
        STAssertEqualObjects(@"650-2", [f inputDigitAndRememberPosition:@"2"], nil);
        STAssertEquals(5, [f getRememberedPosition], nil);
        STAssertEqualObjects(@"650-25", [f inputDigit:@"5"], nil);
        STAssertEquals(5, [f getRememberedPosition], nil);
        STAssertEqualObjects(@"650-253", [f inputDigit:@"3"], nil);
        STAssertEquals(5, [f getRememberedPosition], nil);
        STAssertEqualObjects(@"650-253-", [f inputDigit:@"-"], nil);
        STAssertEqualObjects(@"650-253-2", [f inputDigit:@"2"], nil);
        STAssertEqualObjects(@"650-253-22", [f inputDigit:@"2"], nil);
        STAssertEqualObjects(@"650-253-222", [f inputDigit:@"2"], nil);
        STAssertEqualObjects(@"650-253-2222", [f inputDigit:@"2"], nil);
        
        [f clear];
        STAssertEqualObjects(@"0", [f inputDigit:@"0"], nil);
        STAssertEqualObjects(@"01", [f inputDigit:@"1"], nil);
        STAssertEqualObjects(@"011 ", [f inputDigit:@"1"], nil);
        STAssertEqualObjects(@"011 4", [f inputDigitAndRememberPosition:@"4"], nil);
        STAssertEqualObjects(@"011 48 ", [f inputDigit:@"8"], nil);
        STAssertEquals(5, [f getRememberedPosition], nil);
        STAssertEqualObjects(@"011 48 8", [f inputDigit:@"8"], nil);
        STAssertEquals(5, [f getRememberedPosition], nil);
        STAssertEqualObjects(@"011 48 88", [f inputDigit:@"8"], nil);
        STAssertEqualObjects(@"011 48 88 1", [f inputDigit:@"1"], nil);
        STAssertEqualObjects(@"011 48 88 12", [f inputDigit:@"2"], nil);
        STAssertEquals(5, [f getRememberedPosition], nil);
        STAssertEqualObjects(@"011 48 88 123", [f inputDigit:@"3"], nil);
        STAssertEqualObjects(@"011 48 88 123 1", [f inputDigit:@"1"], nil);
        STAssertEqualObjects(@"011 48 88 123 12", [f inputDigit:@"2"], nil);
        STAssertEqualObjects(@"011 48 88 123 12 1", [f inputDigit:@"1"], nil);
        STAssertEqualObjects(@"011 48 88 123 12 12", [f inputDigit:@"2"], nil);
        
        [f clear];
        STAssertEqualObjects(@"+", [f inputDigit:@"+"], nil);
        STAssertEqualObjects(@"+1", [f inputDigit:@"1"], nil);
        STAssertEqualObjects(@"+1 6", [f inputDigitAndRememberPosition:@"6"], nil);
        STAssertEqualObjects(@"+1 65", [f inputDigit:@"5"], nil);
        STAssertEqualObjects(@"+1 650", [f inputDigit:@"0"], nil);
        STAssertEquals(4, [f getRememberedPosition], nil);
        STAssertEqualObjects(@"+1 650 2", [f inputDigit:@"2"], nil);
        STAssertEquals(4, [f getRememberedPosition], nil);
        STAssertEqualObjects(@"+1 650 25", [f inputDigit:@"5"], nil);
        STAssertEqualObjects(@"+1 650 253", [f inputDigitAndRememberPosition:@"3"], nil);
        STAssertEqualObjects(@"+1 650 253 2", [f inputDigit:@"2"], nil);
        STAssertEqualObjects(@"+1 650 253 22", [f inputDigit:@"2"], nil);
        STAssertEqualObjects(@"+1 650 253 222", [f inputDigit:@"2"], nil);
        STAssertEquals(10, [f getRememberedPosition], nil);
        
        [f clear];
        STAssertEqualObjects(@"+", [f inputDigit:@"+"], nil);
        STAssertEqualObjects(@"+1", [f inputDigit:@"1"], nil);
        STAssertEqualObjects(@"+1 6", [f inputDigitAndRememberPosition:@"6"], nil);
        STAssertEqualObjects(@"+1 65", [f inputDigit:@"5"], nil);
        STAssertEqualObjects(@"+1 650", [f inputDigit:@"0"], nil);
        STAssertEquals(4, [f getRememberedPosition], nil);
        STAssertEqualObjects(@"+1 650 2", [f inputDigit:@"2"], nil);
        STAssertEquals(4, [f getRememberedPosition], nil);
        STAssertEqualObjects(@"+1 650 25", [f inputDigit:@"5"], nil);
        STAssertEqualObjects(@"+1 650 253", [f inputDigit:@"3"], nil);
        STAssertEqualObjects(@"+1 650 253 2", [f inputDigit:@"2"], nil);
        STAssertEqualObjects(@"+1 650 253 22", [f inputDigit:@"2"], nil);
        STAssertEqualObjects(@"+1 650 253 222", [f inputDigit:@"2"], nil);
        STAssertEqualObjects(@"+1650253222;", [f inputDigit:@";"], nil);
        STAssertEquals(3, [f getRememberedPosition], nil);
    }
    
    // testAYTFGBFixedLine()
    {
        /** @type {i18n.phonenumbers.AsYouTypeFormatter} */
        NBAsYouTypeFormatter *f = [[NBAsYouTypeFormatter alloc] initWithRegionCodeForTest:@"GB"];
        STAssertEqualObjects(@"0", [f inputDigit:@"0"], nil);
        STAssertEqualObjects(@"02", [f inputDigit:@"2"], nil);
        STAssertEqualObjects(@"020", [f inputDigit:@"0"], nil);
        STAssertEqualObjects(@"020 7", [f inputDigitAndRememberPosition:@"7"], nil);
        STAssertEquals(5, [f getRememberedPosition], nil);
        STAssertEqualObjects(@"020 70", [f inputDigit:@"0"], nil);
        STAssertEqualObjects(@"020 703", [f inputDigit:@"3"], nil);
        STAssertEquals(5, [f getRememberedPosition], nil);
        STAssertEqualObjects(@"020 7031", [f inputDigit:@"1"], nil);
        STAssertEqualObjects(@"020 7031 3", [f inputDigit:@"3"], nil);
        STAssertEqualObjects(@"020 7031 30", [f inputDigit:@"0"], nil);
        STAssertEqualObjects(@"020 7031 300", [f inputDigit:@"0"], nil);
        STAssertEqualObjects(@"020 7031 3000", [f inputDigit:@"0"], nil);
    }
    
    // testAYTFGBTollFree()
    {
        /** @type {i18n.phonenumbers.AsYouTypeFormatter} */
        NBAsYouTypeFormatter *f = [[NBAsYouTypeFormatter alloc] initWithRegionCodeForTest:@"GB"];
        STAssertEqualObjects(@"0", [f inputDigit:@"0"], nil);
        STAssertEqualObjects(@"08", [f inputDigit:@"8"], nil);
        STAssertEqualObjects(@"080", [f inputDigit:@"0"], nil);
        STAssertEqualObjects(@"080 7", [f inputDigit:@"7"], nil);
        STAssertEqualObjects(@"080 70", [f inputDigit:@"0"], nil);
        STAssertEqualObjects(@"080 703", [f inputDigit:@"3"], nil);
        STAssertEqualObjects(@"080 7031", [f inputDigit:@"1"], nil);
        STAssertEqualObjects(@"080 7031 3", [f inputDigit:@"3"], nil);
        STAssertEqualObjects(@"080 7031 30", [f inputDigit:@"0"], nil);
        STAssertEqualObjects(@"080 7031 300", [f inputDigit:@"0"], nil);
        STAssertEqualObjects(@"080 7031 3000", [f inputDigit:@"0"], nil);
    }
    
    // testAYTFGBPremiumRate()
    {
        /** @type {i18n.phonenumbers.AsYouTypeFormatter} */
        NBAsYouTypeFormatter *f = [[NBAsYouTypeFormatter alloc] initWithRegionCodeForTest:@"GB"];
        STAssertEqualObjects(@"0", [f inputDigit:@"0"], nil);
        STAssertEqualObjects(@"09", [f inputDigit:@"9"], nil);
        STAssertEqualObjects(@"090", [f inputDigit:@"0"], nil);
        STAssertEqualObjects(@"090 7", [f inputDigit:@"7"], nil);
        STAssertEqualObjects(@"090 70", [f inputDigit:@"0"], nil);
        STAssertEqualObjects(@"090 703", [f inputDigit:@"3"], nil);
        STAssertEqualObjects(@"090 7031", [f inputDigit:@"1"], nil);
        STAssertEqualObjects(@"090 7031 3", [f inputDigit:@"3"], nil);
        STAssertEqualObjects(@"090 7031 30", [f inputDigit:@"0"], nil);
        STAssertEqualObjects(@"090 7031 300", [f inputDigit:@"0"], nil);
        STAssertEqualObjects(@"090 7031 3000", [f inputDigit:@"0"], nil);
    }
    
    // testAYTFNZMobile()
    {
        /** @type {i18n.phonenumbers.AsYouTypeFormatter} */
        NBAsYouTypeFormatter *f = [[NBAsYouTypeFormatter alloc] initWithRegionCodeForTest:@"NZ"];
        STAssertEqualObjects(@"0", [f inputDigit:@"0"], nil);
        STAssertEqualObjects(@"02", [f inputDigit:@"2"], nil);
        STAssertEqualObjects(@"021", [f inputDigit:@"1"], nil);
        STAssertEqualObjects(@"02-11", [f inputDigit:@"1"], nil);
        STAssertEqualObjects(@"02-112", [f inputDigit:@"2"], nil);
        // Note the unittest is using fake metadata which might produce non-ideal
        // results.
        STAssertEqualObjects(@"02-112 3", [f inputDigit:@"3"], nil);
        STAssertEqualObjects(@"02-112 34", [f inputDigit:@"4"], nil);
        STAssertEqualObjects(@"02-112 345", [f inputDigit:@"5"], nil);
        STAssertEqualObjects(@"02-112 3456", [f inputDigit:@"6"], nil);
    }
    
    // testAYTFDE()
    {
        /** @type {i18n.phonenumbers.AsYouTypeFormatter} */
        NBAsYouTypeFormatter *f = [[NBAsYouTypeFormatter alloc] initWithRegionCodeForTest:@"DE"];
        STAssertEqualObjects(@"0", [f inputDigit:@"0"], nil);
        STAssertEqualObjects(@"03", [f inputDigit:@"3"], nil);
        STAssertEqualObjects(@"030", [f inputDigit:@"0"], nil);
        STAssertEqualObjects(@"030/1", [f inputDigit:@"1"], nil);
        STAssertEqualObjects(@"030/12", [f inputDigit:@"2"], nil);
        STAssertEqualObjects(@"030/123", [f inputDigit:@"3"], nil);
        STAssertEqualObjects(@"030/1234", [f inputDigit:@"4"], nil);
        
        // 04134 1234
        [f clear];
        STAssertEqualObjects(@"0", [f inputDigit:@"0"], nil);
        STAssertEqualObjects(@"04", [f inputDigit:@"4"], nil);
        STAssertEqualObjects(@"041", [f inputDigit:@"1"], nil);
        STAssertEqualObjects(@"041 3", [f inputDigit:@"3"], nil);
        STAssertEqualObjects(@"041 34", [f inputDigit:@"4"], nil);
        STAssertEqualObjects(@"04134 1", [f inputDigit:@"1"], nil);
        STAssertEqualObjects(@"04134 12", [f inputDigit:@"2"], nil);
        STAssertEqualObjects(@"04134 123", [f inputDigit:@"3"], nil);
        STAssertEqualObjects(@"04134 1234", [f inputDigit:@"4"], nil);
        
        // 08021 2345
        [f clear];
        STAssertEqualObjects(@"0", [f inputDigit:@"0"], nil);
        STAssertEqualObjects(@"08", [f inputDigit:@"8"], nil);
        STAssertEqualObjects(@"080", [f inputDigit:@"0"], nil);
        STAssertEqualObjects(@"080 2", [f inputDigit:@"2"], nil);
        STAssertEqualObjects(@"080 21", [f inputDigit:@"1"], nil);
        STAssertEqualObjects(@"08021 2", [f inputDigit:@"2"], nil);
        STAssertEqualObjects(@"08021 23", [f inputDigit:@"3"], nil);
        STAssertEqualObjects(@"08021 234", [f inputDigit:@"4"], nil);
        STAssertEqualObjects(@"08021 2345", [f inputDigit:@"5"], nil);
        
        // 00 1 650 253 2250
        [f clear];
        STAssertEqualObjects(@"0", [f inputDigit:@"0"], nil);
        STAssertEqualObjects(@"00", [f inputDigit:@"0"], nil);
        STAssertEqualObjects(@"00 1 ", [f inputDigit:@"1"], nil);
        STAssertEqualObjects(@"00 1 6", [f inputDigit:@"6"], nil);
        STAssertEqualObjects(@"00 1 65", [f inputDigit:@"5"], nil);
        STAssertEqualObjects(@"00 1 650", [f inputDigit:@"0"], nil);
        STAssertEqualObjects(@"00 1 650 2", [f inputDigit:@"2"], nil);
        STAssertEqualObjects(@"00 1 650 25", [f inputDigit:@"5"], nil);
        STAssertEqualObjects(@"00 1 650 253", [f inputDigit:@"3"], nil);
        STAssertEqualObjects(@"00 1 650 253 2", [f inputDigit:@"2"], nil);
        STAssertEqualObjects(@"00 1 650 253 22", [f inputDigit:@"2"], nil);
        STAssertEqualObjects(@"00 1 650 253 222", [f inputDigit:@"2"], nil);
        STAssertEqualObjects(@"00 1 650 253 2222", [f inputDigit:@"2"], nil);
    }
    
    // testAYTFAR()
    {
        /** @type {i18n.phonenumbers.AsYouTypeFormatter} */
        NBAsYouTypeFormatter *f = [[NBAsYouTypeFormatter alloc] initWithRegionCodeForTest:@"AR"];
        STAssertEqualObjects(@"0", [f inputDigit:@"0"], nil);
        STAssertEqualObjects(@"01", [f inputDigit:@"1"], nil);
        STAssertEqualObjects(@"011", [f inputDigit:@"1"], nil);
        STAssertEqualObjects(@"011 7", [f inputDigit:@"7"], nil);
        STAssertEqualObjects(@"011 70", [f inputDigit:@"0"], nil);
        STAssertEqualObjects(@"011 703", [f inputDigit:@"3"], nil);
        STAssertEqualObjects(@"011 7031", [f inputDigit:@"1"], nil);
        STAssertEqualObjects(@"011 7031-3", [f inputDigit:@"3"], nil);
        STAssertEqualObjects(@"011 7031-30", [f inputDigit:@"0"], nil);
        STAssertEqualObjects(@"011 7031-300", [f inputDigit:@"0"], nil);
        STAssertEqualObjects(@"011 7031-3000", [f inputDigit:@"0"], nil);
    }
    
    // testAYTFARMobile()
    {
        /** @type {i18n.phonenumbers.AsYouTypeFormatter} */
        NBAsYouTypeFormatter *f = [[NBAsYouTypeFormatter alloc] initWithRegionCodeForTest:@"AR"];
        STAssertEqualObjects(@"+", [f inputDigit:@"+"], nil);
        STAssertEqualObjects(@"+5", [f inputDigit:@"5"], nil);
        STAssertEqualObjects(@"+54 ", [f inputDigit:@"4"], nil);
        STAssertEqualObjects(@"+54 9", [f inputDigit:@"9"], nil);
        STAssertEqualObjects(@"+54 91", [f inputDigit:@"1"], nil);
        STAssertEqualObjects(@"+54 9 11", [f inputDigit:@"1"], nil);
        STAssertEqualObjects(@"+54 9 11 2", [f inputDigit:@"2"], nil);
        STAssertEqualObjects(@"+54 9 11 23", [f inputDigit:@"3"], nil);
        STAssertEqualObjects(@"+54 9 11 231", [f inputDigit:@"1"], nil);
        STAssertEqualObjects(@"+54 9 11 2312", [f inputDigit:@"2"], nil);
        STAssertEqualObjects(@"+54 9 11 2312 1", [f inputDigit:@"1"], nil);
        STAssertEqualObjects(@"+54 9 11 2312 12", [f inputDigit:@"2"], nil);
        STAssertEqualObjects(@"+54 9 11 2312 123", [f inputDigit:@"3"], nil);
        STAssertEqualObjects(@"+54 9 11 2312 1234", [f inputDigit:@"4"], nil);
    }
    
    // testAYTFKR()
    {
        // +82 51 234 5678
        /** @type {i18n.phonenumbers.AsYouTypeFormatter} */
        NBAsYouTypeFormatter *f = [[NBAsYouTypeFormatter alloc] initWithRegionCodeForTest:@"KR"];
        STAssertEqualObjects(@"+", [f inputDigit:@"+"], nil);
        STAssertEqualObjects(@"+8", [f inputDigit:@"8"], nil);
        STAssertEqualObjects(@"+82 ", [f inputDigit:@"2"], nil);
        STAssertEqualObjects(@"+82 5", [f inputDigit:@"5"], nil);
        STAssertEqualObjects(@"+82 51", [f inputDigit:@"1"], nil);
        STAssertEqualObjects(@"+82 51-2", [f inputDigit:@"2"], nil);
        STAssertEqualObjects(@"+82 51-23", [f inputDigit:@"3"], nil);
        STAssertEqualObjects(@"+82 51-234", [f inputDigit:@"4"], nil);
        STAssertEqualObjects(@"+82 51-234-5", [f inputDigit:@"5"], nil);
        STAssertEqualObjects(@"+82 51-234-56", [f inputDigit:@"6"], nil);
        STAssertEqualObjects(@"+82 51-234-567", [f inputDigit:@"7"], nil);
        STAssertEqualObjects(@"+82 51-234-5678", [f inputDigit:@"8"], nil);
        
        // +82 2 531 5678
        [f clear];
        STAssertEqualObjects(@"+", [f inputDigit:@"+"], nil);
        STAssertEqualObjects(@"+8", [f inputDigit:@"8"], nil);
        STAssertEqualObjects(@"+82 ", [f inputDigit:@"2"], nil);
        STAssertEqualObjects(@"+82 2", [f inputDigit:@"2"], nil);
        STAssertEqualObjects(@"+82 25", [f inputDigit:@"5"], nil);
        STAssertEqualObjects(@"+82 2-53", [f inputDigit:@"3"], nil);
        STAssertEqualObjects(@"+82 2-531", [f inputDigit:@"1"], nil);
        STAssertEqualObjects(@"+82 2-531-5", [f inputDigit:@"5"], nil);
        STAssertEqualObjects(@"+82 2-531-56", [f inputDigit:@"6"], nil);
        STAssertEqualObjects(@"+82 2-531-567", [f inputDigit:@"7"], nil);
        STAssertEqualObjects(@"+82 2-531-5678", [f inputDigit:@"8"], nil);
        
        // +82 2 3665 5678
        [f clear];
        STAssertEqualObjects(@"+", [f inputDigit:@"+"], nil);
        STAssertEqualObjects(@"+8", [f inputDigit:@"8"], nil);
        STAssertEqualObjects(@"+82 ", [f inputDigit:@"2"], nil);
        STAssertEqualObjects(@"+82 2", [f inputDigit:@"2"], nil);
        STAssertEqualObjects(@"+82 23", [f inputDigit:@"3"], nil);
        STAssertEqualObjects(@"+82 2-36", [f inputDigit:@"6"], nil);
        STAssertEqualObjects(@"+82 2-366", [f inputDigit:@"6"], nil);
        STAssertEqualObjects(@"+82 2-3665", [f inputDigit:@"5"], nil);
        STAssertEqualObjects(@"+82 2-3665-5", [f inputDigit:@"5"], nil);
        STAssertEqualObjects(@"+82 2-3665-56", [f inputDigit:@"6"], nil);
        STAssertEqualObjects(@"+82 2-3665-567", [f inputDigit:@"7"], nil);
        STAssertEqualObjects(@"+82 2-3665-5678", [f inputDigit:@"8"], nil);
        
        // 02-114
        [f clear];
        STAssertEqualObjects(@"0", [f inputDigit:@"0"], nil);
        STAssertEqualObjects(@"02", [f inputDigit:@"2"], nil);
        STAssertEqualObjects(@"021", [f inputDigit:@"1"], nil);
        STAssertEqualObjects(@"02-11", [f inputDigit:@"1"], nil);
        STAssertEqualObjects(@"02-114", [f inputDigit:@"4"], nil);
        
        // 02-1300
        [f clear];
        STAssertEqualObjects(@"0", [f inputDigit:@"0"], nil);
        STAssertEqualObjects(@"02", [f inputDigit:@"2"], nil);
        STAssertEqualObjects(@"021", [f inputDigit:@"1"], nil);
        STAssertEqualObjects(@"02-13", [f inputDigit:@"3"], nil);
        STAssertEqualObjects(@"02-130", [f inputDigit:@"0"], nil);
        STAssertEqualObjects(@"02-1300", [f inputDigit:@"0"], nil);
        
        // 011-456-7890
        [f clear];
        STAssertEqualObjects(@"0", [f inputDigit:@"0"], nil);
        STAssertEqualObjects(@"01", [f inputDigit:@"1"], nil);
        STAssertEqualObjects(@"011", [f inputDigit:@"1"], nil);
        STAssertEqualObjects(@"011-4", [f inputDigit:@"4"], nil);
        STAssertEqualObjects(@"011-45", [f inputDigit:@"5"], nil);
        STAssertEqualObjects(@"011-456", [f inputDigit:@"6"], nil);
        STAssertEqualObjects(@"011-456-7", [f inputDigit:@"7"], nil);
        STAssertEqualObjects(@"011-456-78", [f inputDigit:@"8"], nil);
        STAssertEqualObjects(@"011-456-789", [f inputDigit:@"9"], nil);
        STAssertEqualObjects(@"011-456-7890", [f inputDigit:@"0"], nil);
        
        // 011-9876-7890
        [f clear];
        STAssertEqualObjects(@"0", [f inputDigit:@"0"], nil);
        STAssertEqualObjects(@"01", [f inputDigit:@"1"], nil);
        STAssertEqualObjects(@"011", [f inputDigit:@"1"], nil);
        STAssertEqualObjects(@"011-9", [f inputDigit:@"9"], nil);
        STAssertEqualObjects(@"011-98", [f inputDigit:@"8"], nil);
        STAssertEqualObjects(@"011-987", [f inputDigit:@"7"], nil);
        STAssertEqualObjects(@"011-9876", [f inputDigit:@"6"], nil);
        STAssertEqualObjects(@"011-9876-7", [f inputDigit:@"7"], nil);
        STAssertEqualObjects(@"011-9876-78", [f inputDigit:@"8"], nil);
        STAssertEqualObjects(@"011-9876-789", [f inputDigit:@"9"], nil);
        STAssertEqualObjects(@"011-9876-7890", [f inputDigit:@"0"], nil);
    }
    
    // testAYTF_MX()
    {
        /** @type {i18n.phonenumbers.AsYouTypeFormatter} */
        NBAsYouTypeFormatter *f = [[NBAsYouTypeFormatter alloc] initWithRegionCodeForTest:@"MX"];
        
        // +52 800 123 4567
        STAssertEqualObjects(@"+", [f inputDigit:@"+"], nil);
        STAssertEqualObjects(@"+5", [f inputDigit:@"5"], nil);
        STAssertEqualObjects(@"+52 ", [f inputDigit:@"2"], nil);
        STAssertEqualObjects(@"+52 8", [f inputDigit:@"8"], nil);
        STAssertEqualObjects(@"+52 80", [f inputDigit:@"0"], nil);
        STAssertEqualObjects(@"+52 800", [f inputDigit:@"0"], nil);
        STAssertEqualObjects(@"+52 800 1", [f inputDigit:@"1"], nil);
        STAssertEqualObjects(@"+52 800 12", [f inputDigit:@"2"], nil);
        STAssertEqualObjects(@"+52 800 123", [f inputDigit:@"3"], nil);
        STAssertEqualObjects(@"+52 800 123 4", [f inputDigit:@"4"], nil);
        STAssertEqualObjects(@"+52 800 123 45", [f inputDigit:@"5"], nil);
        STAssertEqualObjects(@"+52 800 123 456", [f inputDigit:@"6"], nil);
        STAssertEqualObjects(@"+52 800 123 4567", [f inputDigit:@"7"], nil);
        
        // +52 55 1234 5678
        [f clear];
        STAssertEqualObjects(@"+", [f inputDigit:@"+"], nil);
        STAssertEqualObjects(@"+5", [f inputDigit:@"5"], nil);
        STAssertEqualObjects(@"+52 ", [f inputDigit:@"2"], nil);
        STAssertEqualObjects(@"+52 5", [f inputDigit:@"5"], nil);
        STAssertEqualObjects(@"+52 55", [f inputDigit:@"5"], nil);
        STAssertEqualObjects(@"+52 55 1", [f inputDigit:@"1"], nil);
        STAssertEqualObjects(@"+52 55 12", [f inputDigit:@"2"], nil);
        STAssertEqualObjects(@"+52 55 123", [f inputDigit:@"3"], nil);
        STAssertEqualObjects(@"+52 55 1234", [f inputDigit:@"4"], nil);
        STAssertEqualObjects(@"+52 55 1234 5", [f inputDigit:@"5"], nil);
        STAssertEqualObjects(@"+52 55 1234 56", [f inputDigit:@"6"], nil);
        STAssertEqualObjects(@"+52 55 1234 567", [f inputDigit:@"7"], nil);
        STAssertEqualObjects(@"+52 55 1234 5678", [f inputDigit:@"8"], nil);
        
        // +52 212 345 6789
        [f clear];
        STAssertEqualObjects(@"+", [f inputDigit:@"+"], nil);
        STAssertEqualObjects(@"+5", [f inputDigit:@"5"], nil);
        STAssertEqualObjects(@"+52 ", [f inputDigit:@"2"], nil);
        STAssertEqualObjects(@"+52 2", [f inputDigit:@"2"], nil);
        STAssertEqualObjects(@"+52 21", [f inputDigit:@"1"], nil);
        STAssertEqualObjects(@"+52 212", [f inputDigit:@"2"], nil);
        STAssertEqualObjects(@"+52 212 3", [f inputDigit:@"3"], nil);
        STAssertEqualObjects(@"+52 212 34", [f inputDigit:@"4"], nil);
        STAssertEqualObjects(@"+52 212 345", [f inputDigit:@"5"], nil);
        STAssertEqualObjects(@"+52 212 345 6", [f inputDigit:@"6"], nil);
        STAssertEqualObjects(@"+52 212 345 67", [f inputDigit:@"7"], nil);
        STAssertEqualObjects(@"+52 212 345 678", [f inputDigit:@"8"], nil);
        STAssertEqualObjects(@"+52 212 345 6789", [f inputDigit:@"9"], nil);
        
        // +52 1 55 1234 5678
        [f clear];
        STAssertEqualObjects(@"+", [f inputDigit:@"+"], nil);
        STAssertEqualObjects(@"+5", [f inputDigit:@"5"], nil);
        STAssertEqualObjects(@"+52 ", [f inputDigit:@"2"], nil);
        STAssertEqualObjects(@"+52 1", [f inputDigit:@"1"], nil);
        STAssertEqualObjects(@"+52 15", [f inputDigit:@"5"], nil);
        STAssertEqualObjects(@"+52 1 55", [f inputDigit:@"5"], nil);
        STAssertEqualObjects(@"+52 1 55 1", [f inputDigit:@"1"], nil);
        STAssertEqualObjects(@"+52 1 55 12", [f inputDigit:@"2"], nil);
        STAssertEqualObjects(@"+52 1 55 123", [f inputDigit:@"3"], nil);
        STAssertEqualObjects(@"+52 1 55 1234", [f inputDigit:@"4"], nil);
        STAssertEqualObjects(@"+52 1 55 1234 5", [f inputDigit:@"5"], nil);
        STAssertEqualObjects(@"+52 1 55 1234 56", [f inputDigit:@"6"], nil);
        STAssertEqualObjects(@"+52 1 55 1234 567", [f inputDigit:@"7"], nil);
        STAssertEqualObjects(@"+52 1 55 1234 5678", [f inputDigit:@"8"], nil);
        
        // +52 1 541 234 5678
        [f clear];
        STAssertEqualObjects(@"+", [f inputDigit:@"+"], nil);
        STAssertEqualObjects(@"+5", [f inputDigit:@"5"], nil);
        STAssertEqualObjects(@"+52 ", [f inputDigit:@"2"], nil);
        STAssertEqualObjects(@"+52 1", [f inputDigit:@"1"], nil);
        STAssertEqualObjects(@"+52 15", [f inputDigit:@"5"], nil);
        STAssertEqualObjects(@"+52 1 54", [f inputDigit:@"4"], nil);
        STAssertEqualObjects(@"+52 1 541", [f inputDigit:@"1"], nil);
        STAssertEqualObjects(@"+52 1 541 2", [f inputDigit:@"2"], nil);
        STAssertEqualObjects(@"+52 1 541 23", [f inputDigit:@"3"], nil);
        STAssertEqualObjects(@"+52 1 541 234", [f inputDigit:@"4"], nil);
        STAssertEqualObjects(@"+52 1 541 234 5", [f inputDigit:@"5"], nil);
        STAssertEqualObjects(@"+52 1 541 234 56", [f inputDigit:@"6"], nil);
        STAssertEqualObjects(@"+52 1 541 234 567", [f inputDigit:@"7"], nil);
        STAssertEqualObjects(@"+52 1 541 234 5678", [f inputDigit:@"8"], nil);
    }
    
    // testAYTF_International_Toll_Free()
    {
        /** @type {i18n.phonenumbers.AsYouTypeFormatter} */
        NBAsYouTypeFormatter *f = [[NBAsYouTypeFormatter alloc] initWithRegionCodeForTest:@"US"];
        // +800 1234 5678
        STAssertEqualObjects(@"+", [f inputDigit:@"+"], nil);
        STAssertEqualObjects(@"+8", [f inputDigit:@"8"], nil);
        STAssertEqualObjects(@"+80", [f inputDigit:@"0"], nil);
        STAssertEqualObjects(@"+800 ", [f inputDigit:@"0"], nil);
        STAssertEqualObjects(@"+800 1", [f inputDigit:@"1"], nil);
        STAssertEqualObjects(@"+800 12", [f inputDigit:@"2"], nil);
        STAssertEqualObjects(@"+800 123", [f inputDigit:@"3"], nil);
        STAssertEqualObjects(@"+800 1234", [f inputDigit:@"4"], nil);
        STAssertEqualObjects(@"+800 1234 5", [f inputDigit:@"5"], nil);
        STAssertEqualObjects(@"+800 1234 56", [f inputDigit:@"6"], nil);
        STAssertEqualObjects(@"+800 1234 567", [f inputDigit:@"7"], nil);
        STAssertEqualObjects(@"+800 1234 5678", [f inputDigit:@"8"], nil);
        STAssertEqualObjects(@"+800123456789", [f inputDigit:@"9"], nil);
    }
    
    // testAYTFMultipleLeadingDigitPatterns()
    {
        // +81 50 2345 6789
        /** @type {i18n.phonenumbers.AsYouTypeFormatter} */
        NBAsYouTypeFormatter *f = [[NBAsYouTypeFormatter alloc] initWithRegionCodeForTest:@"JP"];
        STAssertEqualObjects(@"+", [f inputDigit:@"+"], nil);
        STAssertEqualObjects(@"+8", [f inputDigit:@"8"], nil);
        STAssertEqualObjects(@"+81 ", [f inputDigit:@"1"], nil);
        STAssertEqualObjects(@"+81 5", [f inputDigit:@"5"], nil);
        STAssertEqualObjects(@"+81 50", [f inputDigit:@"0"], nil);
        STAssertEqualObjects(@"+81 50 2", [f inputDigit:@"2"], nil);
        STAssertEqualObjects(@"+81 50 23", [f inputDigit:@"3"], nil);
        STAssertEqualObjects(@"+81 50 234", [f inputDigit:@"4"], nil);
        STAssertEqualObjects(@"+81 50 2345", [f inputDigit:@"5"], nil);
        STAssertEqualObjects(@"+81 50 2345 6", [f inputDigit:@"6"], nil);
        STAssertEqualObjects(@"+81 50 2345 67", [f inputDigit:@"7"], nil);
        STAssertEqualObjects(@"+81 50 2345 678", [f inputDigit:@"8"], nil);
        STAssertEqualObjects(@"+81 50 2345 6789", [f inputDigit:@"9"], nil);
        
        // +81 222 12 5678
        [f clear];
        STAssertEqualObjects(@"+", [f inputDigit:@"+"], nil);
        STAssertEqualObjects(@"+8", [f inputDigit:@"8"], nil);
        STAssertEqualObjects(@"+81 ", [f inputDigit:@"1"], nil);
        STAssertEqualObjects(@"+81 2", [f inputDigit:@"2"], nil);
        STAssertEqualObjects(@"+81 22", [f inputDigit:@"2"], nil);
        STAssertEqualObjects(@"+81 22 2", [f inputDigit:@"2"], nil);
        STAssertEqualObjects(@"+81 22 21", [f inputDigit:@"1"], nil);
        STAssertEqualObjects(@"+81 2221 2", [f inputDigit:@"2"], nil);
        STAssertEqualObjects(@"+81 222 12 5", [f inputDigit:@"5"], nil);
        STAssertEqualObjects(@"+81 222 12 56", [f inputDigit:@"6"], nil);
        STAssertEqualObjects(@"+81 222 12 567", [f inputDigit:@"7"], nil);
        STAssertEqualObjects(@"+81 222 12 5678", [f inputDigit:@"8"], nil);
        
        // 011113
        [f clear];
        STAssertEqualObjects(@"0", [f inputDigit:@"0"], nil);
        STAssertEqualObjects(@"01", [f inputDigit:@"1"], nil);
        STAssertEqualObjects(@"011", [f inputDigit:@"1"], nil);
        STAssertEqualObjects(@"011 1", [f inputDigit:@"1"], nil);
        STAssertEqualObjects(@"011 11", [f inputDigit:@"1"], nil);
        STAssertEqualObjects(@"011113", [f inputDigit:@"3"], nil);
        
        // +81 3332 2 5678
        [f clear];
        STAssertEqualObjects(@"+", [f inputDigit:@"+"], nil);
        STAssertEqualObjects(@"+8", [f inputDigit:@"8"], nil);
        STAssertEqualObjects(@"+81 ", [f inputDigit:@"1"], nil);
        STAssertEqualObjects(@"+81 3", [f inputDigit:@"3"], nil);
        STAssertEqualObjects(@"+81 33", [f inputDigit:@"3"], nil);
        STAssertEqualObjects(@"+81 33 3", [f inputDigit:@"3"], nil);
        STAssertEqualObjects(@"+81 3332", [f inputDigit:@"2"], nil);
        STAssertEqualObjects(@"+81 3332 2", [f inputDigit:@"2"], nil);
        STAssertEqualObjects(@"+81 3332 2 5", [f inputDigit:@"5"], nil);
        STAssertEqualObjects(@"+81 3332 2 56", [f inputDigit:@"6"], nil);
        STAssertEqualObjects(@"+81 3332 2 567", [f inputDigit:@"7"], nil);
        STAssertEqualObjects(@"+81 3332 2 5678", [f inputDigit:@"8"], nil);
    }
    
    // testAYTFLongIDD_AU()
    {
        /** @type {i18n.phonenumbers.AsYouTypeFormatter} */
        NBAsYouTypeFormatter *f = [[NBAsYouTypeFormatter alloc] initWithRegionCodeForTest:@"AU"];
        // 0011 1 650 253 2250
        STAssertEqualObjects(@"0", [f inputDigit:@"0"], nil);
        STAssertEqualObjects(@"00", [f inputDigit:@"0"], nil);
        STAssertEqualObjects(@"001", [f inputDigit:@"1"], nil);
        STAssertEqualObjects(@"0011", [f inputDigit:@"1"], nil);
        STAssertEqualObjects(@"0011 1 ", [f inputDigit:@"1"], nil);
        STAssertEqualObjects(@"0011 1 6", [f inputDigit:@"6"], nil);
        STAssertEqualObjects(@"0011 1 65", [f inputDigit:@"5"], nil);
        STAssertEqualObjects(@"0011 1 650", [f inputDigit:@"0"], nil);
        STAssertEqualObjects(@"0011 1 650 2", [f inputDigit:@"2"], nil);
        STAssertEqualObjects(@"0011 1 650 25", [f inputDigit:@"5"], nil);
        STAssertEqualObjects(@"0011 1 650 253", [f inputDigit:@"3"], nil);
        STAssertEqualObjects(@"0011 1 650 253 2", [f inputDigit:@"2"], nil);
        STAssertEqualObjects(@"0011 1 650 253 22", [f inputDigit:@"2"], nil);
        STAssertEqualObjects(@"0011 1 650 253 222", [f inputDigit:@"2"], nil);
        STAssertEqualObjects(@"0011 1 650 253 2222", [f inputDigit:@"2"], nil);
        
        // 0011 81 3332 2 5678
        [f clear];
        STAssertEqualObjects(@"0", [f inputDigit:@"0"], nil);
        STAssertEqualObjects(@"00", [f inputDigit:@"0"], nil);
        STAssertEqualObjects(@"001", [f inputDigit:@"1"], nil);
        STAssertEqualObjects(@"0011", [f inputDigit:@"1"], nil);
        STAssertEqualObjects(@"00118", [f inputDigit:@"8"], nil);
        STAssertEqualObjects(@"0011 81 ", [f inputDigit:@"1"], nil);
        STAssertEqualObjects(@"0011 81 3", [f inputDigit:@"3"], nil);
        STAssertEqualObjects(@"0011 81 33", [f inputDigit:@"3"], nil);
        STAssertEqualObjects(@"0011 81 33 3", [f inputDigit:@"3"], nil);
        STAssertEqualObjects(@"0011 81 3332", [f inputDigit:@"2"], nil);
        STAssertEqualObjects(@"0011 81 3332 2", [f inputDigit:@"2"], nil);
        STAssertEqualObjects(@"0011 81 3332 2 5", [f inputDigit:@"5"], nil);
        STAssertEqualObjects(@"0011 81 3332 2 56", [f inputDigit:@"6"], nil);
        STAssertEqualObjects(@"0011 81 3332 2 567", [f inputDigit:@"7"], nil);
        STAssertEqualObjects(@"0011 81 3332 2 5678", [f inputDigit:@"8"], nil);
        
        // 0011 244 250 253 222
        [f clear];
        STAssertEqualObjects(@"0", [f inputDigit:@"0"], nil);
        STAssertEqualObjects(@"00", [f inputDigit:@"0"], nil);
        STAssertEqualObjects(@"001", [f inputDigit:@"1"], nil);
        STAssertEqualObjects(@"0011", [f inputDigit:@"1"], nil);
        STAssertEqualObjects(@"00112", [f inputDigit:@"2"], nil);
        STAssertEqualObjects(@"001124", [f inputDigit:@"4"], nil);
        STAssertEqualObjects(@"0011 244 ", [f inputDigit:@"4"], nil);
        STAssertEqualObjects(@"0011 244 2", [f inputDigit:@"2"], nil);
        STAssertEqualObjects(@"0011 244 25", [f inputDigit:@"5"], nil);
        STAssertEqualObjects(@"0011 244 250", [f inputDigit:@"0"], nil);
        STAssertEqualObjects(@"0011 244 250 2", [f inputDigit:@"2"], nil);
        STAssertEqualObjects(@"0011 244 250 25", [f inputDigit:@"5"], nil);
        STAssertEqualObjects(@"0011 244 250 253", [f inputDigit:@"3"], nil);
        STAssertEqualObjects(@"0011 244 250 253 2", [f inputDigit:@"2"], nil);
        STAssertEqualObjects(@"0011 244 250 253 22", [f inputDigit:@"2"], nil);
        STAssertEqualObjects(@"0011 244 250 253 222", [f inputDigit:@"2"], nil);
    }
    
    // testAYTFLongIDD_KR()
    {
        /** @type {i18n.phonenumbers.AsYouTypeFormatter} */
        NBAsYouTypeFormatter *f = [[NBAsYouTypeFormatter alloc] initWithRegionCodeForTest:@"KR"];
        // 00300 1 650 253 2222
        STAssertEqualObjects(@"0", [f inputDigit:@"0"], nil);
        STAssertEqualObjects(@"00", [f inputDigit:@"0"], nil);
        STAssertEqualObjects(@"003", [f inputDigit:@"3"], nil);
        STAssertEqualObjects(@"0030", [f inputDigit:@"0"], nil);
        STAssertEqualObjects(@"00300", [f inputDigit:@"0"], nil);
        STAssertEqualObjects(@"00300 1 ", [f inputDigit:@"1"], nil);
        STAssertEqualObjects(@"00300 1 6", [f inputDigit:@"6"], nil);
        STAssertEqualObjects(@"00300 1 65", [f inputDigit:@"5"], nil);
        STAssertEqualObjects(@"00300 1 650", [f inputDigit:@"0"], nil);
        STAssertEqualObjects(@"00300 1 650 2", [f inputDigit:@"2"], nil);
        STAssertEqualObjects(@"00300 1 650 25", [f inputDigit:@"5"], nil);
        STAssertEqualObjects(@"00300 1 650 253", [f inputDigit:@"3"], nil);
        STAssertEqualObjects(@"00300 1 650 253 2", [f inputDigit:@"2"], nil);
        STAssertEqualObjects(@"00300 1 650 253 22", [f inputDigit:@"2"], nil);
        STAssertEqualObjects(@"00300 1 650 253 222", [f inputDigit:@"2"], nil);
        STAssertEqualObjects(@"00300 1 650 253 2222", [f inputDigit:@"2"], nil);
    }
    
    // testAYTFLongNDD_KR()
    {
        /** @type {i18n.phonenumbers.AsYouTypeFormatter} */
        NBAsYouTypeFormatter *f = [[NBAsYouTypeFormatter alloc] initWithRegionCodeForTest:@"KR"];
        // 08811-9876-7890
        STAssertEqualObjects(@"0", [f inputDigit:@"0"], nil);
        STAssertEqualObjects(@"08", [f inputDigit:@"8"], nil);
        STAssertEqualObjects(@"088", [f inputDigit:@"8"], nil);
        STAssertEqualObjects(@"0881", [f inputDigit:@"1"], nil);
        STAssertEqualObjects(@"08811", [f inputDigit:@"1"], nil);
        STAssertEqualObjects(@"08811-9", [f inputDigit:@"9"], nil);
        STAssertEqualObjects(@"08811-98", [f inputDigit:@"8"], nil);
        STAssertEqualObjects(@"08811-987", [f inputDigit:@"7"], nil);
        STAssertEqualObjects(@"08811-9876", [f inputDigit:@"6"], nil);
        STAssertEqualObjects(@"08811-9876-7", [f inputDigit:@"7"], nil);
        STAssertEqualObjects(@"08811-9876-78", [f inputDigit:@"8"], nil);
        STAssertEqualObjects(@"08811-9876-789", [f inputDigit:@"9"], nil);
        STAssertEqualObjects(@"08811-9876-7890", [f inputDigit:@"0"], nil);
        
        // 08500 11-9876-7890
        [f clear];
        STAssertEqualObjects(@"0", [f inputDigit:@"0"], nil);
        STAssertEqualObjects(@"08", [f inputDigit:@"8"], nil);
        STAssertEqualObjects(@"085", [f inputDigit:@"5"], nil);
        STAssertEqualObjects(@"0850", [f inputDigit:@"0"], nil);
        STAssertEqualObjects(@"08500 ", [f inputDigit:@"0"], nil);
        STAssertEqualObjects(@"08500 1", [f inputDigit:@"1"], nil);
        STAssertEqualObjects(@"08500 11", [f inputDigit:@"1"], nil);
        STAssertEqualObjects(@"08500 11-9", [f inputDigit:@"9"], nil);
        STAssertEqualObjects(@"08500 11-98", [f inputDigit:@"8"], nil);
        STAssertEqualObjects(@"08500 11-987", [f inputDigit:@"7"], nil);
        STAssertEqualObjects(@"08500 11-9876", [f inputDigit:@"6"], nil);
        STAssertEqualObjects(@"08500 11-9876-7", [f inputDigit:@"7"], nil);
        STAssertEqualObjects(@"08500 11-9876-78", [f inputDigit:@"8"], nil);
        STAssertEqualObjects(@"08500 11-9876-789", [f inputDigit:@"9"], nil);
        STAssertEqualObjects(@"08500 11-9876-7890", [f inputDigit:@"0"], nil);
    }
    
    // testAYTFLongNDD_SG()
    {
        /** @type {i18n.phonenumbers.AsYouTypeFormatter} */
        NBAsYouTypeFormatter *f = [[NBAsYouTypeFormatter alloc] initWithRegionCodeForTest:@"SG"];
        // 777777 9876 7890
        STAssertEqualObjects(@"7", [f inputDigit:@"7"], nil);
        STAssertEqualObjects(@"77", [f inputDigit:@"7"], nil);
        STAssertEqualObjects(@"777", [f inputDigit:@"7"], nil);
        STAssertEqualObjects(@"7777", [f inputDigit:@"7"], nil);
        STAssertEqualObjects(@"77777", [f inputDigit:@"7"], nil);
        STAssertEqualObjects(@"777777 ", [f inputDigit:@"7"], nil);
        STAssertEqualObjects(@"777777 9", [f inputDigit:@"9"], nil);
        STAssertEqualObjects(@"777777 98", [f inputDigit:@"8"], nil);
        STAssertEqualObjects(@"777777 987", [f inputDigit:@"7"], nil);
        STAssertEqualObjects(@"777777 9876", [f inputDigit:@"6"], nil);
        STAssertEqualObjects(@"777777 9876 7", [f inputDigit:@"7"], nil);
        STAssertEqualObjects(@"777777 9876 78", [f inputDigit:@"8"], nil);
        STAssertEqualObjects(@"777777 9876 789", [f inputDigit:@"9"], nil);
        STAssertEqualObjects(@"777777 9876 7890", [f inputDigit:@"0"], nil);
    }
    
    // testAYTFShortNumberFormattingFix_AU()
    {
        // For Australia, the national prefix is not optional when formatting.
        /** @type {i18n.phonenumbers.AsYouTypeFormatter} */
        NBAsYouTypeFormatter *f = [[NBAsYouTypeFormatter alloc] initWithRegionCodeForTest:@"AU"];
        
        // 1234567890 - For leading digit 1, the national prefix formatting rule has
        // first group only.
        STAssertEqualObjects(@"1", [f inputDigit:@"1"], nil);
        STAssertEqualObjects(@"12", [f inputDigit:@"2"], nil);
        STAssertEqualObjects(@"123", [f inputDigit:@"3"], nil);
        STAssertEqualObjects(@"1234", [f inputDigit:@"4"], nil);
        STAssertEqualObjects(@"1234 5", [f inputDigit:@"5"], nil);
        STAssertEqualObjects(@"1234 56", [f inputDigit:@"6"], nil);
        STAssertEqualObjects(@"1234 567", [f inputDigit:@"7"], nil);
        STAssertEqualObjects(@"1234 567 8", [f inputDigit:@"8"], nil);
        STAssertEqualObjects(@"1234 567 89", [f inputDigit:@"9"], nil);
        STAssertEqualObjects(@"1234 567 890", [f inputDigit:@"0"], nil);
        
        // +61 1234 567 890 - Test the same number, but with the country code.
        [f clear];
        STAssertEqualObjects(@"+", [f inputDigit:@"+"], nil);
        STAssertEqualObjects(@"+6", [f inputDigit:@"6"], nil);
        STAssertEqualObjects(@"+61 ", [f inputDigit:@"1"], nil);
        STAssertEqualObjects(@"+61 1", [f inputDigit:@"1"], nil);
        STAssertEqualObjects(@"+61 12", [f inputDigit:@"2"], nil);
        STAssertEqualObjects(@"+61 123", [f inputDigit:@"3"], nil);
        STAssertEqualObjects(@"+61 1234", [f inputDigit:@"4"], nil);
        STAssertEqualObjects(@"+61 1234 5", [f inputDigit:@"5"], nil);
        STAssertEqualObjects(@"+61 1234 56", [f inputDigit:@"6"], nil);
        STAssertEqualObjects(@"+61 1234 567", [f inputDigit:@"7"], nil);
        STAssertEqualObjects(@"+61 1234 567 8", [f inputDigit:@"8"], nil);
        STAssertEqualObjects(@"+61 1234 567 89", [f inputDigit:@"9"], nil);
        STAssertEqualObjects(@"+61 1234 567 890", [f inputDigit:@"0"], nil);
        
        // 212345678 - For leading digit 2, the national prefix formatting rule puts
        // the national prefix before the first group.
        [f clear];
        STAssertEqualObjects(@"0", [f inputDigit:@"0"], nil);
        STAssertEqualObjects(@"02", [f inputDigit:@"2"], nil);
        STAssertEqualObjects(@"021", [f inputDigit:@"1"], nil);
        STAssertEqualObjects(@"02 12", [f inputDigit:@"2"], nil);
        STAssertEqualObjects(@"02 123", [f inputDigit:@"3"], nil);
        STAssertEqualObjects(@"02 1234", [f inputDigit:@"4"], nil);
        STAssertEqualObjects(@"02 1234 5", [f inputDigit:@"5"], nil);
        STAssertEqualObjects(@"02 1234 56", [f inputDigit:@"6"], nil);
        STAssertEqualObjects(@"02 1234 567", [f inputDigit:@"7"], nil);
        STAssertEqualObjects(@"02 1234 5678", [f inputDigit:@"8"], nil);
        
        // 212345678 - Test the same number, but without the leading 0.
        [f clear];
        STAssertEqualObjects(@"2", [f inputDigit:@"2"], nil);
        STAssertEqualObjects(@"21", [f inputDigit:@"1"], nil);
        STAssertEqualObjects(@"212", [f inputDigit:@"2"], nil);
        STAssertEqualObjects(@"2123", [f inputDigit:@"3"], nil);
        STAssertEqualObjects(@"21234", [f inputDigit:@"4"], nil);
        STAssertEqualObjects(@"212345", [f inputDigit:@"5"], nil);
        STAssertEqualObjects(@"2123456", [f inputDigit:@"6"], nil);
        STAssertEqualObjects(@"21234567", [f inputDigit:@"7"], nil);
        STAssertEqualObjects(@"212345678", [f inputDigit:@"8"], nil);
        
        // +61 2 1234 5678 - Test the same number, but with the country code.
        [f clear];
        STAssertEqualObjects(@"+", [f inputDigit:@"+"], nil);
        STAssertEqualObjects(@"+6", [f inputDigit:@"6"], nil);
        STAssertEqualObjects(@"+61 ", [f inputDigit:@"1"], nil);
        STAssertEqualObjects(@"+61 2", [f inputDigit:@"2"], nil);
        STAssertEqualObjects(@"+61 21", [f inputDigit:@"1"], nil);
        STAssertEqualObjects(@"+61 2 12", [f inputDigit:@"2"], nil);
        STAssertEqualObjects(@"+61 2 123", [f inputDigit:@"3"], nil);
        STAssertEqualObjects(@"+61 2 1234", [f inputDigit:@"4"], nil);
        STAssertEqualObjects(@"+61 2 1234 5", [f inputDigit:@"5"], nil);
        STAssertEqualObjects(@"+61 2 1234 56", [f inputDigit:@"6"], nil);
        STAssertEqualObjects(@"+61 2 1234 567", [f inputDigit:@"7"], nil);
        STAssertEqualObjects(@"+61 2 1234 5678", [f inputDigit:@"8"], nil);
    }
    
    // testAYTFShortNumberFormattingFix_KR()
    {
        // For Korea, the national prefix is not optional when formatting, and the
        // national prefix formatting rule doesn't consist of only the first group.
        /** @type {i18n.phonenumbers.AsYouTypeFormatter} */
        NBAsYouTypeFormatter *f = [[NBAsYouTypeFormatter alloc] initWithRegionCodeForTest:@"KR"];
        
        // 111
        STAssertEqualObjects(@"1", [f inputDigit:@"1"], nil);
        STAssertEqualObjects(@"11", [f inputDigit:@"1"], nil);
        STAssertEqualObjects(@"111", [f inputDigit:@"1"], nil);
        
        // 114
        [f clear];
        STAssertEqualObjects(@"1", [f inputDigit:@"1"], nil);
        STAssertEqualObjects(@"11", [f inputDigit:@"1"], nil);
        STAssertEqualObjects(@"114", [f inputDigit:@"4"], nil);
        
        // 13121234 - Test a mobile number without the national prefix. Even though it
        // is not an emergency number, it should be formatted as a block.
        [f clear];
        STAssertEqualObjects(@"1", [f inputDigit:@"1"], nil);
        STAssertEqualObjects(@"13", [f inputDigit:@"3"], nil);
        STAssertEqualObjects(@"131", [f inputDigit:@"1"], nil);
        STAssertEqualObjects(@"1312", [f inputDigit:@"2"], nil);
        STAssertEqualObjects(@"13121", [f inputDigit:@"1"], nil);
        STAssertEqualObjects(@"131212", [f inputDigit:@"2"], nil);
        STAssertEqualObjects(@"1312123", [f inputDigit:@"3"], nil);
        STAssertEqualObjects(@"13121234", [f inputDigit:@"4"], nil);
        
        // +82 131-2-1234 - Test the same number, but with the country code.
        [f clear];
        STAssertEqualObjects(@"+", [f inputDigit:@"+"], nil);
        STAssertEqualObjects(@"+8", [f inputDigit:@"8"], nil);
        STAssertEqualObjects(@"+82 ", [f inputDigit:@"2"], nil);
        STAssertEqualObjects(@"+82 1", [f inputDigit:@"1"], nil);
        STAssertEqualObjects(@"+82 13", [f inputDigit:@"3"], nil);
        STAssertEqualObjects(@"+82 131", [f inputDigit:@"1"], nil);
        STAssertEqualObjects(@"+82 131-2", [f inputDigit:@"2"], nil);
        STAssertEqualObjects(@"+82 131-2-1", [f inputDigit:@"1"], nil);
        STAssertEqualObjects(@"+82 131-2-12", [f inputDigit:@"2"], nil);
        STAssertEqualObjects(@"+82 131-2-123", [f inputDigit:@"3"], nil);
        STAssertEqualObjects(@"+82 131-2-1234", [f inputDigit:@"4"], nil);
    }
    
    // testAYTFShortNumberFormattingFix_MX()
    {
        // For Mexico, the national prefix is optional when formatting.
        NBAsYouTypeFormatter *f = [[NBAsYouTypeFormatter alloc] initWithRegionCodeForTest:@"MX"];
        
        // 911
        STAssertEqualObjects(@"9", [f inputDigit:@"9"], nil);
        STAssertEqualObjects(@"91", [f inputDigit:@"1"], nil);
        STAssertEqualObjects(@"911", [f inputDigit:@"1"], nil);
        
        // 800 123 4567 - Test a toll-free number, which should have a formatting rule
        // applied to it even though it doesn't begin with the national prefix.
        [f clear];
        STAssertEqualObjects(@"8", [f inputDigit:@"8"], nil);
        STAssertEqualObjects(@"80", [f inputDigit:@"0"], nil);
        STAssertEqualObjects(@"800", [f inputDigit:@"0"], nil);
        STAssertEqualObjects(@"800 1", [f inputDigit:@"1"], nil);
        STAssertEqualObjects(@"800 12", [f inputDigit:@"2"], nil);
        STAssertEqualObjects(@"800 123", [f inputDigit:@"3"], nil);
        STAssertEqualObjects(@"800 123 4", [f inputDigit:@"4"], nil);
        STAssertEqualObjects(@"800 123 45", [f inputDigit:@"5"], nil);
        STAssertEqualObjects(@"800 123 456", [f inputDigit:@"6"], nil);
        STAssertEqualObjects(@"800 123 4567", [f inputDigit:@"7"], nil);
        
        // +52 800 123 4567 - Test the same number, but with the country code.
        [f clear];
        STAssertEqualObjects(@"+", [f inputDigit:@"+"], nil);
        STAssertEqualObjects(@"+5", [f inputDigit:@"5"], nil);
        STAssertEqualObjects(@"+52 ", [f inputDigit:@"2"], nil);
        STAssertEqualObjects(@"+52 8", [f inputDigit:@"8"], nil);
        STAssertEqualObjects(@"+52 80", [f inputDigit:@"0"], nil);
        STAssertEqualObjects(@"+52 800", [f inputDigit:@"0"], nil);
        STAssertEqualObjects(@"+52 800 1", [f inputDigit:@"1"], nil);
        STAssertEqualObjects(@"+52 800 12", [f inputDigit:@"2"], nil);
        STAssertEqualObjects(@"+52 800 123", [f inputDigit:@"3"], nil);
        STAssertEqualObjects(@"+52 800 123 4", [f inputDigit:@"4"], nil);
        STAssertEqualObjects(@"+52 800 123 45", [f inputDigit:@"5"], nil);
        STAssertEqualObjects(@"+52 800 123 456", [f inputDigit:@"6"], nil);
        STAssertEqualObjects(@"+52 800 123 4567", [f inputDigit:@"7"], nil);
    }
    
    // testAYTFNoNationalPrefix()
    {
        /** @type {i18n.phonenumbers.AsYouTypeFormatter} */
        NBAsYouTypeFormatter *f = [[NBAsYouTypeFormatter alloc] initWithRegionCodeForTest:@"IT"];
        STAssertEqualObjects(@"3", [f inputDigit:@"3"], nil);
        STAssertEqualObjects(@"33", [f inputDigit:@"3"], nil);
        STAssertEqualObjects(@"333", [f inputDigit:@"3"], nil);
        STAssertEqualObjects(@"333 3", [f inputDigit:@"3"], nil);
        STAssertEqualObjects(@"333 33", [f inputDigit:@"3"], nil);
        STAssertEqualObjects(@"333 333", [f inputDigit:@"3"], nil);
    }
    
    // testAYTFShortNumberFormattingFix_US()
    {
        // For the US, an initial 1 is treated specially.
        /** @type {i18n.phonenumbers.AsYouTypeFormatter} */
        NBAsYouTypeFormatter *f = [[NBAsYouTypeFormatter alloc] initWithRegionCodeForTest:@"US"];
        
        // 101 - Test that the initial 1 is not treated as a national prefix.
        STAssertEqualObjects(@"1", [f inputDigit:@"1"], nil);
        STAssertEqualObjects(@"10", [f inputDigit:@"0"], nil);
        STAssertEqualObjects(@"101", [f inputDigit:@"1"], nil);
        
        // 112 - Test that the initial 1 is not treated as a national prefix.
        [f clear];
        STAssertEqualObjects(@"1", [f inputDigit:@"1"], nil);
        STAssertEqualObjects(@"11", [f inputDigit:@"1"], nil);
        STAssertEqualObjects(@"112", [f inputDigit:@"2"], nil);
        
        // 122 - Test that the initial 1 is treated as a national prefix.
        [f clear];
        STAssertEqualObjects(@"1", [f inputDigit:@"1"], nil);
        STAssertEqualObjects(@"12", [f inputDigit:@"2"], nil);
        STAssertEqualObjects(@"1 22", [f inputDigit:@"2"], nil);
    }
    
    // testAYTFDescription()
    {
        /** @type {i18n.phonenumbers.AsYouTypeFormatter} */
        NBAsYouTypeFormatter *f = [[NBAsYouTypeFormatter alloc] initWithRegionCodeForTest:@"US"];
        
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
        STAssertEqualObjects(@"1 650 253 2222", [f description], nil);
        
        [f removeLastDigit];
        STAssertEqualObjects(@"1 650 253 222", [f description], nil);
        
        [f removeLastDigit];
        STAssertEqualObjects(@"1 650 253 22", [f description], nil);
        
        [f removeLastDigit];
        STAssertEqualObjects(@"1 650 253 2", [f description], nil);
        
        [f removeLastDigit];
        STAssertEqualObjects(@"1 650 253", [f description], nil);
        
        [f removeLastDigit];
        STAssertEqualObjects(@"1 650 25", [f description], nil);
        
        [f removeLastDigit];
        STAssertEqualObjects(@"1 650 2", [f description], nil);
        
        [f removeLastDigit];
        STAssertEqualObjects(@"1 650", [f description], nil);
        
        [f removeLastDigit];
        STAssertEqualObjects(@"1 65", [f description], nil);
        
        [f removeLastDigit];
        STAssertEqualObjects(@"16", [f description], nil);
        
        [f removeLastDigit];
        STAssertEqualObjects(@"1", [f description], nil);
        
        [f removeLastDigit];
        STAssertEqualObjects(@"", [f description], nil);
    }
}

@end
