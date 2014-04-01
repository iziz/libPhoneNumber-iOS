//
//  NBPhoneNumberUtilTests.m
//  NBPhoneNumberUtilTests
//
//

#import "NBPhoneNumberUtilTests.h"

#import "NBPhoneMetaData.h"
#import "NBPhoneNumber.h"
#import "NBPhoneNumberDesc.h"
#import "NBPhoneNumberUtil.h"
#import "NBNumberFormat.h"


@interface NBPhoneNumberUtil (FOR_UNIT_TEST)

- (NBPhoneMetaData*)getMetadataForRegion:(NSString*)regionCode;
- (BOOL)canBeInternationallyDialled:(NBPhoneNumber*)number;
- (BOOL)truncateTooLongNumber:(NBPhoneNumber*)number;
- (NBEValidationResult)isPossibleNumberWithReason:(NBPhoneNumber*)number;
- (BOOL)isPossibleNumber:(NBPhoneNumber*)number;
- (NBEMatchType)isNumberMatch:(id)firstNumberIn second:(id)secondNumberIn;
- (int)getLengthOfGeographicalAreaCode:(NBPhoneNumber*)phoneNumber;
- (int)getLengthOfNationalDestinationCode:(NBPhoneNumber*)phoneNumber;
- (BOOL)maybeStripNationalPrefixAndCarrierCode:(NSString**)numberStr metadata:(NBPhoneMetaData*)metadata carrierCode:(NSString**)carrierCode;
- (NBECountryCodeSource)maybeStripInternationalPrefixAndNormalize:(NSString**)numberStr possibleIddPrefix:(NSString*)possibleIddPrefix;
- (NSString*)format:(NBPhoneNumber*)phoneNumber numberFormat:(NBEPhoneNumberFormat)numberFormat;
- (NSString*)formatByPattern:(NBPhoneNumber*)number numberFormat:(NBEPhoneNumberFormat)numberFormat userDefinedFormats:(NSArray*)userDefinedFormats;
- (NSString*)formatNumberForMobileDialing:(NBPhoneNumber*)number regionCallingFrom:(NSString*)regionCallingFrom withFormatting:(BOOL)withFormatting;
- (NSString*)formatOutOfCountryCallingNumber:(NBPhoneNumber*)number regionCallingFrom:(NSString*)regionCallingFrom;
- (NSString*)formatOutOfCountryKeepingAlphaChars:(NBPhoneNumber*)number regionCallingFrom:(NSString*)regionCallingFrom;
- (NSString*)formatNationalNumberWithCarrierCode:(NBPhoneNumber*)number carrierCode:(NSString*)carrierCode;
- (NSString*)formatInOriginalFormat:(NBPhoneNumber*)number regionCallingFrom:(NSString*)regionCallingFrom;
- (NSString*)formatNationalNumberWithPreferredCarrierCode:(NBPhoneNumber*)number fallbackCarrierCode:(NSString*)fallbackCarrierCode;

@end


@implementation NBPhoneNumberUtilTests

- (void)setUp
{
    [super setUp];
    
    // ...
    
    [self initWithoutSharedInstance];
    [self initWithoutSharedInstance];
    [self initWithoutSharedInstance];
}

- (void)tearDown
{
    // ...
    
    [super tearDown];
}

- (void)initWithoutSharedInstance
{
    NBPhoneNumberUtil *aUtil = [[NBPhoneNumberUtil alloc] init];
    NBPhoneNumber *aNumber = [aUtil parse:@"2351236236136" defaultRegion:@"KR" error:nil];
    [aUtil format:aNumber numberFormat:NBEPhoneNumberFormatINTERNATIONAL];
}

- (NSString*)stringForNumberType:(NBEPhoneNumberType)type
{
    NSString *stringType = @"UNKNOWN";
    
    switch (type) {
        case 0: return @"FIXED_LINE";
        case 1: return @"MOBILE";
        case 2: return @"FIXED_LINE_OR_MOBILE";
        case 3: return @"TOLL_FREE";
        case 4: return @"PREMIUM_RATE";
        case 5: return @"SHARED_COST";
        case 6: return @"VOIP";
        case 7: return @"PERSONAL_NUMBER";
        case 8: return @"PAGER";
        case 9: return @"UAN";
        case 10: return @"VOICEMAIL";
        default:
            break;
    }
    
    return stringType;
}

- (NSString *)getPhoneNumberFormatted:(NSString *)phoneNumber
{
    NSString *retValue;
    NBPhoneNumberUtil *pnUtil = [NBPhoneNumberUtil sharedInstance];
    NBPhoneNumber *phoneNumberFormatted = [pnUtil parseWithPhoneCarrierRegion:phoneNumber error:nil];
    retValue = [pnUtil format:phoneNumberFormatted numberFormat:NBEPhoneNumberFormatRFC3966 error:nil];
    return retValue;
}

- (void)testForExtraDatas
{
    NSArray *arrayData = [[NBPhoneNumberUtil sharedInstance] getAllMetadata];
    if (arrayData && arrayData.count > 0) {
        NSLog(@"Log sample metadata [%@]", [arrayData firstObject]);
    } else {
        XCTFail(@"Fail to extract meta data");
    }
}

- (void)testCarrierRegion
{
    NSLog(@"testCarrierRegion %@", [self getPhoneNumberFormatted:@"1234567890"]);
}

// FIXME: This unit test ALWAYS FAIL ... until google libPhoneNumber fix this issue
- (void)testAustriaNationalNumberParsing
{
    NSError *aError = nil;
    
    NBPhoneNumberUtil *phoneUtil = [NBPhoneNumberUtil sharedInstance];
    NSString *internationalNumberForInput = @"436606545646";
    NSString *nationalNumberForExpect = @"6606545646";
    NSString *defaultRegion = @"AT";
    
    NBPhoneNumber *phoneNumber = [phoneUtil parse:internationalNumberForInput defaultRegion:defaultRegion error:&aError];
    NSString *nationalNumberForActual = [NSString stringWithFormat:@"%@", phoneNumber.nationalNumber];
    
    // ALWAYS FAIL need fix "google libPhoneNumber"
    XCTAssertEqualObjects(nationalNumberForExpect, nationalNumberForActual);
}

- (void)testForiOS7
{
    NBPhoneNumberUtil *phoneUtil = [NBPhoneNumberUtil sharedInstance];
    
    NSError *aError = nil;
    NBPhoneNumber *myNumber = [phoneUtil parse:@"0174 2340XXX" defaultRegion:@"DE" error:&aError];
    if (aError == nil)
    {
        NSLog(@"isValidPhoneNumber ? [%@]", [phoneUtil isValidNumber:myNumber] ? @"YES":@"NO");
        NSLog(@"E164          : %@", [phoneUtil format:myNumber numberFormat:NBEPhoneNumberFormatE164 error:&aError]);
        NSLog(@"INTERNATIONAL : %@", [phoneUtil format:myNumber numberFormat:NBEPhoneNumberFormatINTERNATIONAL error:&aError]);
        NSLog(@"NATIONAL      : %@", [phoneUtil format:myNumber numberFormat:NBEPhoneNumberFormatNATIONAL error:&aError]);
        NSLog(@"RFC3966       : %@", [phoneUtil format:myNumber numberFormat:NBEPhoneNumberFormatRFC3966 error:&aError]);
    }
    else
    {
        NSLog(@"Error : %@", [aError localizedDescription]);
    }
}

- (void)testForGetMetadataForRegionTwice
{
    NBPhoneNumberUtil *phoneUtil = [NBPhoneNumberUtil sharedInstance];
    
    [phoneUtil getMetadataForRegion:@"US"];
    [phoneUtil getMetadataForRegion:@"KR"];
    [phoneUtil getMetadataForRegion:nil];
    [phoneUtil getMetadataForRegion:NULL];
    [phoneUtil getMetadataForRegion:@""];
    [phoneUtil getMetadataForRegion:0];
    [phoneUtil getMetadataForRegion:@" AU"];
    [phoneUtil getMetadataForRegion:@" JP        "];
}

- (void)testNSDictionaryalbeKey
{
    NBPhoneNumberUtil *phoneUtil = [NBPhoneNumberUtil sharedInstance];
    NSError *aError = nil;

    NBPhoneNumber *myNumber1 = [phoneUtil parse:@"971600123456" defaultRegion:@"AE" error:&aError];
    NBPhoneNumber *myNumber2 = [phoneUtil parse:@"5491187654321" defaultRegion:@"AR" error:&aError];
    NBPhoneNumber *myNumber3 = [phoneUtil parse:@"12423570000" defaultRegion:@"BS" error:&aError];
    NBPhoneNumber *myNumber4 = [phoneUtil parse:@"39236618300" defaultRegion:@"IT" error:&aError];
    NBPhoneNumber *myNumber5 = [phoneUtil parse:@"16502530000" defaultRegion:@"US" error:&aError];
    
    NSMutableDictionary *dicTest = [[NSMutableDictionary alloc] init];
    [dicTest setObject:@"AE" forKey:myNumber1];
    [dicTest setObject:@"AR" forKey:myNumber2];
    [dicTest setObject:@"BS" forKey:myNumber3];
    [dicTest setObject:@"IT" forKey:myNumber4];
    [dicTest setObject:@"US" forKey:myNumber5];
    
    NSLog(@"%@", [dicTest objectForKey:myNumber1]);
    NSLog(@"%@", [dicTest objectForKey:myNumber2]);
    NSLog(@"%@", [dicTest objectForKey:myNumber3]);
    NSLog(@"%@", [dicTest objectForKey:myNumber4]);
    NSLog(@"%@", [dicTest objectForKey:myNumber5]);
}


- (void)testWithRealData
{
    NBPhoneNumberUtil *phoneUtil = [NBPhoneNumberUtil sharedInstance];
    
#pragma mark - customTest
    NSLog(@"-------------- customTest");
    
    NSError *aError = nil;
    NBPhoneNumber *myNumber = [phoneUtil parse:@"6766077303" defaultRegion:@"AT" error:&aError];
    if (aError == nil)
    {
        NSLog(@"isValidPhoneNumber ? [%@]", [phoneUtil isValidNumber:myNumber] ? @"YES":@"NO");
        NSLog(@"E164          : %@", [phoneUtil format:myNumber numberFormat:NBEPhoneNumberFormatE164 error:&aError]);
        NSLog(@"INTERNATIONAL : %@", [phoneUtil format:myNumber numberFormat:NBEPhoneNumberFormatINTERNATIONAL error:&aError]);
        NSLog(@"NATIONAL      : %@", [phoneUtil format:myNumber numberFormat:NBEPhoneNumberFormatNATIONAL error:&aError]);
        NSLog(@"RFC3966       : %@", [phoneUtil format:myNumber numberFormat:NBEPhoneNumberFormatRFC3966 error:&aError]);
    }
    else
    {
        NSLog(@"Error : %@", [aError localizedDescription]);
    }
    
    NSLog (@"extractCountryCode [%ld]", (unsigned long)[phoneUtil extractCountryCode:@"823213123123" nationalNumber:nil]);
    NSString *res = nil;
    NSNumber *dRes = [phoneUtil extractCountryCode:@"823213123123" nationalNumber:&res];
    NSLog (@"extractCountryCode [%@] [%@]", dRes, res);
}


- (void)testWithTestData
{
    // NSError *aError = nil;
    
    NBPhoneNumberUtil *phoneUtil = [NBPhoneNumberUtil sharedInstanceForTest];
    
    // Set up some test numbers to re-use.
    // TODO: Rewrite this as static functions that return new numbers each time to
    // avoid any risk of accidental changes to mutable static state affecting many
    // tests.
    NBPhoneNumber *ALPHA_NUMERIC_NUMBER = [[NBPhoneNumber alloc] init];
    ALPHA_NUMERIC_NUMBER.countryCode = @1;
    ALPHA_NUMERIC_NUMBER.nationalNumber = @80074935247;
    
    NBPhoneNumber *AE_UAN = [[NBPhoneNumber alloc] init];
    AE_UAN.countryCode = @971;
    AE_UAN.nationalNumber = @600123456;
    
    NBPhoneNumber *AR_MOBILE = [[NBPhoneNumber alloc] init];
    AR_MOBILE.countryCode = @54;
    AR_MOBILE.nationalNumber = @91187654321;
    
    NBPhoneNumber *AR_NUMBER = [[NBPhoneNumber alloc] init];
    AR_NUMBER.countryCode = @54;
    AR_NUMBER.nationalNumber = @1187654321;
    
    NBPhoneNumber *AU_NUMBER = [[NBPhoneNumber alloc] init];
    AU_NUMBER.countryCode = @61;
    AU_NUMBER.nationalNumber = @236618300;
    
    NBPhoneNumber *BS_MOBILE = [[NBPhoneNumber alloc] init];
    BS_MOBILE.countryCode = @1;
    BS_MOBILE.nationalNumber = @2423570000;
    
    NBPhoneNumber *BS_NUMBER = [[NBPhoneNumber alloc] init];
    BS_NUMBER.countryCode = @1;
    BS_NUMBER.nationalNumber = @2423651234;
    
    // Note that this is the same as the example number for DE in the metadata.
    NBPhoneNumber *DE_NUMBER = [[NBPhoneNumber alloc] init];
    DE_NUMBER.countryCode = @49;
    DE_NUMBER.nationalNumber = @30123456;
    
    NBPhoneNumber *DE_SHORT_NUMBER = [[NBPhoneNumber alloc] init];
    DE_SHORT_NUMBER.countryCode = @49;
    DE_SHORT_NUMBER.nationalNumber = @1234;
    
    NBPhoneNumber *GB_MOBILE = [[NBPhoneNumber alloc] init];
    GB_MOBILE.countryCode = @44;
    GB_MOBILE.nationalNumber = @7912345678;
    
    NBPhoneNumber *GB_NUMBER = [[NBPhoneNumber alloc] init];
    GB_NUMBER.countryCode = @44;
    GB_NUMBER.nationalNumber = @2070313000;
    
    NBPhoneNumber *IT_MOBILE = [[NBPhoneNumber alloc] init];
    IT_MOBILE.countryCode = @39;
    IT_MOBILE.nationalNumber = @345678901;
    
    NBPhoneNumber *IT_NUMBER = [[NBPhoneNumber alloc] init];
    IT_NUMBER.countryCode = @39;
    IT_NUMBER.nationalNumber = @236618300;
    IT_NUMBER.italianLeadingZero = YES;
    
    NBPhoneNumber *JP_STAR_NUMBER = [[NBPhoneNumber alloc] init];
    JP_STAR_NUMBER.countryCode = @81;
    JP_STAR_NUMBER.nationalNumber = @2345;
    
    // Numbers to test the formatting rules from Mexico.
    NBPhoneNumber *MX_MOBILE1 = [[NBPhoneNumber alloc] init];
    MX_MOBILE1.countryCode = @52;
    MX_MOBILE1.nationalNumber = @12345678900;
    
    NBPhoneNumber *MX_MOBILE2 = [[NBPhoneNumber alloc] init];
    MX_MOBILE2.countryCode = @52;
    MX_MOBILE2.nationalNumber = @15512345678;
    
    NBPhoneNumber *MX_NUMBER1 = [[NBPhoneNumber alloc] init];
    MX_NUMBER1.countryCode = @52;
    MX_NUMBER1.nationalNumber = @3312345678;
    
    NBPhoneNumber *MX_NUMBER2 = [[NBPhoneNumber alloc] init];
    MX_NUMBER2.countryCode = @52;
    MX_NUMBER2.nationalNumber = @8211234567;
    
    NBPhoneNumber *NZ_NUMBER = [[NBPhoneNumber alloc] init];
    NZ_NUMBER.countryCode = @64;
    NZ_NUMBER.nationalNumber = @33316005;
    
    NBPhoneNumber *SG_NUMBER = [[NBPhoneNumber alloc] init];
    SG_NUMBER.countryCode = @65;
    SG_NUMBER.nationalNumber = @65218000;
    
    // A too-long and hence invalid US number.
    NBPhoneNumber *US_LONG_NUMBER = [[NBPhoneNumber alloc] init];
    US_LONG_NUMBER.countryCode = @1;
    US_LONG_NUMBER.nationalNumber = @65025300001;
    
    NBPhoneNumber *US_NUMBER = [[NBPhoneNumber alloc] init];
    US_NUMBER.countryCode = @1;
    US_NUMBER.nationalNumber = @6502530000;
    
    NBPhoneNumber *US_PREMIUM = [[NBPhoneNumber alloc] init];
    US_PREMIUM.countryCode = @1;
    US_PREMIUM.nationalNumber = @9002530000;
    
    // Too short, but still possible US numbers.
    NBPhoneNumber *US_LOCAL_NUMBER = [[NBPhoneNumber alloc] init];
    US_LOCAL_NUMBER.countryCode = @1;
    US_LOCAL_NUMBER.nationalNumber = @2530000;
    
    NBPhoneNumber *US_SHORT_BY_ONE_NUMBER = [[NBPhoneNumber alloc] init];
    US_SHORT_BY_ONE_NUMBER.countryCode = @1;
    US_SHORT_BY_ONE_NUMBER.nationalNumber = @650253000;
    
    NBPhoneNumber *US_TOLLFREE = [[NBPhoneNumber alloc] init];
    US_TOLLFREE.countryCode = @1;
    US_TOLLFREE.nationalNumber = @8002530000;
    
    NBPhoneNumber *US_SPOOF = [[NBPhoneNumber alloc] init];
    US_SPOOF.countryCode = @1;
    US_SPOOF.nationalNumber = @0;
    
    NBPhoneNumber *US_SPOOF_WITH_RAW_INPUT = [[NBPhoneNumber alloc] init];
    US_SPOOF_WITH_RAW_INPUT.countryCode = @1;
    US_SPOOF_WITH_RAW_INPUT.nationalNumber = @0;
    US_SPOOF_WITH_RAW_INPUT.rawInput = @"000-000-0000";
    
    NBPhoneNumber *INTERNATIONAL_TOLL_FREE = [[NBPhoneNumber alloc] init];
    INTERNATIONAL_TOLL_FREE.countryCode = @800;
    INTERNATIONAL_TOLL_FREE.nationalNumber = @12345678;
    
    // We set this to be the same length as numbers for the other non-geographical
    // country prefix that we have in our test metadata. However, this is not
    // considered valid because they differ in their country calling code.
    
    NBPhoneNumber *INTERNATIONAL_TOLL_FREE_TOO_LONG = [[NBPhoneNumber alloc] init];
    INTERNATIONAL_TOLL_FREE_TOO_LONG.countryCode = @800;
    INTERNATIONAL_TOLL_FREE_TOO_LONG.nationalNumber = @123456789;
    
    NBPhoneNumber *UNIVERSAL_PREMIUM_RATE = [[NBPhoneNumber alloc] init];
    UNIVERSAL_PREMIUM_RATE.countryCode = @979;
    UNIVERSAL_PREMIUM_RATE.nationalNumber = @123456789;
    
    NBPhoneNumber *UNKNOWN_COUNTRY_CODE_NO_RAW_INPUT = [[NBPhoneNumber alloc] init];
    UNKNOWN_COUNTRY_CODE_NO_RAW_INPUT.countryCode = @2;
    UNKNOWN_COUNTRY_CODE_NO_RAW_INPUT.nationalNumber = @12345;
    
    
    #pragma mark - testGetInstanceLoadUSMetadata
    {
        NBPhoneMetaData *metadata = [phoneUtil getMetadataForRegion:@"US"];

        XCTAssertEqualObjects(@"US", metadata.codeID);
        XCTAssertEqualObjects(@1, metadata.countryCode);
        XCTAssertEqualObjects(@"011", metadata.internationalPrefix);
        XCTAssertTrue(metadata.nationalPrefix != nil);
        XCTAssertEqual(2, (int)[metadata.numberFormats count]);
        XCTAssertEqualObjects(@"(\\d{3})(\\d{3})(\\d{4})", ((NBNumberFormat*)metadata.numberFormats[1]).pattern);
        XCTAssertEqualObjects(@"$1 $2 $3", ((NBNumberFormat*)metadata.numberFormats[1]).format);
        XCTAssertEqualObjects(@"[13-689]\\d{9}|2[0-35-9]\\d{8}", metadata.generalDesc.nationalNumberPattern);
        XCTAssertEqualObjects(@"\\d{7}(?:\\d{3})?", metadata.generalDesc.possibleNumberPattern);
        XCTAssertTrue([metadata.generalDesc isEqual:metadata.fixedLine]);
        XCTAssertEqualObjects(@"\\d{10}", metadata.tollFree.possibleNumberPattern);
        XCTAssertEqualObjects(@"900\\d{7}", metadata.premiumRate.nationalNumberPattern);
        // No shared-cost data is available, so it should be initialised to 'NA'.
        XCTAssertEqualObjects(@"NA", metadata.sharedCost.nationalNumberPattern);
        XCTAssertEqualObjects(@"NA", metadata.sharedCost.possibleNumberPattern);
    }
                                           
    #pragma mark - testGetInstanceLoadDEMetadata
    {
        NBPhoneMetaData *metadata = [phoneUtil getMetadataForRegion:@"DE"];
        XCTAssertEqualObjects(@"DE", metadata.codeID);
        XCTAssertEqualObjects(@49, metadata.countryCode);
        XCTAssertEqualObjects(@"00", metadata.internationalPrefix);
        XCTAssertEqualObjects(@"0", metadata.nationalPrefix);
        XCTAssertEqual(6, (int)[metadata.numberFormats count]);
        XCTAssertEqual(1, (int)[((NBNumberFormat*)metadata.numberFormats[5]).leadingDigitsPatterns count]);
        XCTAssertEqualObjects(@"900", ((NBNumberFormat*)metadata.numberFormats[5]).leadingDigitsPatterns[0]);
        XCTAssertEqualObjects(@"(\\d{3})(\\d{3,4})(\\d{4})", ((NBNumberFormat*)metadata.numberFormats[5]).pattern);
        XCTAssertEqualObjects(@"$1 $2 $3", ((NBNumberFormat*)metadata.numberFormats[5]).format);
        XCTAssertEqualObjects(@"(?:[24-6]\\d{2}|3[03-9]\\d|[789](?:[1-9]\\d|0[2-9]))\\d{1,8}", metadata.fixedLine.nationalNumberPattern);
        XCTAssertEqualObjects(@"\\d{2,14}", metadata.fixedLine.possibleNumberPattern);
        XCTAssertEqualObjects(@"30123456", metadata.fixedLine.exampleNumber);
        XCTAssertEqualObjects(@"\\d{10}", metadata.tollFree.possibleNumberPattern);
        XCTAssertEqualObjects(@"900([135]\\d{6}|9\\d{7})", metadata.premiumRate.nationalNumberPattern);
    }


    #pragma mark - testGetInstanceLoadARMetadata
    {
        NBPhoneMetaData *metadata = [phoneUtil getMetadataForRegion:@"AR"];
        XCTAssertEqualObjects(@"AR", metadata.codeID);
        XCTAssertEqualObjects(@54, metadata.countryCode);
        XCTAssertEqualObjects(@"00", metadata.internationalPrefix);
        XCTAssertEqualObjects(@"0", metadata.nationalPrefix);
        XCTAssertEqualObjects(@"0(?:(11|343|3715)15)?", metadata.nationalPrefixForParsing);
        XCTAssertEqualObjects(@"9$1", metadata.nationalPrefixTransformRule);
        XCTAssertEqualObjects(@"$2 15 $3-$4", ((NBNumberFormat*)metadata.numberFormats[2]).format);
        XCTAssertEqualObjects(@"(9)(\\d{4})(\\d{2})(\\d{4})", ((NBNumberFormat*)metadata.numberFormats[3]).pattern);
        XCTAssertEqualObjects(@"(9)(\\d{4})(\\d{2})(\\d{4})", ((NBNumberFormat*)metadata.intlNumberFormats[3]).pattern);
        XCTAssertEqualObjects(@"$1 $2 $3 $4", ((NBNumberFormat*)metadata.intlNumberFormats[3]).format);
    }


    #pragma mark - testGetInstanceLoadInternationalTollFreeMetadata
    {
        NBPhoneMetaData *metadata = [phoneUtil getMetadataForNonGeographicalRegion:@800];
        XCTAssertEqualObjects(@"001", metadata.codeID);
        XCTAssertEqualObjects(@800, metadata.countryCode);
        XCTAssertEqualObjects(@"$1 $2", ((NBNumberFormat*)metadata.numberFormats[0]).format);
        XCTAssertEqualObjects(@"(\\d{4})(\\d{4})", ((NBNumberFormat*)metadata.numberFormats[0]).pattern);
        XCTAssertEqualObjects(@"12345678", metadata.generalDesc.exampleNumber);
        XCTAssertEqualObjects(@"12345678", metadata.tollFree.exampleNumber);
    }
                                                                

    #pragma mark - testIsNumberGeographical
    {
        // Bahamas, mobile phone number.
        XCTAssertFalse([phoneUtil isNumberGeographical:BS_MOBILE]);
        // Australian fixed line number.
        XCTAssertTrue([phoneUtil isNumberGeographical:AU_NUMBER]);
        // International toll free number.
        XCTAssertFalse([phoneUtil isNumberGeographical:INTERNATIONAL_TOLL_FREE]);
    }
                                                                

    #pragma mark - testIsLeadingZeroPossible
    {
        // Italy
        XCTAssertTrue([phoneUtil isLeadingZeroPossible:@39]);
        // USA
        XCTAssertFalse([phoneUtil isLeadingZeroPossible:@1]);
        // International toll free
        XCTAssertTrue([phoneUtil isLeadingZeroPossible:@800]);
        // International premium-rate
        XCTAssertFalse([phoneUtil isLeadingZeroPossible:@979]);
        // Not in metadata file, just default to false.
        XCTAssertFalse([phoneUtil isLeadingZeroPossible:@888]);
    }
        

    #pragma mark - testgetLengthOfGeographicalAreaCode
    {
        // Google MTV, which has area code '650'.
        XCTAssertEqual(3, [phoneUtil getLengthOfGeographicalAreaCode:US_NUMBER]);
        
        // A North America toll-free number, which has no area code.
        XCTAssertEqual(0, [phoneUtil getLengthOfGeographicalAreaCode:US_TOLLFREE]);
        
        // Google London, which has area code '20'.
        XCTAssertEqual(2, [phoneUtil getLengthOfGeographicalAreaCode:GB_NUMBER]);
        
        // A UK mobile phone, which has no area code.
        XCTAssertEqual(0, [phoneUtil getLengthOfGeographicalAreaCode:GB_MOBILE]);
        
        // Google Buenos Aires, which has area code '11'.
        XCTAssertEqual(2, [phoneUtil getLengthOfGeographicalAreaCode:AR_NUMBER]);
        
        // Google Sydney, which has area code '2'.
        XCTAssertEqual(1, [phoneUtil getLengthOfGeographicalAreaCode:AU_NUMBER]);
        
        // Italian numbers - there is no national prefix, but it still has an area
        // code.
        XCTAssertEqual(2, [phoneUtil getLengthOfGeographicalAreaCode:IT_NUMBER]);
        
        // Google Singapore. Singapore has no area code and no national prefix.
        XCTAssertEqual(0, [phoneUtil getLengthOfGeographicalAreaCode:SG_NUMBER]);
        
        // An invalid US number (1 digit shorter), which has no area code.
        XCTAssertEqual(0, [phoneUtil getLengthOfGeographicalAreaCode:US_SHORT_BY_ONE_NUMBER]);
        
        // An international toll free number, which has no area code.
        XCTAssertEqual(0, [phoneUtil getLengthOfGeographicalAreaCode:INTERNATIONAL_TOLL_FREE]);
    }

    
    #pragma mark - testGetLengthOfNationalDestinationCode
    {
        // Google MTV, which has national destination code (NDC) '650'.
        XCTAssertEqual(3, [phoneUtil getLengthOfNationalDestinationCode:US_NUMBER]);
        
        // A North America toll-free number, which has NDC '800'.
        XCTAssertEqual(3, [phoneUtil getLengthOfNationalDestinationCode:US_TOLLFREE]);
        
        // Google London, which has NDC '20'.
        XCTAssertEqual(2, [phoneUtil getLengthOfNationalDestinationCode:GB_NUMBER]);
        
        // A UK mobile phone, which has NDC '7912'.
        XCTAssertEqual(4, [phoneUtil getLengthOfNationalDestinationCode:GB_MOBILE]);
        
        // Google Buenos Aires, which has NDC '11'.
        XCTAssertEqual(2, [phoneUtil getLengthOfNationalDestinationCode:AR_NUMBER]);
        
        // An Argentinian mobile which has NDC '911'.
        XCTAssertEqual(3, [phoneUtil getLengthOfNationalDestinationCode:AR_MOBILE]);
        
        // Google Sydney, which has NDC '2'.
        XCTAssertEqual(1, [phoneUtil getLengthOfNationalDestinationCode:AU_NUMBER]);
        
        // Google Singapore, which has NDC '6521'.
        XCTAssertEqual(4, [phoneUtil getLengthOfNationalDestinationCode:SG_NUMBER]);
        
        // An invalid US number (1 digit shorter), which has no NDC.
        XCTAssertEqual(0,
                     [phoneUtil getLengthOfNationalDestinationCode:US_SHORT_BY_ONE_NUMBER]);
        
        // A number containing an invalid country calling code, which shouldn't have
        // any NDC.
        
        NBPhoneNumber *number = [[NBPhoneNumber alloc] init];
        [number setCountryCode:@123];
        [number setNationalNumber:@6502530000];
        XCTAssertEqual(0, [phoneUtil getLengthOfNationalDestinationCode:number]);
        
        // An international toll free number, which has NDC '1234'.
        XCTAssertEqual(4, [phoneUtil getLengthOfNationalDestinationCode:INTERNATIONAL_TOLL_FREE]);
    }
        
    #pragma mark - testGetNationalSignificantNumber
    {
        XCTAssertEqualObjects(@"6502530000", [phoneUtil getNationalSignificantNumber:US_NUMBER]);
        
        // An Italian mobile number.
        XCTAssertEqualObjects(@"345678901", [phoneUtil getNationalSignificantNumber:IT_MOBILE]);
        
        // An Italian fixed line number.
        XCTAssertEqualObjects(@"0236618300", [phoneUtil getNationalSignificantNumber:IT_NUMBER]);
        
        XCTAssertEqualObjects(@"12345678", [phoneUtil getNationalSignificantNumber:INTERNATIONAL_TOLL_FREE]);
    }

    
    #pragma mark - testGetExampleNumber
    {
        XCTAssertTrue([DE_NUMBER isEqual:[phoneUtil getExampleNumber:@"DE" error:nil]]);
        
        XCTAssertTrue([DE_NUMBER isEqual:[phoneUtil getExampleNumberForType:@"DE" type:NBEPhoneNumberTypeFIXED_LINE error:nil]]);
        XCTAssertNil([phoneUtil getExampleNumberForType:@"DE" type:NBEPhoneNumberTypeMOBILE error:nil]);
        // For the US, the example number is placed under general description, and
        // hence should be used for both fixed line and mobile, so neither of these
        // should return nil.
        XCTAssertNotNil([phoneUtil getExampleNumberForType:@"US" type:NBEPhoneNumberTypeFIXED_LINE error:nil]);
        XCTAssertNotNil([phoneUtil getExampleNumberForType:@"US" type:NBEPhoneNumberTypeMOBILE error:nil]);
        // CS is an invalid region, so we have no data for it.
        XCTAssertNil([phoneUtil getExampleNumberForType:@"CS" type:NBEPhoneNumberTypeMOBILE error:nil]);
        // RegionCode 001 is reserved for supporting non-geographical country calling
        // code. We don't support getting an example number for it with this method.
        XCTAssertNil([phoneUtil getExampleNumber:@"001" error:nil]);
    }

    
    #pragma mark - testexampleNumberForNonGeoEntity
    {
        XCTAssertTrue([INTERNATIONAL_TOLL_FREE isEqual:[phoneUtil getExampleNumberForNonGeoEntity:@800 error:nil]]);
        XCTAssertTrue([UNIVERSAL_PREMIUM_RATE isEqual:[phoneUtil getExampleNumberForNonGeoEntity:@979 error:nil]]);
    }

    
    #pragma mark - testConvertAlphaCharactersInNumber
    {
        NSString *input = @"1800-ABC-DEF";
        // Alpha chars are converted to digits; everything else is left untouched.
        
        NSString *expectedOutput = @"1800-222-333";
        XCTAssertEqualObjects(expectedOutput, [phoneUtil convertAlphaCharactersInNumber:input]);
    }

    
    #pragma mark - testNormaliseRemovePunctuation
    {
        NSString *inputNumber = @"034-56&+#2\u00AD34";
        NSString *expectedOutput = @"03456234";
        XCTAssertEqualObjects(expectedOutput, [phoneUtil normalizePhoneNumber:inputNumber], @"Conversion did not correctly remove punctuation");
    }

    
    #pragma mark - testNormaliseReplaceAlphaCharacters
    {
        NSString *inputNumber = @"034-I-am-HUNGRY";
        NSString *expectedOutput = @"034426486479";
        XCTAssertEqualObjects(expectedOutput, [phoneUtil normalizePhoneNumber:inputNumber], @"Conversion did not correctly replace alpha characters");
    }

    
    #pragma mark - testNormaliseOtherDigits
    {
        NSString *inputNumber = @"\uFF125\u0665";
        NSString *expectedOutput = @"255";
        XCTAssertEqualObjects(expectedOutput, [phoneUtil normalizePhoneNumber:inputNumber], @"Conversion did not correctly replace non-latin digits");
        // Eastern-Arabic digits.
        inputNumber = @"\u06F52\u06F0";
        expectedOutput = @"520";
        XCTAssertEqualObjects(expectedOutput, [phoneUtil normalizePhoneNumber:inputNumber], @"Conversion did not correctly replace non-latin digits");
    }

    
    #pragma mark - testNormaliseStripAlphaCharacters
    {
        NSString *inputNumber = @"034-56&+a#234";
        NSString *expectedOutput = @"03456234";
        XCTAssertEqualObjects(expectedOutput, [phoneUtil normalizeDigitsOnly:inputNumber], @"Conversion did not correctly remove alpha character");
    }

    
    #pragma mark - testFormatUSNumber
    {
        XCTAssertEqualObjects(@"650 253 0000", [phoneUtil format:US_NUMBER numberFormat:NBEPhoneNumberFormatNATIONAL]);
        XCTAssertEqualObjects(@"+1 650 253 0000", [phoneUtil format:US_NUMBER numberFormat:NBEPhoneNumberFormatINTERNATIONAL]);
        XCTAssertEqualObjects(@"800 253 0000", [phoneUtil format:US_TOLLFREE numberFormat:NBEPhoneNumberFormatNATIONAL]);
        XCTAssertEqualObjects(@"+1 800 253 0000", [phoneUtil format:US_TOLLFREE numberFormat:NBEPhoneNumberFormatINTERNATIONAL]);
        XCTAssertEqualObjects(@"900 253 0000", [phoneUtil format:US_PREMIUM numberFormat:NBEPhoneNumberFormatNATIONAL]);
        XCTAssertEqualObjects(@"+1 900 253 0000", [phoneUtil format:US_PREMIUM numberFormat:NBEPhoneNumberFormatINTERNATIONAL]);
        XCTAssertEqualObjects(@"tel:+1-900-253-0000", [phoneUtil format:US_PREMIUM numberFormat:NBEPhoneNumberFormatRFC3966]);
        // Numbers with all zeros in the national number part will be formatted by
        // using the raw_input if that is available no matter which format is
        // specified.
        XCTAssertEqualObjects(@"000-000-0000", [phoneUtil format:US_SPOOF_WITH_RAW_INPUT numberFormat:NBEPhoneNumberFormatNATIONAL]);
        XCTAssertEqualObjects(@"0", [phoneUtil format:US_SPOOF numberFormat:NBEPhoneNumberFormatNATIONAL]);
    }

    
    #pragma mark - testFormatBSNumber
    {
        XCTAssertEqualObjects(@"242 365 1234", [phoneUtil format:BS_NUMBER numberFormat:NBEPhoneNumberFormatNATIONAL]);
        XCTAssertEqualObjects(@"+1 242 365 1234", [phoneUtil format:BS_NUMBER numberFormat:NBEPhoneNumberFormatINTERNATIONAL]);
    }
    

    #pragma mark - testFormatGBNumber
    {
        XCTAssertEqualObjects(@"(020) 7031 3000", [phoneUtil format:GB_NUMBER numberFormat:NBEPhoneNumberFormatNATIONAL]);
        XCTAssertEqualObjects(@"+44 20 7031 3000", [phoneUtil format:GB_NUMBER numberFormat:NBEPhoneNumberFormatINTERNATIONAL]);
        XCTAssertEqualObjects(@"(07912) 345 678", [phoneUtil format:GB_MOBILE numberFormat:NBEPhoneNumberFormatNATIONAL]);
        XCTAssertEqualObjects(@"+44 7912 345 678", [phoneUtil format:GB_MOBILE numberFormat:NBEPhoneNumberFormatINTERNATIONAL]);
    }
    

    #pragma mark - testFormatDENumber
    {
        id deNumber = [[NBPhoneNumber alloc] init];
        [deNumber setCountryCode:@49];
        [deNumber setNationalNumber:@301234];
        XCTAssertEqualObjects(@"030/1234", [phoneUtil format:deNumber numberFormat:NBEPhoneNumberFormatNATIONAL]);
        XCTAssertEqualObjects(@"+49 30/1234", [phoneUtil format:deNumber numberFormat:NBEPhoneNumberFormatINTERNATIONAL]);
        XCTAssertEqualObjects(@"tel:+49-30-1234", [phoneUtil format:deNumber numberFormat:NBEPhoneNumberFormatRFC3966]);
        
        deNumber = [[NBPhoneNumber alloc] init];
        [deNumber setCountryCode:@49];
        [deNumber setNationalNumber:@291123];
        XCTAssertEqualObjects(@"0291 123", [phoneUtil format:deNumber numberFormat:NBEPhoneNumberFormatNATIONAL]);
        XCTAssertEqualObjects(@"+49 291 123", [phoneUtil format:deNumber numberFormat:NBEPhoneNumberFormatINTERNATIONAL]);
        
        deNumber = [[NBPhoneNumber alloc] init];
        [deNumber setCountryCode:@49];
        [deNumber setNationalNumber:@29112345678];
        XCTAssertEqualObjects(@"0291 12345678", [phoneUtil format:deNumber numberFormat:NBEPhoneNumberFormatNATIONAL]);
        XCTAssertEqualObjects(@"+49 291 12345678", [phoneUtil format:deNumber numberFormat:NBEPhoneNumberFormatINTERNATIONAL]);
        
        deNumber = [[NBPhoneNumber alloc] init];
        [deNumber setCountryCode:@49];
        [deNumber setNationalNumber:@912312345];
        XCTAssertEqualObjects(@"09123 12345", [phoneUtil format:deNumber numberFormat:NBEPhoneNumberFormatNATIONAL]);
        XCTAssertEqualObjects(@"+49 9123 12345", [phoneUtil format:deNumber numberFormat:NBEPhoneNumberFormatINTERNATIONAL]);
        
        deNumber = [[NBPhoneNumber alloc] init];
        [deNumber setCountryCode:@49];
        [deNumber setNationalNumber:@80212345];
        XCTAssertEqualObjects(@"08021 2345", [phoneUtil format:deNumber numberFormat:NBEPhoneNumberFormatNATIONAL]);
        XCTAssertEqualObjects(@"+49 8021 2345", [phoneUtil format:deNumber numberFormat:NBEPhoneNumberFormatINTERNATIONAL]);
        
        // Note this number is correctly formatted without national prefix. Most of
        // the numbers that are treated as invalid numbers by the library are short
        // numbers, and they are usually not dialed with national prefix.
        XCTAssertEqualObjects(@"1234", [phoneUtil format:DE_SHORT_NUMBER numberFormat:NBEPhoneNumberFormatNATIONAL]);
        XCTAssertEqualObjects(@"+49 1234", [phoneUtil format:DE_SHORT_NUMBER numberFormat:NBEPhoneNumberFormatINTERNATIONAL]);
        
        deNumber = [[NBPhoneNumber alloc] init];
        [deNumber setCountryCode:@49];
        [deNumber setNationalNumber:@41341234];
        XCTAssertEqualObjects(@"04134 1234", [phoneUtil format:deNumber numberFormat:NBEPhoneNumberFormatNATIONAL]);
    }

    #pragma mark - testFormatITNumber
    {
        XCTAssertEqualObjects(@"02 3661 8300", [phoneUtil format:IT_NUMBER numberFormat:NBEPhoneNumberFormatNATIONAL]);
        XCTAssertEqualObjects(@"+39 02 3661 8300", [phoneUtil format:IT_NUMBER numberFormat:NBEPhoneNumberFormatINTERNATIONAL]);
        XCTAssertEqualObjects(@"+390236618300", [phoneUtil format:IT_NUMBER numberFormat:NBEPhoneNumberFormatE164]);
        XCTAssertEqualObjects(@"345 678 901", [phoneUtil format:IT_MOBILE numberFormat:NBEPhoneNumberFormatNATIONAL]);
        XCTAssertEqualObjects(@"+39 345 678 901", [phoneUtil format:IT_MOBILE numberFormat:NBEPhoneNumberFormatINTERNATIONAL]);
        XCTAssertEqualObjects(@"+39345678901", [phoneUtil format:IT_MOBILE numberFormat:NBEPhoneNumberFormatE164]);
    }

    #pragma mark - testFormatAUNumber
    {
        XCTAssertEqualObjects(@"02 3661 8300", [phoneUtil format:AU_NUMBER numberFormat:NBEPhoneNumberFormatNATIONAL]);
        XCTAssertEqualObjects(@"+61 2 3661 8300", [phoneUtil format:AU_NUMBER numberFormat:NBEPhoneNumberFormatINTERNATIONAL]);
        XCTAssertEqualObjects(@"+61236618300", [phoneUtil format:AU_NUMBER numberFormat:NBEPhoneNumberFormatE164]);
        
        id auNumber = [[NBPhoneNumber alloc] init];
        [auNumber setCountryCode:@61];
        [auNumber setNationalNumber:@1800123456];
        XCTAssertEqualObjects(@"1800 123 456", [phoneUtil format:auNumber numberFormat:NBEPhoneNumberFormatNATIONAL]);
        XCTAssertEqualObjects(@"+61 1800 123 456", [phoneUtil format:auNumber numberFormat:NBEPhoneNumberFormatINTERNATIONAL]);
        XCTAssertEqualObjects(@"+611800123456", [phoneUtil format:auNumber numberFormat:NBEPhoneNumberFormatE164]);
    }

    #pragma mark - testFormatARNumber
    {
        XCTAssertEqualObjects(@"011 8765-4321", [phoneUtil format:AR_NUMBER numberFormat:NBEPhoneNumberFormatNATIONAL]);
        XCTAssertEqualObjects(@"+54 11 8765-4321", [phoneUtil format:AR_NUMBER numberFormat:NBEPhoneNumberFormatINTERNATIONAL]);
        XCTAssertEqualObjects(@"+541187654321", [phoneUtil format:AR_NUMBER numberFormat:NBEPhoneNumberFormatE164]);
        XCTAssertEqualObjects(@"011 15 8765-4321", [phoneUtil format:AR_MOBILE numberFormat:NBEPhoneNumberFormatNATIONAL]);
        XCTAssertEqualObjects(@"+54 9 11 8765 4321", [phoneUtil format:AR_MOBILE numberFormat:NBEPhoneNumberFormatINTERNATIONAL]);
        XCTAssertEqualObjects(@"+5491187654321", [phoneUtil format:AR_MOBILE numberFormat:NBEPhoneNumberFormatE164]);
    }

    #pragma mark - testFormatMXNumber
    {
        XCTAssertEqualObjects(@"045 234 567 8900", [phoneUtil format:MX_MOBILE1 numberFormat:NBEPhoneNumberFormatNATIONAL]);
        XCTAssertEqualObjects(@"+52 1 234 567 8900", [phoneUtil format:MX_MOBILE1 numberFormat:NBEPhoneNumberFormatINTERNATIONAL]);
        XCTAssertEqualObjects(@"+5212345678900", [phoneUtil format:MX_MOBILE1 numberFormat:NBEPhoneNumberFormatE164]);
        XCTAssertEqualObjects(@"045 55 1234 5678", [phoneUtil format:MX_MOBILE2 numberFormat:NBEPhoneNumberFormatNATIONAL]);
        XCTAssertEqualObjects(@"+52 1 55 1234 5678", [phoneUtil format:MX_MOBILE2 numberFormat:NBEPhoneNumberFormatINTERNATIONAL]);
        XCTAssertEqualObjects(@"+5215512345678", [phoneUtil format:MX_MOBILE2 numberFormat:NBEPhoneNumberFormatE164]);
        XCTAssertEqualObjects(@"01 33 1234 5678", [phoneUtil format:MX_NUMBER1 numberFormat:NBEPhoneNumberFormatNATIONAL]);
        XCTAssertEqualObjects(@"+52 33 1234 5678", [phoneUtil format:MX_NUMBER1 numberFormat:NBEPhoneNumberFormatINTERNATIONAL]);
        XCTAssertEqualObjects(@"+523312345678", [phoneUtil format:MX_NUMBER1 numberFormat:NBEPhoneNumberFormatE164]);
        XCTAssertEqualObjects(@"01 821 123 4567", [phoneUtil format:MX_NUMBER2 numberFormat:NBEPhoneNumberFormatNATIONAL]);
        XCTAssertEqualObjects(@"+52 821 123 4567", [phoneUtil format:MX_NUMBER2 numberFormat:NBEPhoneNumberFormatINTERNATIONAL]);
        XCTAssertEqualObjects(@"+528211234567", [phoneUtil format:MX_NUMBER2 numberFormat:NBEPhoneNumberFormatE164]);
    }

    #pragma mark - testFormatOutOfCountryCallingNumber
    {
        XCTAssertEqualObjects(@"00 1 900 253 0000", [phoneUtil formatOutOfCountryCallingNumber:US_PREMIUM regionCallingFrom:@"DE"]);
        XCTAssertEqualObjects(@"1 650 253 0000", [phoneUtil formatOutOfCountryCallingNumber:US_NUMBER regionCallingFrom:@"BS"]);
        XCTAssertEqualObjects(@"00 1 650 253 0000", [phoneUtil formatOutOfCountryCallingNumber:US_NUMBER regionCallingFrom:@"PL"]);
        XCTAssertEqualObjects(@"011 44 7912 345 678", [phoneUtil formatOutOfCountryCallingNumber:GB_MOBILE regionCallingFrom:@"US"]);
        XCTAssertEqualObjects(@"00 49 1234", [phoneUtil formatOutOfCountryCallingNumber:DE_SHORT_NUMBER regionCallingFrom:@"GB"]);
        // Note this number is correctly formatted without national prefix. Most of
        // the numbers that are treated as invalid numbers by the library are short
        // numbers, and they are usually not dialed with national prefix.
        XCTAssertEqualObjects(@"1234", [phoneUtil formatOutOfCountryCallingNumber:DE_SHORT_NUMBER regionCallingFrom:@"DE"]);
        XCTAssertEqualObjects(@"011 39 02 3661 8300", [phoneUtil formatOutOfCountryCallingNumber:IT_NUMBER regionCallingFrom:@"US"]);
        XCTAssertEqualObjects(@"02 3661 8300", [phoneUtil formatOutOfCountryCallingNumber:IT_NUMBER regionCallingFrom:@"IT"]);
        XCTAssertEqualObjects(@"+39 02 3661 8300", [phoneUtil formatOutOfCountryCallingNumber:IT_NUMBER regionCallingFrom:@"SG"]);
        XCTAssertEqualObjects(@"6521 8000", [phoneUtil formatOutOfCountryCallingNumber:SG_NUMBER regionCallingFrom:@"SG"]);
        XCTAssertEqualObjects(@"011 54 9 11 8765 4321", [phoneUtil formatOutOfCountryCallingNumber:AR_MOBILE regionCallingFrom:@"US"]);
        XCTAssertEqualObjects(@"011 800 1234 5678", [phoneUtil formatOutOfCountryCallingNumber:INTERNATIONAL_TOLL_FREE regionCallingFrom:@"US"]);
        
        id arNumberWithExtn = [AR_MOBILE copy];
        [arNumberWithExtn setExtension:@"1234"];
        XCTAssertEqualObjects(@"011 54 9 11 8765 4321 ext. 1234", [phoneUtil formatOutOfCountryCallingNumber:arNumberWithExtn regionCallingFrom:@"US"]);
        XCTAssertEqualObjects(@"0011 54 9 11 8765 4321 ext. 1234", [phoneUtil formatOutOfCountryCallingNumber:arNumberWithExtn regionCallingFrom:@"AU"]);
        XCTAssertEqualObjects(@"011 15 8765-4321 ext. 1234", [phoneUtil formatOutOfCountryCallingNumber:arNumberWithExtn regionCallingFrom:@"AR"]);
    }

    
    #pragma mark - testFormatOutOfCountryWithInvalidRegion
    {
        // AQ/Antarctica isn't a valid region code for phone number formatting,
        // so this falls back to intl formatting.
        XCTAssertEqualObjects(@"+1 650 253 0000", [phoneUtil formatOutOfCountryCallingNumber:US_NUMBER regionCallingFrom:@"AQ"]);
        // For region code 001, the out-of-country format always turns into the
        // international format.
        XCTAssertEqualObjects(@"+1 650 253 0000", [phoneUtil formatOutOfCountryCallingNumber:US_NUMBER regionCallingFrom:@"001"]);
    }
    

    #pragma mark - testFormatOutOfCountryWithPreferredIntlPrefix
    {
        // This should use 0011, since that is the preferred international prefix
        // (both 0011 and 0012 are accepted as possible international prefixes in our
        // test metadta.)
        XCTAssertEqualObjects(@"0011 39 02 3661 8300", [phoneUtil formatOutOfCountryCallingNumber:IT_NUMBER regionCallingFrom:@"AU"]);
    }
    

    #pragma mark - testFormatOutOfCountryKeepingAlphaChars
    {
        id alphaNumericNumber = [[NBPhoneNumber alloc] init];
        [alphaNumericNumber setCountryCode:@1];
        [alphaNumericNumber setNationalNumber:@8007493524];
        [alphaNumericNumber setRawInput:@"1800 six-flag"];
        XCTAssertEqualObjects(@"0011 1 800 SIX-FLAG", [phoneUtil formatOutOfCountryKeepingAlphaChars:alphaNumericNumber regionCallingFrom:@"AU"]);
        
        [alphaNumericNumber setRawInput:@"1-800-SIX-flag"];
        XCTAssertEqualObjects(@"0011 1 800-SIX-FLAG", [phoneUtil formatOutOfCountryKeepingAlphaChars:alphaNumericNumber regionCallingFrom:@"AU"]);
        
        [alphaNumericNumber setRawInput:@"Call us from UK: 00 1 800 SIX-flag"];
        XCTAssertEqualObjects(@"0011 1 800 SIX-FLAG", [phoneUtil formatOutOfCountryKeepingAlphaChars:alphaNumericNumber regionCallingFrom:@"AU"]);
        
        [alphaNumericNumber setRawInput:@"800 SIX-flag"];
        XCTAssertEqualObjects(@"0011 1 800 SIX-FLAG", [phoneUtil formatOutOfCountryKeepingAlphaChars:alphaNumericNumber regionCallingFrom:@"AU"]);
        
        // Formatting from within the NANPA region.
        XCTAssertEqualObjects(@"1 800 SIX-FLAG", [phoneUtil formatOutOfCountryKeepingAlphaChars:alphaNumericNumber regionCallingFrom:@"US"]);
        XCTAssertEqualObjects(@"1 800 SIX-FLAG", [phoneUtil formatOutOfCountryKeepingAlphaChars:alphaNumericNumber regionCallingFrom:@"BS"]);
        
        // Testing that if the raw input doesn't exist, it is formatted using
        // formatOutOfCountryCallingNumber.
        [alphaNumericNumber setRawInput:nil];
        XCTAssertEqualObjects(@"00 1 800 749 3524", [phoneUtil formatOutOfCountryKeepingAlphaChars:alphaNumericNumber regionCallingFrom:@"DE"]);
        
        // Testing AU alpha number formatted from Australia.
        [alphaNumericNumber setCountryCode:@61];
        [alphaNumericNumber setNationalNumber:@827493524];
        [alphaNumericNumber setRawInput:@"+61 82749-FLAG"];
        // This number should have the national prefix fixed.
        XCTAssertEqualObjects(@"082749-FLAG", [phoneUtil formatOutOfCountryKeepingAlphaChars:alphaNumericNumber regionCallingFrom:@"AU"]);
        
        [alphaNumericNumber setRawInput:@"082749-FLAG"];
        XCTAssertEqualObjects(@"082749-FLAG", [phoneUtil formatOutOfCountryKeepingAlphaChars:alphaNumericNumber regionCallingFrom:@"AU"]);
        
        [alphaNumericNumber setNationalNumber:@18007493524];
        [alphaNumericNumber setRawInput:@"1-800-SIX-flag"];
        // This number should not have the national prefix prefixed, in accordance
        // with the override for this specific formatting rule.
        XCTAssertEqualObjects(@"1-800-SIX-FLAG", [phoneUtil formatOutOfCountryKeepingAlphaChars:alphaNumericNumber regionCallingFrom:@"AU"]);
        
        // The metadata should not be permanently changed, since we copied it before
        // modifying patterns. Here we check this.
        [alphaNumericNumber setNationalNumber:@1800749352];
        XCTAssertEqualObjects(@"1800 749 352", [phoneUtil formatOutOfCountryCallingNumber:alphaNumericNumber regionCallingFrom:@"AU"]);
        
        // Testing a region with multiple international prefixes.
        XCTAssertEqualObjects(@"+61 1-800-SIX-FLAG", [phoneUtil formatOutOfCountryKeepingAlphaChars:alphaNumericNumber regionCallingFrom:@"SG"]);
        // Testing the case of calling from a non-supported region.
        XCTAssertEqualObjects(@"+61 1-800-SIX-FLAG", [phoneUtil formatOutOfCountryKeepingAlphaChars:alphaNumericNumber regionCallingFrom:@"AQ"]);
        
        // Testing the case with an invalid country calling code.
        [alphaNumericNumber setCountryCode:0];
        [alphaNumericNumber setNationalNumber:@18007493524];
        [alphaNumericNumber setRawInput:@"1-800-SIX-flag"];
        // Uses the raw input only.
        XCTAssertEqualObjects(@"1-800-SIX-flag", [phoneUtil formatOutOfCountryKeepingAlphaChars:alphaNumericNumber regionCallingFrom:@"DE"]);
        
        // Testing the case of an invalid alpha number.
        [alphaNumericNumber setCountryCode:@1];
        [alphaNumericNumber setNationalNumber:@80749];
        [alphaNumericNumber setRawInput:@"180-SIX"];
        // No country-code stripping can be done.
        XCTAssertEqualObjects(@"00 1 180-SIX", [phoneUtil formatOutOfCountryKeepingAlphaChars:alphaNumericNumber regionCallingFrom:@"DE"]);
        
        // Testing the case of calling from a non-supported region.
        [alphaNumericNumber setCountryCode:@1];
        [alphaNumericNumber setNationalNumber:@80749];
        [alphaNumericNumber setRawInput:@"180-SIX"];
        // No country-code stripping can be done since the number is invalid.
        XCTAssertEqualObjects(@"+1 180-SIX", [phoneUtil formatOutOfCountryKeepingAlphaChars:alphaNumericNumber regionCallingFrom:@"AQ"]);
    }
    

    #pragma mark - testFormatWithCarrierCode()
    {
        // We only support this for AR in our test metadata, and only for mobile
        // numbers starting with certain values.
        
        NBPhoneNumber *arMobile = [[NBPhoneNumber alloc] init];
        [arMobile setCountryCode:@54];
        [arMobile setNationalNumber:@92234654321];
        XCTAssertEqualObjects(@"02234 65-4321", [phoneUtil format:arMobile numberFormat:NBEPhoneNumberFormatNATIONAL]);
        // Here we force 14 as the carrier code.
        XCTAssertEqualObjects(@"02234 14 65-4321", [phoneUtil formatNationalNumberWithCarrierCode:arMobile carrierCode:@"14"]);
        // Here we force the number to be shown with no carrier code.
        XCTAssertEqualObjects(@"02234 65-4321", [phoneUtil formatNationalNumberWithCarrierCode:arMobile carrierCode:@""]);
        // Here the international rule is used, so no carrier code should be present.
        XCTAssertEqualObjects(@"+5492234654321", [phoneUtil format:arMobile numberFormat:NBEPhoneNumberFormatE164]);
        // We don't support this for the US so there should be no change.
        XCTAssertEqualObjects(@"650 253 0000", [phoneUtil formatNationalNumberWithCarrierCode:US_NUMBER carrierCode:@"15"]);
        // Invalid country code should just get the NSN.
        XCTAssertEqualObjects(@"12345", [phoneUtil formatNationalNumberWithCarrierCode:UNKNOWN_COUNTRY_CODE_NO_RAW_INPUT carrierCode:@"89"]);
    }
    

    #pragma mark - testFormatWithPreferredCarrierCode
    {
        // We only support this for AR in our test metadata.
        
        NBPhoneNumber *arNumber = [[NBPhoneNumber alloc] init];
        [arNumber setCountryCode:@54];
        [arNumber setNationalNumber:@91234125678];
        // Test formatting with no preferred carrier code stored in the number itself.
        XCTAssertEqualObjects(@"01234 15 12-5678", [phoneUtil formatNationalNumberWithPreferredCarrierCode:arNumber fallbackCarrierCode:@"15"]);
        XCTAssertEqualObjects(@"01234 12-5678", [phoneUtil formatNationalNumberWithPreferredCarrierCode:arNumber fallbackCarrierCode:@""]);
        // Test formatting with preferred carrier code present.
        [arNumber setPreferredDomesticCarrierCode:@"19"];
        XCTAssertEqualObjects(@"01234 12-5678", [phoneUtil format:arNumber numberFormat:NBEPhoneNumberFormatNATIONAL]);
        XCTAssertEqualObjects(@"01234 19 12-5678", [phoneUtil formatNationalNumberWithPreferredCarrierCode:arNumber fallbackCarrierCode:@"15"]);
        XCTAssertEqualObjects(@"01234 19 12-5678", [phoneUtil formatNationalNumberWithPreferredCarrierCode:arNumber fallbackCarrierCode:@""]);
        // When the preferred_domestic_carrier_code is present (even when it contains
        // an empty string), use it instead of the default carrier code passed in.
        [arNumber setPreferredDomesticCarrierCode:@""];
        XCTAssertEqualObjects(@"01234 12-5678", [phoneUtil formatNationalNumberWithPreferredCarrierCode:arNumber fallbackCarrierCode:@"15"]);
        // We don't support this for the US so there should be no change.
        
        NBPhoneNumber *usNumber = [[NBPhoneNumber alloc] init];
        [usNumber setCountryCode:@1];
        [usNumber setNationalNumber:@4241231234];
        [usNumber setPreferredDomesticCarrierCode:@"99"];
        XCTAssertEqualObjects(@"424 123 1234", [phoneUtil format:usNumber numberFormat:NBEPhoneNumberFormatNATIONAL]);
        XCTAssertEqualObjects(@"424 123 1234", [phoneUtil formatNationalNumberWithPreferredCarrierCode:usNumber fallbackCarrierCode:@"15"]);
    }
    

    #pragma mark - testFormatNumberForMobileDialing
    {
        // Numbers are normally dialed in national format in-country, and
        // international format from outside the country.
        XCTAssertEqualObjects(@"030123456", [phoneUtil formatNumberForMobileDialing:DE_NUMBER regionCallingFrom:@"DE" withFormatting:NO]);
        XCTAssertEqualObjects(@"+4930123456", [phoneUtil formatNumberForMobileDialing:DE_NUMBER regionCallingFrom:@"CH" withFormatting:NO]);
        id deNumberWithExtn = [DE_NUMBER copy];
        [deNumberWithExtn setExtension:@"1234"];
        XCTAssertEqualObjects(@"030123456", [phoneUtil formatNumberForMobileDialing:deNumberWithExtn regionCallingFrom:@"DE" withFormatting:NO]);
        XCTAssertEqualObjects(@"+4930123456", [phoneUtil formatNumberForMobileDialing:deNumberWithExtn regionCallingFrom:@"CH" withFormatting:NO]);
        
        // US toll free numbers are marked as noInternationalDialling in the test
        // metadata for testing purposes.
        XCTAssertEqualObjects(@"800 253 0000", [phoneUtil formatNumberForMobileDialing:US_TOLLFREE regionCallingFrom:@"US" withFormatting:YES]);
        XCTAssertEqualObjects(@"", [phoneUtil formatNumberForMobileDialing:US_TOLLFREE regionCallingFrom:@"CN" withFormatting:YES]);
        XCTAssertEqualObjects(@"+1 650 253 0000", [phoneUtil formatNumberForMobileDialing:US_NUMBER regionCallingFrom:@"US" withFormatting:YES]);
        
        id usNumberWithExtn = [US_NUMBER copy];
        [usNumberWithExtn setExtension:@"1234"];
        XCTAssertEqualObjects(@"+1 650 253 0000", [phoneUtil formatNumberForMobileDialing:usNumberWithExtn regionCallingFrom:@"US" withFormatting:YES]);
        XCTAssertEqualObjects(@"8002530000", [phoneUtil formatNumberForMobileDialing:US_TOLLFREE regionCallingFrom:@"US" withFormatting:NO]);
        XCTAssertEqualObjects(@"", [phoneUtil formatNumberForMobileDialing:US_TOLLFREE regionCallingFrom:@"CN" withFormatting:NO]);
        XCTAssertEqualObjects(@"+16502530000", [phoneUtil formatNumberForMobileDialing:US_NUMBER regionCallingFrom:@"US" withFormatting:NO]);
        XCTAssertEqualObjects(@"+16502530000", [phoneUtil formatNumberForMobileDialing:usNumberWithExtn regionCallingFrom:@"US" withFormatting:NO]);

        // An invalid US number, which is one digit too long.
        XCTAssertEqualObjects(@"+165025300001", [phoneUtil formatNumberForMobileDialing:US_LONG_NUMBER regionCallingFrom:@"US" withFormatting:NO]);
        XCTAssertEqualObjects(@"+1 65025300001", [phoneUtil formatNumberForMobileDialing:US_LONG_NUMBER regionCallingFrom:@"US" withFormatting:YES]);

        // Star numbers. In real life they appear in Israel, but we have them in JP
        // in our test metadata.
        XCTAssertEqualObjects(@"*2345", [phoneUtil formatNumberForMobileDialing:JP_STAR_NUMBER regionCallingFrom:@"JP" withFormatting:NO]);
        XCTAssertEqualObjects(@"*2345", [phoneUtil formatNumberForMobileDialing:JP_STAR_NUMBER regionCallingFrom:@"JP" withFormatting:YES]);
        XCTAssertEqualObjects(@"+80012345678", [phoneUtil formatNumberForMobileDialing:INTERNATIONAL_TOLL_FREE regionCallingFrom:@"JP" withFormatting:NO]);
        XCTAssertEqualObjects(@"+800 1234 5678", [phoneUtil formatNumberForMobileDialing:INTERNATIONAL_TOLL_FREE regionCallingFrom:@"JP" withFormatting:YES]);
        
        // UAE numbers beginning with 600 (classified as UAN) need to be dialled
        // without +971 locally.
        XCTAssertEqualObjects(@"+971600123456", [phoneUtil formatNumberForMobileDialing:AE_UAN regionCallingFrom:@"JP" withFormatting:NO]);
        XCTAssertEqualObjects(@"600123456", [phoneUtil formatNumberForMobileDialing:AE_UAN regionCallingFrom:@"AE" withFormatting:NO]);
        XCTAssertEqualObjects(@"+523312345678",
                             [phoneUtil formatNumberForMobileDialing:MX_NUMBER1 regionCallingFrom:@"MX" withFormatting:NO]);
        XCTAssertEqualObjects(@"+523312345678",
                             [phoneUtil formatNumberForMobileDialing:MX_NUMBER1 regionCallingFrom:@"US" withFormatting:NO]);
        
        // Non-geographical numbers should always be dialed in international format.
        XCTAssertEqualObjects(@"+80012345678", [phoneUtil formatNumberForMobileDialing:INTERNATIONAL_TOLL_FREE regionCallingFrom:@"US" withFormatting:NO]);
        XCTAssertEqualObjects(@"+80012345678", [phoneUtil formatNumberForMobileDialing:INTERNATIONAL_TOLL_FREE regionCallingFrom:@"UN001" withFormatting:NO]);

    }

    
    #pragma mark - testFormatByPattern
    {
        NBNumberFormat *newNumFormat = [[NBNumberFormat alloc] init];
        [newNumFormat setPattern:@"(\\d{3})(\\d{3})(\\d{4})"];
        [newNumFormat setFormat:@"($1) $2-$3"];
        
        XCTAssertEqualObjects(@"(650) 253-0000", [phoneUtil formatByPattern:US_NUMBER numberFormat:NBEPhoneNumberFormatNATIONAL userDefinedFormats:@[newNumFormat]]);
        
        XCTAssertEqualObjects(@"+1 (650) 253-0000", [phoneUtil formatByPattern:US_NUMBER numberFormat:NBEPhoneNumberFormatINTERNATIONAL userDefinedFormats:@[newNumFormat]]);
        XCTAssertEqualObjects(@"tel:+1-650-253-0000", [phoneUtil formatByPattern:US_NUMBER numberFormat:NBEPhoneNumberFormatRFC3966 userDefinedFormats:@[newNumFormat]]);
        
        // $NP is set to '1' for the US. Here we check that for other NANPA countries
        // the US rules are followed.
        [newNumFormat setNationalPrefixFormattingRule:@"$NP ($FG)"];
        [newNumFormat setFormat:@"$1 $2-$3"];
        XCTAssertEqualObjects(@"1 (242) 365-1234", [phoneUtil formatByPattern:BS_NUMBER numberFormat:NBEPhoneNumberFormatNATIONAL userDefinedFormats:@[newNumFormat]]);
        XCTAssertEqualObjects(@"+1 242 365-1234", [phoneUtil formatByPattern:BS_NUMBER numberFormat:NBEPhoneNumberFormatINTERNATIONAL userDefinedFormats:@[newNumFormat]]);
        
        [newNumFormat setPattern:@"(\\d{2})(\\d{5})(\\d{3})"];
        [newNumFormat setFormat:@"$1-$2 $3"];
        
        XCTAssertEqualObjects(@"02-36618 300", [phoneUtil formatByPattern:IT_NUMBER numberFormat:NBEPhoneNumberFormatNATIONAL userDefinedFormats:@[newNumFormat]]);
        XCTAssertEqualObjects(@"+39 02-36618 300", [phoneUtil formatByPattern:IT_NUMBER numberFormat:NBEPhoneNumberFormatINTERNATIONAL userDefinedFormats:@[newNumFormat]]);
        
        [newNumFormat setNationalPrefixFormattingRule:@"$NP$FG"];
        [newNumFormat setPattern:@"(\\d{2})(\\d{4})(\\d{4})"];
        [newNumFormat setFormat:@"$1 $2 $3"];
        XCTAssertEqualObjects(@"020 7031 3000", [phoneUtil formatByPattern:GB_NUMBER numberFormat:NBEPhoneNumberFormatNATIONAL userDefinedFormats:@[newNumFormat]]);
        
        [newNumFormat setNationalPrefixFormattingRule:@"($NP$FG)"];
        XCTAssertEqualObjects(@"(020) 7031 3000", [phoneUtil formatByPattern:GB_NUMBER numberFormat:NBEPhoneNumberFormatNATIONAL userDefinedFormats:@[newNumFormat]]);
        
        [newNumFormat setNationalPrefixFormattingRule:@""];
        XCTAssertEqualObjects(@"20 7031 3000", [phoneUtil formatByPattern:GB_NUMBER numberFormat:NBEPhoneNumberFormatNATIONAL userDefinedFormats:@[newNumFormat]]);
        XCTAssertEqualObjects(@"+44 20 7031 3000", [phoneUtil formatByPattern:GB_NUMBER numberFormat:NBEPhoneNumberFormatINTERNATIONAL userDefinedFormats:@[newNumFormat]]);
    }
    

    #pragma mark - testFormatE164Number
    {
        XCTAssertEqualObjects(@"+16502530000", [phoneUtil format:US_NUMBER numberFormat:NBEPhoneNumberFormatE164]);
        XCTAssertEqualObjects(@"+4930123456", [phoneUtil format:DE_NUMBER numberFormat:NBEPhoneNumberFormatE164]);
        XCTAssertEqualObjects(@"+80012345678", [phoneUtil format:INTERNATIONAL_TOLL_FREE numberFormat:NBEPhoneNumberFormatE164]);
    }
    

    #pragma mark - testFormatNumberWithExtension
    {
        id nzNumber = [NZ_NUMBER copy];
        [nzNumber setExtension:@"1234"];
        // Uses default extension prefix:
        XCTAssertEqualObjects(@"03-331 6005 ext. 1234", [phoneUtil format:nzNumber numberFormat:NBEPhoneNumberFormatNATIONAL]);
        // Uses RFC 3966 syntax.
        XCTAssertEqualObjects(@"tel:+64-3-331-6005;ext=1234", [phoneUtil format:nzNumber numberFormat:NBEPhoneNumberFormatRFC3966]);
        // Extension prefix overridden in the territory information for the US:
        
        id usNumberWithExtension = [US_NUMBER copy];
        [usNumberWithExtension setExtension:@"4567"];
        XCTAssertEqualObjects(@"650 253 0000 extn. 4567", [phoneUtil format:usNumberWithExtension numberFormat:NBEPhoneNumberFormatNATIONAL]);
    }


    #pragma mark - testFormatInOriginalFormat
    {
        NSError *aError = nil;
        NBPhoneNumber *number1 = [phoneUtil parseAndKeepRawInput:@"+442087654321" defaultRegion:@"GB" error:&aError];
        XCTAssertEqualObjects(@"+44 20 8765 4321", [phoneUtil formatInOriginalFormat:number1 regionCallingFrom:@"GB"]);
        
        NBPhoneNumber *number2 = [phoneUtil parseAndKeepRawInput:@"02087654321" defaultRegion:@"GB" error:&aError];
        XCTAssertEqualObjects(@"(020) 8765 4321", [phoneUtil formatInOriginalFormat:number2 regionCallingFrom:@"GB"]);
        
        NBPhoneNumber *number3 = [phoneUtil parseAndKeepRawInput:@"011442087654321" defaultRegion:@"US" error:&aError];
        XCTAssertEqualObjects(@"011 44 20 8765 4321", [phoneUtil formatInOriginalFormat:number3 regionCallingFrom:@"US"]);
        
        NBPhoneNumber *number4 = [phoneUtil parseAndKeepRawInput:@"442087654321" defaultRegion:@"GB" error:&aError];
        XCTAssertEqualObjects(@"44 20 8765 4321", [phoneUtil formatInOriginalFormat:number4 regionCallingFrom:@"GB"]);
        
        NBPhoneNumber *number5 = [phoneUtil parse:@"+442087654321" defaultRegion:@"GB" error:&aError];
        XCTAssertEqualObjects(@"(020) 8765 4321", [phoneUtil formatInOriginalFormat:number5 regionCallingFrom:@"GB"]);
        
        // Invalid numbers that we have a formatting pattern for should be formatted
        // properly. Note area codes starting with 7 are intentionally excluded in
        // the test metadata for testing purposes.
        NBPhoneNumber *number6 = [phoneUtil parseAndKeepRawInput:@"7345678901" defaultRegion:@"US" error:&aError];
        XCTAssertEqualObjects(@"734 567 8901", [phoneUtil formatInOriginalFormat:number6 regionCallingFrom:@"US"]);
        
        // US is not a leading zero country, and the presence of the leading zero
        // leads us to format the number using raw_input.
        NBPhoneNumber *number7 = [phoneUtil parseAndKeepRawInput:@"0734567 8901" defaultRegion:@"US" error:&aError];
        XCTAssertEqualObjects(@"0734567 8901", [phoneUtil formatInOriginalFormat:number7 regionCallingFrom:@"US"]);
        
        // This number is valid, but we don't have a formatting pattern for it.
        // Fall back to the raw input.
        NBPhoneNumber *number8 = [phoneUtil parseAndKeepRawInput:@"02-4567-8900" defaultRegion:@"KR" error:&aError];
        XCTAssertEqualObjects(@"02-4567-8900", [phoneUtil formatInOriginalFormat:number8 regionCallingFrom:@"KR"]);
        
        NBPhoneNumber *number9 = [phoneUtil parseAndKeepRawInput:@"01180012345678" defaultRegion:@"US" error:&aError];
        XCTAssertEqualObjects(@"011 800 1234 5678", [phoneUtil formatInOriginalFormat:number9 regionCallingFrom:@"US"]);
        
        NBPhoneNumber *number10 = [phoneUtil parseAndKeepRawInput:@"+80012345678" defaultRegion:@"KR" error:&aError];
        XCTAssertEqualObjects(@"+800 1234 5678", [phoneUtil formatInOriginalFormat:number10 regionCallingFrom:@"KR"]);
        
        // US local numbers are formatted correctly, as we have formatting patterns
        // for them.
        NBPhoneNumber *localNumberUS = [phoneUtil parseAndKeepRawInput:@"2530000" defaultRegion:@"US" error:&aError];
        XCTAssertEqualObjects(@"253 0000", [phoneUtil formatInOriginalFormat:localNumberUS regionCallingFrom:@"US"]);
        
        NBPhoneNumber *numberWithNationalPrefixUS = [phoneUtil parseAndKeepRawInput:@"18003456789" defaultRegion:@"US" error:&aError];
        XCTAssertEqualObjects(@"1 800 345 6789", [phoneUtil formatInOriginalFormat:numberWithNationalPrefixUS regionCallingFrom:@"US"]);
        
        NBPhoneNumber *numberWithoutNationalPrefixGB = [phoneUtil parseAndKeepRawInput:@"2087654321" defaultRegion:@"GB" error:&aError];
        XCTAssertEqualObjects(@"20 8765 4321", [phoneUtil formatInOriginalFormat:numberWithoutNationalPrefixGB regionCallingFrom:@"GB"]);
        
        // Make sure no metadata is modified as a result of the previous function
        // call.
        XCTAssertEqualObjects(@"(020) 8765 4321", [phoneUtil formatInOriginalFormat:number5 regionCallingFrom:@"GB" error:&aError]);
        
        NBPhoneNumber *numberWithNationalPrefixMX = [phoneUtil parseAndKeepRawInput:@"013312345678" defaultRegion:@"MX" error:&aError];
        XCTAssertEqualObjects(@"01 33 1234 5678", [phoneUtil formatInOriginalFormat:numberWithNationalPrefixMX regionCallingFrom:@"MX"]);
        
        NBPhoneNumber *numberWithoutNationalPrefixMX = [phoneUtil parseAndKeepRawInput:@"3312345678" defaultRegion:@"MX" error:&aError];
        XCTAssertEqualObjects(@"33 1234 5678", [phoneUtil formatInOriginalFormat:numberWithoutNationalPrefixMX regionCallingFrom:@"MX"]);
        
        NBPhoneNumber *italianFixedLineNumber = [phoneUtil parseAndKeepRawInput:@"0212345678" defaultRegion:@"IT" error:&aError];
        XCTAssertEqualObjects(@"02 1234 5678", [phoneUtil formatInOriginalFormat:italianFixedLineNumber regionCallingFrom:@"IT"]);
        
        NBPhoneNumber *numberWithNationalPrefixJP = [phoneUtil parseAndKeepRawInput:@"00777012" defaultRegion:@"JP" error:&aError];
        XCTAssertEqualObjects(@"0077-7012", [phoneUtil formatInOriginalFormat:numberWithNationalPrefixJP regionCallingFrom:@"JP"]);
        
        NBPhoneNumber *numberWithoutNationalPrefixJP = [phoneUtil parseAndKeepRawInput:@"0777012" defaultRegion:@"JP" error:&aError];
        XCTAssertEqualObjects(@"0777012", [phoneUtil formatInOriginalFormat:numberWithoutNationalPrefixJP regionCallingFrom:@"JP"]);
        
        NBPhoneNumber *numberWithCarrierCodeBR = [phoneUtil parseAndKeepRawInput:@"012 3121286979" defaultRegion:@"BR" error:&aError];
        XCTAssertEqualObjects(@"012 3121286979", [phoneUtil formatInOriginalFormat:numberWithCarrierCodeBR regionCallingFrom:@"BR"]);
        
        // The default national prefix used in this case is 045. When a number with
        // national prefix 044 is entered, we return the raw input as we don't want to
        // change the number entered.
        NBPhoneNumber *numberWithNationalPrefixMX1 = [phoneUtil parseAndKeepRawInput:@"044(33)1234-5678" defaultRegion:@"MX" error:&aError];
        XCTAssertEqualObjects(@"044(33)1234-5678", [phoneUtil formatInOriginalFormat:numberWithNationalPrefixMX1 regionCallingFrom:@"MX"]);
        
        NBPhoneNumber *numberWithNationalPrefixMX2 = [phoneUtil parseAndKeepRawInput:@"045(33)1234-5678" defaultRegion:@"MX" error:&aError];
        XCTAssertEqualObjects(@"045 33 1234 5678", [phoneUtil formatInOriginalFormat:numberWithNationalPrefixMX2 regionCallingFrom:@"MX"]);
        
        // The default international prefix used in this case is 0011. When a number
        // with international prefix 0012 is entered, we return the raw input as we
        // don't want to change the number entered.
        id outOfCountryNumberFromAU1 = [phoneUtil parseAndKeepRawInput:@"0012 16502530000" defaultRegion:@"AU" error:&aError];
        XCTAssertEqualObjects(@"0012 16502530000", [phoneUtil formatInOriginalFormat:outOfCountryNumberFromAU1 regionCallingFrom:@"AU"]);
        
        id outOfCountryNumberFromAU2 = [phoneUtil parseAndKeepRawInput:@"0011 16502530000" defaultRegion:@"AU" error:&aError];
        XCTAssertEqualObjects(@"0011 1 650 253 0000", [phoneUtil formatInOriginalFormat:outOfCountryNumberFromAU2 regionCallingFrom:@"AU"]);
        
        // Test the star sign is not removed from or added to the original input by
        // this method.
        id starNumber = [phoneUtil parseAndKeepRawInput:@"*1234" defaultRegion:@"JP" error:&aError];
        XCTAssertEqualObjects(@"*1234", [phoneUtil formatInOriginalFormat:starNumber regionCallingFrom:@"JP"]);
        
        NBPhoneNumber *numberWithoutStar = [phoneUtil parseAndKeepRawInput:@"1234" defaultRegion:@"JP" error:&aError];
        XCTAssertEqualObjects(@"1234", [phoneUtil formatInOriginalFormat:numberWithoutStar regionCallingFrom:@"JP"]);
        
        // Test an invalid national number without raw input is just formatted as the
        // national number.
        XCTAssertEqualObjects(@"650253000", [phoneUtil formatInOriginalFormat:US_SHORT_BY_ONE_NUMBER regionCallingFrom:@"US"]);
    }

    #pragma mark - testIsPremiumRate
    {
        XCTAssertEqual(NBEPhoneNumberTypePREMIUM_RATE, [phoneUtil getNumberType:US_PREMIUM]);
        
        NBPhoneNumber *premiumRateNumber = [[NBPhoneNumber alloc] init];
        premiumRateNumber = [[NBPhoneNumber alloc] init];
        [premiumRateNumber setCountryCode:@39];
        [premiumRateNumber setNationalNumber:@892123];
        XCTAssertEqual(NBEPhoneNumberTypePREMIUM_RATE, [phoneUtil getNumberType:premiumRateNumber]);
        
        premiumRateNumber = [[NBPhoneNumber alloc] init];
        [premiumRateNumber setCountryCode:@44];
        [premiumRateNumber setNationalNumber:@9187654321];
        XCTAssertEqual(NBEPhoneNumberTypePREMIUM_RATE, [phoneUtil getNumberType:premiumRateNumber]);
        
        premiumRateNumber = [[NBPhoneNumber alloc] init];
        [premiumRateNumber setCountryCode:@49];
        [premiumRateNumber setNationalNumber:@9001654321];
        XCTAssertEqual(NBEPhoneNumberTypePREMIUM_RATE, [phoneUtil getNumberType:premiumRateNumber]);
        
        premiumRateNumber = [[NBPhoneNumber alloc] init];
        [premiumRateNumber setCountryCode:@49];
        [premiumRateNumber setNationalNumber:@90091234567];
        XCTAssertEqual(NBEPhoneNumberTypePREMIUM_RATE, [phoneUtil getNumberType:premiumRateNumber]);
        XCTAssertEqual(NBEPhoneNumberTypePREMIUM_RATE, [phoneUtil getNumberType:UNIVERSAL_PREMIUM_RATE]);
    }
    

    #pragma mark - testIsTollFree
    {
        NBPhoneNumber *tollFreeNumber = [[NBPhoneNumber alloc] init];
        
        [tollFreeNumber setCountryCode:@1];
        [tollFreeNumber setNationalNumber:@8881234567];
        XCTAssertEqual(NBEPhoneNumberTypeTOLL_FREE, [phoneUtil getNumberType:tollFreeNumber]);
        
        tollFreeNumber = [[NBPhoneNumber alloc] init];
        [tollFreeNumber setCountryCode:@39];
        [tollFreeNumber setNationalNumber:@803123];
        XCTAssertEqual(NBEPhoneNumberTypeTOLL_FREE, [phoneUtil getNumberType:tollFreeNumber]);
        
        tollFreeNumber = [[NBPhoneNumber alloc] init];
        [tollFreeNumber setCountryCode:@44];
        [tollFreeNumber setNationalNumber:@8012345678];
        XCTAssertEqual(NBEPhoneNumberTypeTOLL_FREE, [phoneUtil getNumberType:tollFreeNumber]);
        
        tollFreeNumber = [[NBPhoneNumber alloc] init];
        [tollFreeNumber setCountryCode:@49];
        [tollFreeNumber setNationalNumber:@8001234567];
        XCTAssertEqual(NBEPhoneNumberTypeTOLL_FREE, [phoneUtil getNumberType:tollFreeNumber]);
        
        XCTAssertEqual(NBEPhoneNumberTypeTOLL_FREE, [phoneUtil getNumberType:INTERNATIONAL_TOLL_FREE]);
    }
    

    #pragma mark - testIsMobile
    {
        XCTAssertEqual(NBEPhoneNumberTypeMOBILE, [phoneUtil getNumberType:BS_MOBILE]);
        XCTAssertEqual(NBEPhoneNumberTypeMOBILE, [phoneUtil getNumberType:GB_MOBILE]);
        XCTAssertEqual(NBEPhoneNumberTypeMOBILE, [phoneUtil getNumberType:IT_MOBILE]);
        XCTAssertEqual(NBEPhoneNumberTypeMOBILE, [phoneUtil getNumberType:AR_MOBILE]);
        
        NBPhoneNumber *mobileNumber = [[NBPhoneNumber alloc] init];
        [mobileNumber setCountryCode:@49];
        [mobileNumber setNationalNumber:@15123456789];
        XCTAssertEqual(NBEPhoneNumberTypeMOBILE, [phoneUtil getNumberType:mobileNumber]);
    }

    
    #pragma mark - testIsFixedLine
    {
        XCTAssertEqual(NBEPhoneNumberTypeFIXED_LINE, [phoneUtil getNumberType:BS_NUMBER]);
        XCTAssertEqual(NBEPhoneNumberTypeFIXED_LINE, [phoneUtil getNumberType:IT_NUMBER]);
        XCTAssertEqual(NBEPhoneNumberTypeFIXED_LINE, [phoneUtil getNumberType:GB_NUMBER]);
        XCTAssertEqual(NBEPhoneNumberTypeFIXED_LINE, [phoneUtil getNumberType:DE_NUMBER]);
    }

    
    #pragma mark - testIsFixedLineAndMobile
    {
        XCTAssertEqual(NBEPhoneNumberTypeFIXED_LINE_OR_MOBILE, [phoneUtil getNumberType:US_NUMBER]);
        
        NBPhoneNumber *fixedLineAndMobileNumber = [[NBPhoneNumber alloc] init];
        [fixedLineAndMobileNumber setCountryCode:@54];
        [fixedLineAndMobileNumber setNationalNumber:@1987654321];
        XCTAssertEqual(NBEPhoneNumberTypeFIXED_LINE_OR_MOBILE, [phoneUtil getNumberType:fixedLineAndMobileNumber]);
    }

    
    #pragma mark - testIsSharedCost
    {
        NBPhoneNumber *gbNumber = [[NBPhoneNumber alloc] init];
        [gbNumber setCountryCode:@44];
        [gbNumber setNationalNumber:@8431231234];
        XCTAssertEqual(NBEPhoneNumberTypeSHARED_COST, [phoneUtil getNumberType:gbNumber]);
    }

    
    #pragma mark - testIsVoip
    {
        NBPhoneNumber *gbNumber = [[NBPhoneNumber alloc] init];
        [gbNumber setCountryCode:@44];
        [gbNumber setNationalNumber:@5631231234];
        XCTAssertEqual(NBEPhoneNumberTypeVOIP, [phoneUtil getNumberType:gbNumber]);
    }

    
    #pragma mark - testIsPersonalNumber
    {
        NBPhoneNumber *gbNumber = [[NBPhoneNumber alloc] init];
        [gbNumber setCountryCode:@44];
        [gbNumber setNationalNumber:@7031231234];
        XCTAssertEqual(NBEPhoneNumberTypePERSONAL_NUMBER, [phoneUtil getNumberType:gbNumber]);
    }
    

    #pragma mark - testIsUnknown
    {
        // Invalid numbers should be of type UNKNOWN.
        XCTAssertEqual(NBEPhoneNumberTypeUNKNOWN, [phoneUtil getNumberType:US_LOCAL_NUMBER]);
    }
    

    #pragma mark - testisValidNumber
    {
        XCTAssertTrue([phoneUtil isValidNumber:US_NUMBER]);
        XCTAssertTrue([phoneUtil isValidNumber:IT_NUMBER]);
        XCTAssertTrue([phoneUtil isValidNumber:GB_MOBILE]);
        XCTAssertTrue([phoneUtil isValidNumber:INTERNATIONAL_TOLL_FREE]);
        XCTAssertTrue([phoneUtil isValidNumber:UNIVERSAL_PREMIUM_RATE]);
        
        NBPhoneNumber *nzNumber = [[NBPhoneNumber alloc] init];
        [nzNumber setCountryCode:@64];
        [nzNumber setNationalNumber:@21387835];
        XCTAssertTrue([phoneUtil isValidNumber:nzNumber]);
    }

    
    #pragma mark - testIsValidForRegion
    {
        // This number is valid for the Bahamas, but is not a valid US number.
        XCTAssertTrue([phoneUtil isValidNumber:BS_NUMBER]);
        XCTAssertTrue([phoneUtil isValidNumberForRegion:BS_NUMBER regionCode:@"BS"]);
        XCTAssertFalse([phoneUtil isValidNumberForRegion:BS_NUMBER regionCode:@"US"]);
        
        NBPhoneNumber *bsInvalidNumber = [[NBPhoneNumber alloc] init];
        [bsInvalidNumber setCountryCode:@1];
        [bsInvalidNumber setNationalNumber:@2421232345];
        // This number is no longer valid.
        XCTAssertFalse([phoneUtil isValidNumber:bsInvalidNumber]);
        
        // La Mayotte and Reunion use 'leadingDigits' to differentiate them.
        
        NBPhoneNumber *reNumber = [[NBPhoneNumber alloc] init];
        [reNumber setCountryCode:@262];
        [reNumber setNationalNumber:@262123456];
        XCTAssertTrue([phoneUtil isValidNumber:reNumber]);
        XCTAssertTrue([phoneUtil isValidNumberForRegion:reNumber regionCode:@"RE"]);
        XCTAssertFalse([phoneUtil isValidNumberForRegion:reNumber regionCode:@"YT"]);
        
        // Now change the number to be a number for La Mayotte.
        [reNumber setNationalNumber:@269601234];
        XCTAssertTrue([phoneUtil isValidNumberForRegion:reNumber regionCode:@"YT"]);
        XCTAssertFalse([phoneUtil isValidNumberForRegion:reNumber regionCode:@"RE"]);
        
        // This number is no longer valid for La Reunion.
        [reNumber setNationalNumber:@269123456];
        XCTAssertFalse([phoneUtil isValidNumberForRegion:reNumber regionCode:@"YT"]);
        XCTAssertFalse([phoneUtil isValidNumberForRegion:reNumber regionCode:@"RE"]);
        XCTAssertFalse([phoneUtil isValidNumber:reNumber]);
        
        // However, it should be recognised as from La Mayotte, since it is valid for
        // this region.
        XCTAssertEqualObjects(@"YT", [phoneUtil getRegionCodeForNumber:reNumber]);
        
        // This number is valid in both places.
        [reNumber setNationalNumber:@800123456];
        XCTAssertTrue([phoneUtil isValidNumberForRegion:reNumber regionCode:@"YT"]);
        XCTAssertTrue([phoneUtil isValidNumberForRegion:reNumber regionCode:@"RE"]);
        XCTAssertTrue([phoneUtil isValidNumberForRegion:INTERNATIONAL_TOLL_FREE regionCode:@"001"]);
        XCTAssertFalse([phoneUtil isValidNumberForRegion:INTERNATIONAL_TOLL_FREE regionCode:@"US"]);
        XCTAssertFalse([phoneUtil isValidNumberForRegion:INTERNATIONAL_TOLL_FREE regionCode:@"ZZ"]);
        
        NBPhoneNumber *invalidNumber = [[NBPhoneNumber alloc] init];
        // Invalid country calling codes.
        [invalidNumber setCountryCode:@3923];
        [invalidNumber setNationalNumber:@2366];
        XCTAssertFalse([phoneUtil isValidNumberForRegion:invalidNumber regionCode:@"ZZ"]);
        XCTAssertFalse([phoneUtil isValidNumberForRegion:invalidNumber regionCode:@"001"]);
        [invalidNumber setCountryCode:0];
        XCTAssertFalse([phoneUtil isValidNumberForRegion:invalidNumber regionCode:@"001"]);
        XCTAssertFalse([phoneUtil isValidNumberForRegion:invalidNumber regionCode:@"ZZ"]);
    }

    
    #pragma mark - testIsNotValidNumber
    {
        XCTAssertFalse([phoneUtil isValidNumber:US_LOCAL_NUMBER]);
        
        NBPhoneNumber *invalidNumber = [[NBPhoneNumber alloc] init];
        [invalidNumber setCountryCode:@39];
        [invalidNumber setNationalNumber:@23661830000];
        [invalidNumber setItalianLeadingZero:YES];
        XCTAssertFalse([phoneUtil isValidNumber:invalidNumber]);
        
        invalidNumber = [[NBPhoneNumber alloc] init];
        [invalidNumber setCountryCode:@44];
        [invalidNumber setNationalNumber:@791234567];
        XCTAssertFalse([phoneUtil isValidNumber:invalidNumber]);
        
        invalidNumber = [[NBPhoneNumber alloc] init];
        [invalidNumber setCountryCode:@0];
        [invalidNumber setNationalNumber:@1234];
        XCTAssertFalse([phoneUtil isValidNumber:invalidNumber]);
        
        invalidNumber = [[NBPhoneNumber alloc] init];
        [invalidNumber setCountryCode:@64];
        [invalidNumber setNationalNumber:@3316005];
        XCTAssertFalse([phoneUtil isValidNumber:invalidNumber]);
        
        invalidNumber = [[NBPhoneNumber alloc] init];
        // Invalid country calling codes.
        [invalidNumber setCountryCode:@3923];
        [invalidNumber setNationalNumber:@2366];
        XCTAssertFalse([phoneUtil isValidNumber:invalidNumber]);
        [invalidNumber setCountryCode:@0];
        XCTAssertFalse([phoneUtil isValidNumber:invalidNumber]);
        
        XCTAssertFalse([phoneUtil isValidNumber:INTERNATIONAL_TOLL_FREE_TOO_LONG]);
    }
    

    #pragma mark - testgetRegionCodeForCountryCode
    {
        XCTAssertEqualObjects(@"US", [phoneUtil getRegionCodeForCountryCode:@1]);
        XCTAssertEqualObjects(@"GB", [phoneUtil getRegionCodeForCountryCode:@44]);
        XCTAssertEqualObjects(@"DE", [phoneUtil getRegionCodeForCountryCode:@49]);
        XCTAssertEqualObjects(@"001", [phoneUtil getRegionCodeForCountryCode:@800]);
        XCTAssertEqualObjects(@"001", [phoneUtil getRegionCodeForCountryCode:@979]);
    }
    

    #pragma mark - testgetRegionCodeForNumber
    {
        XCTAssertEqualObjects(@"BS", [phoneUtil getRegionCodeForNumber:BS_NUMBER]);
        XCTAssertEqualObjects(@"US", [phoneUtil getRegionCodeForNumber:US_NUMBER]);
        XCTAssertEqualObjects(@"GB", [phoneUtil getRegionCodeForNumber:GB_MOBILE]);
        XCTAssertEqualObjects(@"001", [phoneUtil getRegionCodeForNumber:INTERNATIONAL_TOLL_FREE]);
        XCTAssertEqualObjects(@"001", [phoneUtil getRegionCodeForNumber:UNIVERSAL_PREMIUM_RATE]);
    }
    

    #pragma mark - testGetRegionCodesForCountryCode
    {
        NSArray *regionCodesForNANPA = [phoneUtil getRegionCodesForCountryCode:@1];
        XCTAssertTrue([regionCodesForNANPA containsObject:@"US"]);
        XCTAssertTrue([regionCodesForNANPA containsObject:@"BS"]);
        XCTAssertTrue([[phoneUtil getRegionCodesForCountryCode:@44] containsObject:@"GB"]);
        XCTAssertTrue([[phoneUtil getRegionCodesForCountryCode:@49] containsObject:@"DE"]);
        XCTAssertTrue([[phoneUtil getRegionCodesForCountryCode:@800] containsObject:@"001"]);
        // Test with invalid country calling code.
        XCTAssertTrue([[phoneUtil getRegionCodesForCountryCode:@-1] count] == 0);
    }
    

    #pragma mark - testGetCountryCodeForRegion
    {
        XCTAssertEqualObjects(@1, [phoneUtil getCountryCodeForRegion:@"US"]);
        XCTAssertEqualObjects(@64, [phoneUtil getCountryCodeForRegion:@"NZ"]);
        XCTAssertEqualObjects(@0, [phoneUtil getCountryCodeForRegion:nil]);
        XCTAssertEqualObjects(@0, [phoneUtil getCountryCodeForRegion:@"ZZ"]);
        XCTAssertEqualObjects(@0, [phoneUtil getCountryCodeForRegion:@"001"]);
        // CS is already deprecated so the library doesn't support it.
        XCTAssertEqualObjects(@0, [phoneUtil getCountryCodeForRegion:@"CS"]);
    }
    

    #pragma mark - testGetNationalDiallingPrefixForRegion
    {
        XCTAssertEqualObjects(@"1", [phoneUtil getNddPrefixForRegion:@"US" stripNonDigits:NO]);

        // Test non-main country to see it gets the national dialling prefix for the
        // main country with that country calling code.
        XCTAssertEqualObjects(@"1", [phoneUtil getNddPrefixForRegion:@"BS" stripNonDigits:NO]);
        XCTAssertEqualObjects(@"0", [phoneUtil getNddPrefixForRegion:@"NZ" stripNonDigits:NO]);

        // Test case with non digit in the national prefix.
        XCTAssertEqualObjects(@"0~0", [phoneUtil getNddPrefixForRegion:@"AO" stripNonDigits:NO]);
        XCTAssertEqualObjects(@"00", [phoneUtil getNddPrefixForRegion:@"AO" stripNonDigits:YES]);

        // Test cases with invalid regions.
        XCTAssertNil([phoneUtil getNddPrefixForRegion:nil stripNonDigits:NO]);
        XCTAssertNil([phoneUtil getNddPrefixForRegion:@"ZZ" stripNonDigits:NO]);
        XCTAssertNil([phoneUtil getNddPrefixForRegion:@"001" stripNonDigits:NO]);

        // CS is already deprecated so the library doesn't support it.
        XCTAssertNil([phoneUtil getNddPrefixForRegion:@"CS" stripNonDigits:NO]);
    }


    #pragma mark - testIsNANPACountry
    {
        XCTAssertTrue([phoneUtil isNANPACountry:@"US"]);
        XCTAssertTrue([phoneUtil isNANPACountry:@"BS"]);
        XCTAssertFalse([phoneUtil isNANPACountry:@"DE"]);
        XCTAssertFalse([phoneUtil isNANPACountry:@"ZZ"]);
        XCTAssertFalse([phoneUtil isNANPACountry:@"001"]);
        XCTAssertFalse([phoneUtil isNANPACountry:nil]);
    }

    
    #pragma mark - testIsPossibleNumber
    {
        XCTAssertTrue([phoneUtil isPossibleNumber:US_NUMBER]);
        XCTAssertTrue([phoneUtil isPossibleNumber:US_LOCAL_NUMBER]);
        XCTAssertTrue([phoneUtil isPossibleNumber:GB_NUMBER]);
        XCTAssertTrue([phoneUtil isPossibleNumber:INTERNATIONAL_TOLL_FREE]);
        
        XCTAssertTrue([phoneUtil isPossibleNumberString:@"+1 650 253 0000" regionDialingFrom:@"US" error:nil]);
        XCTAssertTrue([phoneUtil isPossibleNumberString:@"+1 650 GOO OGLE" regionDialingFrom:@"US" error:nil]);
        XCTAssertTrue([phoneUtil isPossibleNumberString:@"(650) 253-0000" regionDialingFrom:@"US" error:nil]);
        XCTAssertTrue([phoneUtil isPossibleNumberString:@"253-0000" regionDialingFrom:@"US" error:nil]);
        XCTAssertTrue([phoneUtil isPossibleNumberString:@"+1 650 253 0000" regionDialingFrom:@"GB" error:nil]);
        XCTAssertTrue([phoneUtil isPossibleNumberString:@"+44 20 7031 3000" regionDialingFrom:@"GB" error:nil]);
        XCTAssertTrue([phoneUtil isPossibleNumberString:@"(020) 7031 3000" regionDialingFrom:@"GB" error:nil]);
        XCTAssertTrue([phoneUtil isPossibleNumberString:@"7031 3000" regionDialingFrom:@"GB" error:nil]);
        XCTAssertTrue([phoneUtil isPossibleNumberString:@"3331 6005" regionDialingFrom:@"NZ" error:nil]);
        XCTAssertTrue([phoneUtil isPossibleNumberString:@"+800 1234 5678" regionDialingFrom:@"001" error:nil]);
    }
    

    #pragma mark - testIsPossibleNumberWithReason
    {
        // National numbers for country calling code +1 that are within 7 to 10 digits
        // are possible.
        XCTAssertEqual(NBEValidationResultIS_POSSIBLE, [phoneUtil isPossibleNumberWithReason:US_NUMBER]);
        XCTAssertEqual(NBEValidationResultIS_POSSIBLE, [phoneUtil isPossibleNumberWithReason:US_LOCAL_NUMBER]);
        XCTAssertEqual(NBEValidationResultTOO_LONG, [phoneUtil isPossibleNumberWithReason:US_LONG_NUMBER]);
        
        NBPhoneNumber *number = [[NBPhoneNumber alloc] init];
        [number setCountryCode:@0];
        [number setNationalNumber:@2530000];
        XCTAssertEqual(NBEValidationResultINVALID_COUNTRY_CODE, [phoneUtil isPossibleNumberWithReason:number]);
        
        number = [[NBPhoneNumber alloc] init];
        [number setCountryCode:@1];
        [number setNationalNumber:@253000];
        XCTAssertEqual(NBEValidationResultTOO_SHORT, [phoneUtil isPossibleNumberWithReason:number]);
        
        number = [[NBPhoneNumber alloc] init];
        [number setCountryCode:@65];
        [number setNationalNumber:@1234567890];
        XCTAssertEqual(NBEValidationResultIS_POSSIBLE, [phoneUtil isPossibleNumberWithReason:number]);
        XCTAssertEqual(NBEValidationResultTOO_LONG, [phoneUtil isPossibleNumberWithReason:INTERNATIONAL_TOLL_FREE_TOO_LONG]);
        
        // Try with number that we don't have metadata for.
        
        NBPhoneNumber *adNumber = [[NBPhoneNumber alloc] init];
        [adNumber setCountryCode:@376];
        [adNumber setNationalNumber:@12345];
        XCTAssertEqual(NBEValidationResultIS_POSSIBLE, [phoneUtil isPossibleNumberWithReason:adNumber]);
        
        [adNumber setCountryCode:@376];
        [adNumber setNationalNumber:@1];
        XCTAssertEqual(NBEValidationResultTOO_SHORT, [phoneUtil isPossibleNumberWithReason:adNumber]);
        
        [adNumber setCountryCode:@376];
        [adNumber setNationalNumber:@12345678901234567];
        XCTAssertEqual(NBEValidationResultTOO_LONG, [phoneUtil isPossibleNumberWithReason:adNumber]);
    }


    #pragma mark - testIsNotPossibleNumber
    {
        XCTAssertFalse([phoneUtil isPossibleNumber:US_LONG_NUMBER]);
        XCTAssertFalse([phoneUtil isPossibleNumber:INTERNATIONAL_TOLL_FREE_TOO_LONG]);
        
        NBPhoneNumber *number = [[NBPhoneNumber alloc] init];
        [number setCountryCode:@1];
        [number setNationalNumber:@253000];
        XCTAssertFalse([phoneUtil isPossibleNumber:number]);
        
        number = [[NBPhoneNumber alloc] init];
        [number setCountryCode:@44];
        [number setNationalNumber:@300];
        XCTAssertFalse([phoneUtil isPossibleNumber:number]);
        XCTAssertFalse([phoneUtil isPossibleNumberString:@"+1 650 253 00000" regionDialingFrom:@"US" error:nil]);
        XCTAssertFalse([phoneUtil isPossibleNumberString:@"(650) 253-00000" regionDialingFrom:@"US" error:nil]);
        XCTAssertFalse([phoneUtil isPossibleNumberString:@"I want a Pizza" regionDialingFrom:@"US" error:nil]);
        XCTAssertFalse([phoneUtil isPossibleNumberString:@"253-000" regionDialingFrom:@"US" error:nil]);
        XCTAssertFalse([phoneUtil isPossibleNumberString:@"1 3000" regionDialingFrom:@"GB" error:nil]);
        XCTAssertFalse([phoneUtil isPossibleNumberString:@"+44 300" regionDialingFrom:@"GB" error:nil]);
        XCTAssertFalse([phoneUtil isPossibleNumberString:@"+800 1234 5678 9" regionDialingFrom:@"001" error:nil]);
    }


    #pragma mark - testTruncateTooLongNumber
    {
        // GB number 080 1234 5678, but entered with 4 extra digits at the end.
        NBPhoneNumber *tooLongNumber = [[NBPhoneNumber alloc] init];
        [tooLongNumber setCountryCode:@44];
        [tooLongNumber setNationalNumber:@80123456780123];
        
        NBPhoneNumber *validNumber = [[NBPhoneNumber alloc] init];
        [validNumber setCountryCode:@44];
        [validNumber setNationalNumber:@8012345678];
        XCTAssertTrue([phoneUtil truncateTooLongNumber:tooLongNumber]);
        XCTAssertTrue([validNumber isEqual:tooLongNumber]);
        
        // IT number 022 3456 7890, but entered with 3 extra digits at the end.
        tooLongNumber = [[NBPhoneNumber alloc] init];
        [tooLongNumber setCountryCode:@39];
        [tooLongNumber setNationalNumber:@2234567890123];
        [tooLongNumber setItalianLeadingZero:YES];
                                             
        validNumber = [[NBPhoneNumber alloc] init];
        [validNumber setCountryCode:@39];
        [validNumber setNationalNumber:@2234567890];
        [validNumber setItalianLeadingZero:YES];
        XCTAssertTrue([phoneUtil truncateTooLongNumber:tooLongNumber]);
        XCTAssertTrue([validNumber isEqual:tooLongNumber]);
        
        // US number 650-253-0000, but entered with one additional digit at the end.
        tooLongNumber = [US_LONG_NUMBER copy];
        XCTAssertTrue([phoneUtil truncateTooLongNumber:tooLongNumber]);
        XCTAssertTrue([US_NUMBER isEqual:tooLongNumber]);
        
        tooLongNumber = [INTERNATIONAL_TOLL_FREE_TOO_LONG copy];
        XCTAssertTrue([phoneUtil truncateTooLongNumber:tooLongNumber]);
        XCTAssertTrue([INTERNATIONAL_TOLL_FREE isEqual:tooLongNumber]);
        
        // Tests what happens when a valid number is passed in.
        
        NBPhoneNumber *validNumberCopy = [validNumber copy];
        XCTAssertTrue([phoneUtil truncateTooLongNumber:validNumber]);
        // Tests the number is not modified.
        XCTAssertTrue([validNumber isEqual:validNumberCopy]);
        
        // Tests what happens when a number with invalid prefix is passed in.
        
        NBPhoneNumber *numberWithInvalidPrefix = [[NBPhoneNumber alloc] init];
        // The test metadata says US numbers cannot have prefix 240.
        [numberWithInvalidPrefix setCountryCode:@1];
        [numberWithInvalidPrefix setNationalNumber:@2401234567];
        
        NBPhoneNumber *invalidNumberCopy = [numberWithInvalidPrefix copy];
        XCTAssertFalse([phoneUtil truncateTooLongNumber:numberWithInvalidPrefix]);
        // Tests the number is not modified.
        XCTAssertTrue([numberWithInvalidPrefix isEqual:invalidNumberCopy]);
        
        // Tests what happens when a too short number is passed in.
        
        NBPhoneNumber *tooShortNumber = [[NBPhoneNumber alloc] init];
        [tooShortNumber setCountryCode:@1];
        [tooShortNumber setNationalNumber:@1234];
        
        NBPhoneNumber *tooShortNumberCopy = [tooShortNumber copy];
        XCTAssertFalse([phoneUtil truncateTooLongNumber:tooShortNumber]);
        // Tests the number is not modified.
        XCTAssertTrue([tooShortNumber isEqual:tooShortNumberCopy]);
    }
    

    #pragma mark - testIsViablePhoneNumber
    {
        NSLog(@"-------------- testIsViablePhoneNumber");
        XCTAssertFalse([phoneUtil isViablePhoneNumber:@"1"]);
        // Only one or two digits before strange non-possible punctuation.
        XCTAssertFalse([phoneUtil isViablePhoneNumber:@"1+1+1"]);
        XCTAssertFalse([phoneUtil isViablePhoneNumber:@"80+0"]);
        // Two digits is viable.
        XCTAssertTrue([phoneUtil isViablePhoneNumber:@"00"]);
        XCTAssertTrue([phoneUtil isViablePhoneNumber:@"111"]);
        // Alpha numbers.
        XCTAssertTrue([phoneUtil isViablePhoneNumber:@"0800-4-pizza"]);
        XCTAssertTrue([phoneUtil isViablePhoneNumber:@"0800-4-PIZZA"]);
        // We need at least three digits before any alpha characters.
        XCTAssertFalse([phoneUtil isViablePhoneNumber:@"08-PIZZA"]);
        XCTAssertFalse([phoneUtil isViablePhoneNumber:@"8-PIZZA"]);
        XCTAssertFalse([phoneUtil isViablePhoneNumber:@"12. March"]);
    }


    #pragma mark - testIsViablePhoneNumberNonAscii
    {
        NSLog(@"-------------- testIsViablePhoneNumberNonAscii");
        // Only one or two digits before possible punctuation followed by more digits.
        XCTAssertTrue([phoneUtil isViablePhoneNumber:@"1\u300034"]);
        XCTAssertFalse([phoneUtil isViablePhoneNumber:@"1\u30003+4"]);
        // Unicode variants of possible starting character and other allowed
        // punctuation/digits.
        XCTAssertTrue([phoneUtil isViablePhoneNumber:@"\uFF081\uFF09\u30003456789"]);
        // Testing a leading + is okay.
        XCTAssertTrue([phoneUtil isViablePhoneNumber:@"+1\uFF09\u30003456789"]);
    }


    #pragma mark - testExtractPossibleNumber
    {
        NSLog(@"-------------- testExtractPossibleNumber");
        // Removes preceding funky punctuation and letters but leaves the rest
        // untouched.
        XCTAssertEqualObjects(@"0800-345-600", [phoneUtil extractPossibleNumber:@"Tel:0800-345-600"]);
        XCTAssertEqualObjects(@"0800 FOR PIZZA", [phoneUtil extractPossibleNumber:@"Tel:0800 FOR PIZZA"]);
        // Should not remove plus sign
        XCTAssertEqualObjects(@"+800-345-600", [phoneUtil extractPossibleNumber:@"Tel:+800-345-600"]);
        // Should recognise wide digits as possible start values.
        XCTAssertEqualObjects(@"\uFF10\uFF12\uFF13", [phoneUtil extractPossibleNumber:@"\uFF10\uFF12\uFF13"]);
        // Dashes are not possible start values and should be removed.
        XCTAssertEqualObjects(@"\uFF11\uFF12\uFF13", [phoneUtil extractPossibleNumber:@"Num-\uFF11\uFF12\uFF13"]);
        // If not possible number present, return empty string.
        XCTAssertEqualObjects(@"", [phoneUtil extractPossibleNumber:@"Num-...."]);
        // Leading brackets are stripped - these are not used when parsing.
        XCTAssertEqualObjects(@"650) 253-0000", [phoneUtil extractPossibleNumber:@"(650) 253-0000"]);
        
        // Trailing non-alpha-numeric characters should be removed.
        XCTAssertEqualObjects(@"650) 253-0000", [phoneUtil extractPossibleNumber:@"(650) 253-0000..- .."]);
        XCTAssertEqualObjects(@"650) 253-0000", [phoneUtil extractPossibleNumber:@"(650) 253-0000."]);
        // This case has a trailing RTL char.
        XCTAssertEqualObjects(@"650) 253-0000", [phoneUtil extractPossibleNumber:@"(650) 253-0000\u200F"]);
    }

    
    #pragma mark - testMaybeStripNationalPrefix
    {
        NSLog(@"-------------- testMaybeStripNationalPrefix");
        NBPhoneMetaData *metadata = [[NBPhoneMetaData alloc] init];
        [metadata setNationalPrefixForParsing:@"34"];
        
        NBPhoneNumberDesc *generalDesc = [[NBPhoneNumberDesc alloc] init];
        [generalDesc setNationalNumberPattern:@"\\d{4,8}"];
        [metadata setGeneralDesc:generalDesc];
        
        NBPhoneNumber *numberToStrip = [[NBPhoneNumber alloc] init];
        [numberToStrip setRawInput:@"34356778"];
        
        NSString *strippedNumber = @"356778";
        NSString *rawInput = numberToStrip.rawInput;
        XCTAssertTrue([phoneUtil maybeStripNationalPrefixAndCarrierCode:&rawInput metadata:metadata carrierCode:nil]);
        XCTAssertEqualObjects(strippedNumber, rawInput, @"Should have had national prefix stripped.");
        
        // Retry stripping - now the number should not start with the national prefix,
        // so no more stripping should occur.
        XCTAssertFalse([phoneUtil maybeStripNationalPrefixAndCarrierCode:&rawInput metadata:metadata carrierCode:nil]);
        XCTAssertEqualObjects(strippedNumber, rawInput, @"Should have had no change - no national prefix present.");
                             
        // Some countries have no national prefix. Repeat test with none specified.
        [metadata setNationalPrefixForParsing:@""];
        XCTAssertFalse([phoneUtil maybeStripNationalPrefixAndCarrierCode:&rawInput metadata:metadata carrierCode:nil]);
        XCTAssertEqualObjects(strippedNumber, rawInput, @"Should not strip anything with empty national prefix.");

        // If the resultant number doesn't match the national rule, it shouldn't be
        // stripped.
        [metadata setNationalPrefixForParsing:@"3"];
        numberToStrip.rawInput = @"3123";
        rawInput = numberToStrip.rawInput;
        strippedNumber = @"3123";
        XCTAssertFalse([phoneUtil maybeStripNationalPrefixAndCarrierCode:&rawInput metadata:metadata carrierCode:nil]);
        XCTAssertEqualObjects(strippedNumber, rawInput, @"Should have had no change - after stripping, it would not have matched the national rule.");
        
        // Test extracting carrier selection code.
        [metadata setNationalPrefixForParsing:@"0(81)?"];
        numberToStrip.rawInput = @"08122123456";
        strippedNumber = @"22123456";
        rawInput = numberToStrip.rawInput;
        NSString *carrierCode = @"";
        XCTAssertTrue([phoneUtil maybeStripNationalPrefixAndCarrierCode:&rawInput metadata:metadata carrierCode:&carrierCode]);
        XCTAssertEqualObjects(@"81", carrierCode);
        XCTAssertEqualObjects(strippedNumber, rawInput, @"Should have had national prefix and carrier code stripped.");
        
        // If there was a transform rule, check it was applied.
        [metadata setNationalPrefixTransformRule:@"5$15"];
        // Note that a capturing group is present here.
        [metadata setNationalPrefixForParsing:@"0(\\d{2})"];
        numberToStrip.rawInput = @"031123";
        rawInput = numberToStrip.rawInput;
        NSString *transformedNumber = @"5315123";
        XCTAssertTrue([phoneUtil maybeStripNationalPrefixAndCarrierCode:&rawInput metadata:metadata carrierCode:nil]);
        XCTAssertEqualObjects(transformedNumber, rawInput, @"Should transform the 031 to a 5315.");
    }


    #pragma mark - testMaybeStripInternationalPrefix
    {
        NSLog(@"-------------- testMaybeStripInternationalPrefix");
        NSString *internationalPrefix = @"00[39]";
        
        NSString *numberToStripPrefix = @"0034567700-3898003";
        
        // Note the dash is removed as part of the normalization.
        NSString *strippedNumberString = @"45677003898003";
        XCTAssertEqual(NBECountryCodeSourceFROM_NUMBER_WITH_IDD, [phoneUtil maybeStripInternationalPrefixAndNormalize:&numberToStripPrefix
                                                                                possibleIddPrefix:internationalPrefix]);
        XCTAssertEqualObjects(strippedNumberString, numberToStripPrefix, @"The number supplied was not stripped of its international prefix.");
        // Now the number no longer starts with an IDD prefix, so it should now report
        // FROM_DEFAULT_COUNTRY.
        XCTAssertEqual(NBECountryCodeSourceFROM_DEFAULT_COUNTRY, [phoneUtil maybeStripInternationalPrefixAndNormalize:&numberToStripPrefix
                                                                                      possibleIddPrefix:internationalPrefix]);
        
        numberToStripPrefix = @"00945677003898003";
        XCTAssertEqual(NBECountryCodeSourceFROM_NUMBER_WITH_IDD, [phoneUtil maybeStripInternationalPrefixAndNormalize:&numberToStripPrefix
                                                                                possibleIddPrefix:internationalPrefix]);
        XCTAssertEqualObjects(strippedNumberString, numberToStripPrefix, @"The number supplied was not stripped of its international prefix.");
        // Test it works when the international prefix is broken up by spaces.
        numberToStripPrefix = @"00 9 45677003898003";
        XCTAssertEqual(NBECountryCodeSourceFROM_NUMBER_WITH_IDD, [phoneUtil maybeStripInternationalPrefixAndNormalize:&numberToStripPrefix
                                                                                possibleIddPrefix:internationalPrefix]);
        XCTAssertEqualObjects(strippedNumberString, numberToStripPrefix, @"The number supplied was not stripped of its international prefix.");
        // Now the number no longer starts with an IDD prefix, so it should now report
        // FROM_DEFAULT_COUNTRY.
        XCTAssertEqual(NBECountryCodeSourceFROM_DEFAULT_COUNTRY, [phoneUtil maybeStripInternationalPrefixAndNormalize:&numberToStripPrefix
                                                                                possibleIddPrefix:internationalPrefix]);
        
        // Test the + symbol is also recognised and stripped.
        numberToStripPrefix = @"+45677003898003";
        strippedNumberString = @"45677003898003";
        XCTAssertEqual(NBECountryCodeSourceFROM_NUMBER_WITH_PLUS_SIGN, [phoneUtil maybeStripInternationalPrefixAndNormalize:&numberToStripPrefix
                                                                                      possibleIddPrefix:internationalPrefix]);
        XCTAssertEqualObjects(strippedNumberString, numberToStripPrefix, @"The number supplied was not stripped of the plus symbol.");
        
        // If the number afterwards is a zero, we should not strip this - no country
        // calling code begins with 0.
        numberToStripPrefix = @"0090112-3123";
        strippedNumberString = @"00901123123";
        XCTAssertEqual(NBECountryCodeSourceFROM_DEFAULT_COUNTRY, [phoneUtil maybeStripInternationalPrefixAndNormalize:&numberToStripPrefix
                                                                                possibleIddPrefix:internationalPrefix]);
        XCTAssertEqualObjects(strippedNumberString, numberToStripPrefix, @"The number supplied had a 0 after the match so should not be stripped.");
        // Here the 0 is separated by a space from the IDD.
        numberToStripPrefix = @"009 0-112-3123";
        XCTAssertEqual(NBECountryCodeSourceFROM_DEFAULT_COUNTRY, [phoneUtil maybeStripInternationalPrefixAndNormalize:&numberToStripPrefix
                                                                                possibleIddPrefix:internationalPrefix]);
    }

    #pragma mark - testMaybeExtractCountryCode
    {
        NSLog(@"-------------- testMaybeExtractCountryCode");
        NBPhoneNumber *number = [[NBPhoneNumber alloc] init];
        NBPhoneMetaData *metadata = [phoneUtil getMetadataForRegion:@"US"];
        
        // Note that for the US, the IDD is 011.
        NSString *phoneNumber = @"011112-3456789";
        NSString *strippedNumber = @"123456789";
        NSNumber *countryCallingCode = @1;
        
        NSString *numberToFill = @"";

        {
            NSError *aError = nil;
            XCTAssertEqualObjects(countryCallingCode, [phoneUtil maybeExtractCountryCode:phoneNumber metadata:metadata
                                                                   nationalNumber:&numberToFill keepRawInput:YES phoneNumber:&number error:&aError]);
            XCTAssertEqual(NBECountryCodeSourceFROM_NUMBER_WITH_IDD, [number.countryCodeSource intValue]);
            // Should strip and normalize national significant number.
            XCTAssertEqualObjects(strippedNumber, numberToFill);
            if (aError)
                XCTFail(@"Should not have thrown an exception: %@", aError.description);
        }
        XCTAssertEqual(NBECountryCodeSourceFROM_NUMBER_WITH_IDD, [number.countryCodeSource intValue], @"Did not figure out CountryCodeSource correctly");
        // Should strip and normalize national significant number.
        XCTAssertEqualObjects(strippedNumber, numberToFill, @"Did not strip off the country calling code correctly.");
        
        number = [[NBPhoneNumber alloc] init];
        phoneNumber = @"+6423456789";
        countryCallingCode = @64;
        numberToFill = @"";
        XCTAssertEqualObjects(countryCallingCode, [phoneUtil maybeExtractCountryCode:phoneNumber metadata:metadata
                                                                     nationalNumber:&numberToFill keepRawInput:YES phoneNumber:&number error:nil]);
        XCTAssertEqual(NBECountryCodeSourceFROM_NUMBER_WITH_PLUS_SIGN, [number.countryCodeSource intValue], @"Did not figure out CountryCodeSource correctly");
        
        number = [[NBPhoneNumber alloc] init];
        phoneNumber = @"+80012345678";
        countryCallingCode = @800;
        numberToFill = @"";
        XCTAssertEqualObjects(countryCallingCode, [phoneUtil maybeExtractCountryCode:phoneNumber metadata:metadata
                                                 nationalNumber:&numberToFill keepRawInput:YES phoneNumber:&number error:nil]);
        XCTAssertEqual(NBECountryCodeSourceFROM_NUMBER_WITH_PLUS_SIGN, [number.countryCodeSource intValue], @"Did not figure out CountryCodeSource correctly");
        
        number = [[NBPhoneNumber alloc] init];
        phoneNumber = @"2345-6789";
        numberToFill = @"";
        XCTAssertEqual(@0, [phoneUtil maybeExtractCountryCode:phoneNumber metadata:metadata
                                               nationalNumber:&numberToFill keepRawInput:YES phoneNumber:&number error:nil]);
        XCTAssertEqual(NBECountryCodeSourceFROM_DEFAULT_COUNTRY, [number.countryCodeSource intValue], @"Did not figure out CountryCodeSource correctly");

                                 
        number = [[NBPhoneNumber alloc] init];
        phoneNumber = @"0119991123456789";
        numberToFill = @"";
        {
            NSError *aError = nil;
            [phoneUtil maybeExtractCountryCode:phoneNumber metadata:metadata
                                nationalNumber:&numberToFill keepRawInput:YES phoneNumber:&number error:&aError];
            if (aError == nil)
                XCTFail(@"Should have thrown an exception, no valid country calling code present.");
            else // Expected.
                XCTAssertEqualObjects(@"INVALID_COUNTRY_CODE", aError.domain);
        }
        
        number = [[NBPhoneNumber alloc] init];
        phoneNumber = @"(1 610) 619 4466";
        countryCallingCode = @1;
        numberToFill = @"";
        {
            NSError *aError = nil;
            XCTAssertEqualObjects(countryCallingCode, [phoneUtil maybeExtractCountryCode:phoneNumber metadata:metadata
                                                                   nationalNumber:&numberToFill keepRawInput:YES phoneNumber:&number error:&aError],
                                 @"Should have extracted the country calling code of the region passed in");
            XCTAssertEqual(NBECountryCodeSourceFROM_NUMBER_WITHOUT_PLUS_SIGN, [number.countryCodeSource intValue], @"Did not figure out CountryCodeSource correctly");
        }
        
        number = [[NBPhoneNumber alloc] init];
        phoneNumber = @"(1 610) 619 4466";
        countryCallingCode = @1;
        numberToFill = @"";
        {
            NSError *aError = nil;
            XCTAssertEqualObjects(countryCallingCode, [phoneUtil maybeExtractCountryCode:phoneNumber metadata:metadata
                                                                   nationalNumber:&numberToFill keepRawInput:NO phoneNumber:&number error:&aError]);
        }
                
        number = [[NBPhoneNumber alloc] init];
        phoneNumber = @"(1 610) 619 446";
        numberToFill = @"";
        {
            NSError *aError = nil;
            XCTAssertEqualObjects(@0, [phoneUtil maybeExtractCountryCode:phoneNumber metadata:metadata
                                                          nationalNumber:&numberToFill keepRawInput:NO phoneNumber:&number error:&aError]);
            XCTAssertFalse(number.countryCodeSource != nil, @"Should not contain CountryCodeSource.");
        }
        
        number = [[NBPhoneNumber alloc] init];
        phoneNumber = @"(1 610) 619";
        numberToFill = @"";
        {
            NSError *aError = nil;
            XCTAssertEqual(@0, [phoneUtil maybeExtractCountryCode:phoneNumber metadata:metadata
                                                          nationalNumber:&numberToFill keepRawInput:YES phoneNumber:&number error:&aError]);
            XCTAssertEqual(NBECountryCodeSourceFROM_DEFAULT_COUNTRY, [number.countryCodeSource intValue]);
        }
    }


    #pragma mark - testParseNationalNumber
    {
        NSError *aError;
        NSLog(@"-------------- testParseNationalNumber");
        // National prefix attached.
        XCTAssertTrue([NZ_NUMBER isEqual:[phoneUtil parse:@"033316005" defaultRegion:@"NZ" error:&aError]]);
        XCTAssertTrue([NZ_NUMBER isEqual:[phoneUtil parse:@"33316005" defaultRegion:@"NZ" error:&aError]]);
        
        // National prefix attached and some formatting present.
        XCTAssertTrue([NZ_NUMBER isEqual:[phoneUtil parse:@"03-331 6005" defaultRegion:@"NZ" error:&aError]]);
        XCTAssertTrue([NZ_NUMBER isEqual:[phoneUtil parse:@"03 331 6005" defaultRegion:@"NZ" error:&aError]]);
        
        // Test parsing RFC3966 format with a phone context.
        XCTAssertTrue([NZ_NUMBER isEqual:[phoneUtil parse:@"tel:03-331-6005;phone-context=+64" defaultRegion:@"NZ" error:&aError]]);
        XCTAssertTrue([NZ_NUMBER isEqual:[phoneUtil parse:@"tel:331-6005;phone-context=+64-3" defaultRegion:@"NZ" error:&aError]]);
        XCTAssertTrue([NZ_NUMBER isEqual:[phoneUtil parse:@"tel:331-6005;phone-context=+64-3" defaultRegion:@"US" error:&aError]]);
                      
        // Test parsing RFC3966 format with optional user-defined parameters. The
        // parameters will appear after the context if present.
        XCTAssertTrue([NZ_NUMBER isEqual:[phoneUtil parse:@"tel:03-331-6005;phone-context=+64;a=%A1" defaultRegion:@"NZ" error:&aError]]);
        
        // Test parsing RFC3966 with an ISDN subaddress.
        XCTAssertTrue([NZ_NUMBER isEqual:[phoneUtil parse:@"tel:03-331-6005;isub=12345;phone-context=+64" defaultRegion:@"NZ" error:&aError]]);
        XCTAssertTrue([NZ_NUMBER isEqual:[phoneUtil parse:@"tel:+64-3-331-6005;isub=12345" defaultRegion:@"NZ" error:&aError]]);

        // Testing international prefixes.
        // Should strip country calling code.
        XCTAssertTrue([NZ_NUMBER isEqual:[phoneUtil parse:@"0064 3 331 6005" defaultRegion:@"NZ" error:&aError]]);

        // Try again, but this time we have an international number with Region Code
        // US. It should recognise the country calling code and parse accordingly.
        XCTAssertTrue([NZ_NUMBER isEqual:[phoneUtil parse:@"01164 3 331 6005" defaultRegion:@"US" error:&aError]]);
        XCTAssertTrue([NZ_NUMBER isEqual:[phoneUtil parse:@"+64 3 331 6005" defaultRegion:@"US" error:&aError]]);
        // We should ignore the leading plus here, since it is not followed by a valid
        // country code but instead is followed by the IDD for the US.
        XCTAssertTrue([NZ_NUMBER isEqual:[phoneUtil parse:@"+01164 3 331 6005" defaultRegion:@"US" error:&aError]]);
        XCTAssertTrue([NZ_NUMBER isEqual:[phoneUtil parse:@"+0064 3 331 6005" defaultRegion:@"NZ" error:&aError]]);
        XCTAssertTrue([NZ_NUMBER isEqual:[phoneUtil parse:@"+ 00 64 3 331 6005" defaultRegion:@"NZ" error:&aError]]);
        
        XCTAssertTrue([US_LOCAL_NUMBER isEqual:[phoneUtil parse:@"tel:253-0000;phone-context=www.google.com" defaultRegion:@"US" error:&aError]]);
        XCTAssertTrue([US_LOCAL_NUMBER isEqual:[phoneUtil parse:@"tel:253-0000;isub=12345;phone-context=www.google.com" defaultRegion:@"US" error:&aError]]);
        // This is invalid because no "+" sign is present as part of phone-context.
        // The phone context is simply ignored in this case just as if it contains a
        // domain.
        XCTAssertTrue([US_LOCAL_NUMBER isEqual:[phoneUtil parse:@"tel:2530000;isub=12345;phone-context=1-650" defaultRegion:@"US" error:&aError]]);
        XCTAssertTrue([US_LOCAL_NUMBER isEqual:[phoneUtil parse:@"tel:2530000;isub=12345;phone-context=1234.com" defaultRegion:@"US" error:&aError]]);
        
        NBPhoneNumber *nzNumber = [[NBPhoneNumber alloc] init];
        [nzNumber setCountryCode:@64];
        [nzNumber setNationalNumber:@64123456];
        XCTAssertTrue([nzNumber isEqual:[phoneUtil parse:@"64(0)64123456" defaultRegion:@"NZ" error:&aError]]);
        // Check that using a '/' is fine in a phone number.
        XCTAssertTrue([DE_NUMBER isEqual:[phoneUtil parse:@"301/23456" defaultRegion:@"DE" error:&aError]]);
        
        NBPhoneNumber *usNumber = [[NBPhoneNumber alloc] init];
        // Check it doesn't use the '1' as a country calling code when parsing if the
        // phone number was already possible.
        [usNumber setCountryCode:@1];
        [usNumber setNationalNumber:@1234567890];
        XCTAssertTrue([usNumber isEqual:[phoneUtil parse:@"123-456-7890" defaultRegion:@"US" error:&aError]]);
        
        // Test star numbers. Although this is not strictly valid, we would like to
        // make sure we can parse the output we produce when formatting the number.
        XCTAssertTrue([JP_STAR_NUMBER isEqual:[phoneUtil parse:@"+81 *2345" defaultRegion:@"JP" error:&aError]]);
        
        NBPhoneNumber *shortNumber = [[NBPhoneNumber alloc] init];
        [shortNumber setCountryCode:@64];
        [shortNumber setNationalNumber:@12];
        XCTAssertTrue([shortNumber isEqual:[phoneUtil parse:@"12" defaultRegion:@"NZ" error:&aError]]);
    }


    #pragma mark - testParseNumberWithAlphaCharacters
    {
        NSError *aError;
        NSLog(@"-------------- testParseNumberWithAlphaCharacters");
        // Test case with alpha characters.
        NBPhoneNumber *tollfreeNumber = [[NBPhoneNumber alloc] init];
        [tollfreeNumber setCountryCode:@64];
        [tollfreeNumber setNationalNumber:@800332005];
        XCTAssertTrue([tollfreeNumber isEqual:[phoneUtil parse:@"0800 DDA 005" defaultRegion:@"NZ" error:&aError]]);
        
        NBPhoneNumber *premiumNumber = [[NBPhoneNumber alloc] init];
        [premiumNumber setCountryCode:@64];
        [premiumNumber setNationalNumber:@9003326005];
        XCTAssertTrue([premiumNumber isEqual:[phoneUtil parse:@"0900 DDA 6005" defaultRegion:@"NZ" error:&aError]]);
        // Not enough alpha characters for them to be considered intentional, so they
        // are stripped.
        XCTAssertTrue([premiumNumber isEqual:[phoneUtil parse:@"0900 332 6005a" defaultRegion:@"NZ" error:&aError]]);
        XCTAssertTrue([premiumNumber isEqual:[phoneUtil parse:@"0900 332 600a5" defaultRegion:@"NZ" error:&aError]]);
        XCTAssertTrue([premiumNumber isEqual:[phoneUtil parse:@"0900 332 600A5" defaultRegion:@"NZ" error:&aError]]);
        XCTAssertTrue([premiumNumber isEqual:[phoneUtil parse:@"0900 a332 600A5" defaultRegion:@"NZ" error:&aError]]);
    }
    
        
    #pragma mark - testParseMaliciousInput
    {
        NSLog(@"-------------- testParseMaliciousInput");
        // Lots of leading + signs before the possible number.
        
        NSString *maliciousNumber = @"";
        for (int i=0; i<6000; i++)
        {
            maliciousNumber = [maliciousNumber stringByAppendingString:@"+"];
        }
        
        maliciousNumber = [maliciousNumber stringByAppendingString:@"12222-33-244 extensioB 343+"];
        {
            NSError *aError = nil;
            [phoneUtil parse:maliciousNumber defaultRegion:@"US" error:&aError];
            if (aError == nil) {
                XCTFail(@"This should not parse without throwing an exception %@", maliciousNumber);
            } else {
                XCTAssertEqualObjects(@"TOO_LONG", aError.domain, @"Wrong error type stored in exception.");
            }
        }

        NSString *maliciousNumberWithAlmostExt = @"";
        for (int i=0; i<350; i++)
        {
            maliciousNumberWithAlmostExt = [maliciousNumberWithAlmostExt stringByAppendingString:@"200"];
        }

        [maliciousNumberWithAlmostExt stringByAppendingString:@" extensiOB 345"];
        
        {
            NSError *aError = nil;
            [phoneUtil parse:maliciousNumberWithAlmostExt defaultRegion:@"US" error:&aError];
            if (aError == nil) {
                XCTFail(@"This should not parse without throwing an exception %@", maliciousNumberWithAlmostExt);
            } else {
                XCTAssertEqualObjects(@"TOO_LONG", aError.domain, @"Wrong error type stored in exception.");
            }
        }
    }


    #pragma mark - testParseWithInternationalPrefixes
    {
        NSError *aError = nil;
        NSLog(@"-------------- testParseWithInternationalPrefixes");
        XCTAssertTrue([US_NUMBER isEqual:[phoneUtil parse:@"+1 (650) 253-0000" defaultRegion:@"NZ" error:&aError]]);
        XCTAssertTrue([INTERNATIONAL_TOLL_FREE isEqual:[phoneUtil parse:@"011 800 1234 5678" defaultRegion:@"US" error:&aError]]);
        XCTAssertTrue([US_NUMBER isEqual:[phoneUtil parse:@"1-650-253-0000" defaultRegion:@"US" error:&aError]]);
        // Calling the US number from Singapore by using different service providers
        // 1st test: calling using SingTel IDD service (IDD is 001)
        XCTAssertTrue([US_NUMBER isEqual:[phoneUtil parse:@"0011-650-253-0000" defaultRegion:@"SG" error:&aError]]);
        // 2nd test: calling using StarHub IDD service (IDD is 008)
        XCTAssertTrue([US_NUMBER isEqual:[phoneUtil parse:@"0081-650-253-0000" defaultRegion:@"SG" error:&aError]]);
        // 3rd test: calling using SingTel V019 service (IDD is 019)
        XCTAssertTrue([US_NUMBER isEqual:[phoneUtil parse:@"0191-650-253-0000" defaultRegion:@"SG" error:&aError]]);
        // Calling the US number from Poland
        XCTAssertTrue([US_NUMBER isEqual:[phoneUtil parse:@"0~01-650-253-0000" defaultRegion:@"PL" error:&aError]]);
        // Using '++' at the start.
        XCTAssertTrue([US_NUMBER isEqual:[phoneUtil parse:@"++1 (650) 253-0000" defaultRegion:@"PL" error:&aError]]);
    }

    
    #pragma mark - testParseNonAscii
    {
        NSError *aError = nil;
        NSLog(@"-------------- testParseNonAscii");
        // Using a full-width plus sign.
        XCTAssertTrue([US_NUMBER isEqual:[phoneUtil parse:@"\uFF0B1 (650) 253-0000" defaultRegion:@"SG" error:&aError]]);
        // Using a soft hyphen U+00AD.
        XCTAssertTrue([US_NUMBER isEqual:[phoneUtil parse:@"1 (650) 253\u00AD-0000" defaultRegion:@"US" error:&aError]]);
        // The whole number, including punctuation, is here represented in full-width
        // form.
        XCTAssertTrue([US_NUMBER isEqual:[phoneUtil parse:@"\uFF0B\uFF11\u3000\uFF08\uFF16\uFF15\uFF10\uFF09\u3000\uFF12\uFF15\uFF13\uFF0D\uFF10\uFF10\uFF10\uFF10" defaultRegion:@"SG" error:&aError]]);
        // Using U+30FC dash instead.
        XCTAssertTrue([US_NUMBER isEqual:[phoneUtil parse:@"\uFF0B\uFF11\u3000\uFF08\uFF16\uFF15\uFF10\uFF09\u3000\uFF12\uFF15\uFF13\u30FC\uFF10\uFF10\uFF10\uFF10" defaultRegion:@"SG" error:&aError]]);
        
        // Using a very strange decimal digit range (Mongolian digits).
        // TODO(user): Support Mongolian digits
        // STAssertTrue(US_NUMBER isEqual:
        //     [phoneUtil parse:@"\u1811 \u1816\u1815\u1810 " +
        //                     '\u1812\u1815\u1813 \u1810\u1810\u1810\u1810" defaultRegion:@"US"], nil);
    }

    
    #pragma mark - testParseWithLeadingZero
    {
        NSError *aError = nil;
        NSLog(@"-------------- testParseWithLeadingZero");
        XCTAssertTrue([IT_NUMBER isEqual:[phoneUtil parse:@"+39 02-36618 300" defaultRegion:@"NZ" error:&aError]]);
        XCTAssertTrue([IT_NUMBER isEqual:[phoneUtil parse:@"02-36618 300" defaultRegion:@"IT" error:&aError]]);
        XCTAssertTrue([IT_MOBILE isEqual:[phoneUtil parse:@"345 678 901" defaultRegion:@"IT" error:&aError]]);
    }

    
    #pragma mark - testParseNationalNumberArgentina
    {
        NSError *aError = nil;
        NSLog(@"-------------- testParseNationalNumberArgentina");
        // Test parsing mobile numbers of Argentina.
        NBPhoneNumber *arNumber = [[NBPhoneNumber alloc] init];
        [arNumber setCountryCode:@54];
        [arNumber setNationalNumber:@93435551212];
        XCTAssertTrue([arNumber isEqual:[phoneUtil parse:@"+54 9 343 555 1212" defaultRegion:@"AR" error:&aError]]);
        XCTAssertTrue([arNumber isEqual:[phoneUtil parse:@"0343 15 555 1212" defaultRegion:@"AR" error:&aError]]);
        
        arNumber = [[NBPhoneNumber alloc] init];
        [arNumber setCountryCode:@54];
        [arNumber setNationalNumber:@93715654320];
        XCTAssertTrue([arNumber isEqual:[phoneUtil parse:@"+54 9 3715 65 4320" defaultRegion:@"AR" error:&aError]]);
        XCTAssertTrue([arNumber isEqual:[phoneUtil parse:@"03715 15 65 4320" defaultRegion:@"AR" error:&aError]]);
        XCTAssertTrue([AR_MOBILE isEqual:[phoneUtil parse:@"911 876 54321" defaultRegion:@"AR" error:&aError]]);
        
        // Test parsing fixed-line numbers of Argentina.
        XCTAssertTrue([AR_NUMBER isEqual:[phoneUtil parse:@"+54 11 8765 4321" defaultRegion:@"AR" error:&aError]]);
        XCTAssertTrue([AR_NUMBER isEqual:[phoneUtil parse:@"011 8765 4321" defaultRegion:@"AR" error:&aError]]);
        
        arNumber = [[NBPhoneNumber alloc] init];
        [arNumber setCountryCode:@54];
        [arNumber setNationalNumber:@3715654321];
        XCTAssertTrue([arNumber isEqual:[phoneUtil parse:@"+54 3715 65 4321" defaultRegion:@"AR" error:&aError]]);
        XCTAssertTrue([arNumber isEqual:[phoneUtil parse:@"03715 65 4321" defaultRegion:@"AR" error:&aError]]);
        
        arNumber = [[NBPhoneNumber alloc] init];
        [arNumber setCountryCode:@54];
        [arNumber setNationalNumber:@2312340000];
        XCTAssertTrue([arNumber isEqual:[phoneUtil parse:@"+54 23 1234 0000" defaultRegion:@"AR" error:&aError]]);
        XCTAssertTrue([arNumber isEqual:[phoneUtil parse:@"023 1234 0000" defaultRegion:@"AR" error:&aError]]);
    }

    
    #pragma mark - testParseWithXInNumber
    {
        NSError *aError = nil;
        NSLog(@"-------------- testParseWithXInNumber");
        // Test that having an 'x' in the phone number at the start is ok and that it
        // just gets removed.
        XCTAssertTrue([AR_NUMBER isEqual:[phoneUtil parse:@"01187654321" defaultRegion:@"AR" error:&aError]]);
        XCTAssertTrue([AR_NUMBER isEqual:[phoneUtil parse:@"(0) 1187654321" defaultRegion:@"AR" error:&aError]]);
        XCTAssertTrue([AR_NUMBER isEqual:[phoneUtil parse:@"0 1187654321" defaultRegion:@"AR" error:&aError]]);
        XCTAssertTrue([AR_NUMBER isEqual:[phoneUtil parse:@"(0xx) 1187654321" defaultRegion:@"AR" error:&aError]]);
        
        id arFromUs = [[NBPhoneNumber alloc] init];
        [arFromUs setCountryCode:@54];
        [arFromUs setNationalNumber:@81429712];
        // This test is intentionally constructed such that the number of digit after
        // xx is larger than 7, so that the number won't be mistakenly treated as an
        // extension, as we allow extensions up to 7 digits. This assumption is okay
        // for now as all the countries where a carrier selection code is written in
        // the form of xx have a national significant number of length larger than 7.
        XCTAssertTrue([arFromUs isEqual:[phoneUtil parse:@"011xx5481429712" defaultRegion:@"US" error:&aError]]);
    }

    
    #pragma mark - testParseNumbersMexico
    {
        NSError *aError = nil;
        NSLog(@"-------------- testParseNumbersMexico");
        // Test parsing fixed-line numbers of Mexico.
        
        id mxNumber = [[NBPhoneNumber alloc] init];
        [mxNumber setCountryCode:@52];
        [mxNumber setNationalNumber:@4499780001];
        XCTAssertTrue([mxNumber isEqual:[phoneUtil parse:@"+52 (449)978-0001" defaultRegion:@"MX" error:&aError]]);
        XCTAssertTrue([mxNumber isEqual:[phoneUtil parse:@"01 (449)978-0001" defaultRegion:@"MX" error:&aError]]);
        XCTAssertTrue([mxNumber isEqual:[phoneUtil parse:@"(449)978-0001" defaultRegion:@"MX" error:&aError]]);
        
        // Test parsing mobile numbers of Mexico.
        mxNumber = [[NBPhoneNumber alloc] init];
        [mxNumber setCountryCode:@52];
        [mxNumber setNationalNumber:@13312345678];
        XCTAssertTrue([mxNumber isEqual:[phoneUtil parse:@"+52 1 33 1234-5678" defaultRegion:@"MX" error:&aError]]);
        XCTAssertTrue([mxNumber isEqual:[phoneUtil parse:@"044 (33) 1234-5678" defaultRegion:@"MX" error:&aError]]);
        XCTAssertTrue([mxNumber isEqual:[phoneUtil parse:@"045 33 1234-5678" defaultRegion:@"MX" error:&aError]]);
    }

    
    #pragma mark - testFailedParseOnInvalidNumbers
    {
        NSLog(@"-------------- testFailedParseOnInvalidNumbers");
        {
            NSError *aError = nil;
            NSString *sentencePhoneNumber = @"This is not a phone number";
            [phoneUtil parse:sentencePhoneNumber defaultRegion:@"NZ" error:&aError];
            
            if (aError == nil)
                XCTFail(@"This should not parse without throwing an exception %@", sentencePhoneNumber);
            else
                // Expected this exception.
                XCTAssertEqualObjects(@"NOT_A_NUMBER", aError.domain ,@"Wrong error type stored in exception.");
        }
        {
            NSError *aError = nil;
            NSString *sentencePhoneNumber = @"1 Still not a number";
            [phoneUtil parse:sentencePhoneNumber defaultRegion:@"NZ" error:&aError];
            
            if (aError == nil)
                XCTFail(@"This should not parse without throwing an exception %@", sentencePhoneNumber);
            else
                // Expected this exception.
                XCTAssertEqualObjects(@"NOT_A_NUMBER", aError.domain, @"Wrong error type stored in exception.");
        }
        
        {
            NSError *aError = nil;
            NSString *sentencePhoneNumber = @"1 MICROSOFT";
            [phoneUtil parse:sentencePhoneNumber defaultRegion:@"NZ" error:&aError];
            
            if (aError == nil)
                XCTFail(@"This should not parse without throwing an exception %@", sentencePhoneNumber);
            else
                // Expected this exception.
                XCTAssertEqualObjects(@"NOT_A_NUMBER", aError.domain, @"Wrong error type stored in exception.");
        }
                   
        {
            NSError *aError = nil;
            NSString *sentencePhoneNumber = @"12 MICROSOFT";
            [phoneUtil parse:sentencePhoneNumber defaultRegion:@"NZ" error:&aError];
            
            if (aError == nil)
                XCTFail(@"This should not parse without throwing an exception %@", sentencePhoneNumber);
            else
                // Expected this exception.
                XCTAssertEqualObjects(@"NOT_A_NUMBER", aError.domain, @"Wrong error type stored in exception.");
        }
                   
        {
            NSError *aError = nil;
            NSString *tooLongPhoneNumber = @"01495 72553301873 810104";
            [phoneUtil parse:tooLongPhoneNumber defaultRegion:@"GB" error:&aError];
            
            if (aError == nil)
                XCTFail(@"This should not parse without throwing an exception %@", tooLongPhoneNumber);
            else
                // Expected this exception.
                XCTAssertEqualObjects(@"TOO_LONG", aError.domain, @"Wrong error type stored in exception.");
        }
                   
        {
            NSError *aError = nil;
            NSString *plusMinusPhoneNumber = @"+---";
            [phoneUtil parse:plusMinusPhoneNumber defaultRegion:@"DE" error:&aError];
            
            if (aError == nil)
                XCTFail(@"This should not parse without throwing an exception %@", plusMinusPhoneNumber);
            else
                // Expected this exception.
                XCTAssertEqualObjects(@"NOT_A_NUMBER", aError.domain, @"Wrong error type stored in exception.");
        }
                   
        {
            NSError *aError = nil;
            NSString *plusStar = @"+***";
            [phoneUtil parse:plusStar defaultRegion:@"DE" error:&aError];
            if (aError == nil)
                XCTFail(@"This should not parse without throwing an exception %@", plusStar);
            else
                // Expected this exception.
                XCTAssertEqualObjects(@"NOT_A_NUMBER", aError.domain, @"Wrong error type stored in exception.");
        }
        
        {
            NSError *aError = nil;
            NSString *plusStarPhoneNumber = @"+*******91";
            [phoneUtil parse:plusStarPhoneNumber defaultRegion:@"DE" error:&aError];
            if (aError == nil)
                XCTFail(@"This should not parse without throwing an exception %@", plusStarPhoneNumber);
            else
                // Expected this exception.
                XCTAssertEqualObjects(@"NOT_A_NUMBER", aError.domain, @"Wrong error type stored in exception.");
        }
        
        {
            NSError *aError = nil;
            NSString *tooShortPhoneNumber = @"+49 0";
            [phoneUtil parse:tooShortPhoneNumber defaultRegion:@"DE" error:&aError];
            if (aError == nil)
                XCTFail(@"This should not parse without throwing an exception %@", tooShortPhoneNumber);
            else
                // Expected this exception.
                XCTAssertEqualObjects(@"TOO_SHORT_NSN", aError.domain, @"Wrong error type stored in exception.");
        }
        
        {
            NSError *aError = nil;
            NSString *invalidcountryCode = @"+210 3456 56789";
            [phoneUtil parse:invalidcountryCode defaultRegion:@"NZ" error:&aError];
            if (aError == nil)
                XCTFail(@"This is not a recognised region code: should fail: %@", invalidcountryCode);
            else
                // Expected this exception.
                XCTAssertEqualObjects(@"INVALID_COUNTRY_CODE", aError.domain, @"Wrong error type stored in exception.");
        }
        
        {
            NSError *aError = nil;
            NSString *plusAndIddAndInvalidcountryCode = @"+ 00 210 3 331 6005";
            [phoneUtil parse:plusAndIddAndInvalidcountryCode defaultRegion:@"NZ" error:&aError];
            if (aError == nil)
                XCTFail(@"This should not parse without throwing an exception.");
            else {
                // Expected this exception. 00 is a correct IDD, but 210 is not a valid
                // country code.
                XCTAssertEqualObjects(@"INVALID_COUNTRY_CODE", aError.domain, @"Wrong error type stored in exception.");
            }
        }
                   
        {
            NSError *aError = nil;
            NSString *someNumber = @"123 456 7890";
            [phoneUtil parse:someNumber defaultRegion:@"ZZ" error:&aError];
            if (aError == nil)
                XCTFail(@"Unknown region code not allowed: should fail.");
            else
                // Expected this exception.
                XCTAssertEqualObjects(@"INVALID_COUNTRY_CODE", aError.domain, @"Wrong error type stored in exception.");
        }
        
        {
            NSError *aError = nil;
            NSString *someNumber = @"123 456 7890";
            [phoneUtil parse:someNumber defaultRegion:@"CS" error:&aError];
            if (aError == nil)
                XCTFail(@"Deprecated region code not allowed: should fail.");
            else
                // Expected this exception.
                XCTAssertEqualObjects(@"INVALID_COUNTRY_CODE", aError.domain, @"Wrong error type stored in exception.");
        }
        
        {
            NSError *aError = nil;
            NSString *someNumber = @"123 456 7890";
            [phoneUtil parse:someNumber defaultRegion:nil error:&aError];
            if (aError == nil)
                XCTFail(@"nil region code not allowed: should fail.");
            else
                // Expected this exception.
                XCTAssertEqualObjects(@"INVALID_COUNTRY_CODE", aError.domain, @"Wrong error type stored in exception.");
        }
        
        
        {
            NSError *aError = nil;
            NSString *someNumber = @"0044------";
            [phoneUtil parse:someNumber defaultRegion:@"GB" error:&aError];
            if (aError == nil)
                XCTFail(@"No number provided, only region code: should fail");
            else
                // Expected this exception.
                XCTAssertEqualObjects(@"TOO_SHORT_AFTER_IDD", aError.domain, @"Wrong error type stored in exception.");
        }
        
        {
            NSError *aError = nil;
            NSString *someNumber = @"0044";
            [phoneUtil parse:someNumber defaultRegion:@"GB" error:&aError];
            if (aError == nil)
                XCTFail(@"No number provided, only region code: should fail");
            else
                // Expected this exception.
                XCTAssertEqualObjects(@"TOO_SHORT_AFTER_IDD", aError.domain, @"Wrong error type stored in exception.");
        }
        
        {
            NSError *aError = nil;
            NSString *someNumber = @"011";
            [phoneUtil parse:someNumber defaultRegion:@"US" error:&aError];
            if (aError == nil)
                XCTFail(@"Only IDD provided - should fail.");
            else
                // Expected this exception.
                XCTAssertEqualObjects(@"TOO_SHORT_AFTER_IDD", aError.domain, @"Wrong error type stored in exception.");
        }
        
        {
            NSError *aError = nil;
            NSString *someNumber = @"0119";
            [phoneUtil parse:someNumber defaultRegion:@"US" error:&aError];
            if (aError == nil)
                XCTFail(@"Only IDD provided and then 9 - should fail.");
            else
                // Expected this exception.
                XCTAssertEqualObjects(@"TOO_SHORT_AFTER_IDD", aError.domain, @"Wrong error type stored in exception.");
        }
        
        {
            NSError *aError = nil;
            NSString *emptyNumber = @"";
            // Invalid region.
            [phoneUtil parse:emptyNumber defaultRegion:@"ZZ" error:&aError];
            if (aError == nil)
                XCTFail(@"Empty string - should fail.");
            else
                // Expected this exception.
                XCTAssertEqualObjects(@"NOT_A_NUMBER", aError.domain, @"Wrong error type stored in exception.");
        }
        
        {
            NSError *aError = nil;
            // Invalid region.
            [phoneUtil parse:nil defaultRegion:@"ZZ" error:&aError];
            if (aError == nil)
                XCTFail(@"nil string - should fail.");
            else
                // Expected this exception.
                XCTAssertEqualObjects(@"NOT_A_NUMBER", aError.domain, @"Wrong error type stored in exception.");
        }
        
        {
            NSError *aError = nil;
            [phoneUtil parse:nil defaultRegion:@"US" error:&aError];
            if (aError == nil)
                XCTFail(@"nil string - should fail.");
            else
                // Expected this exception.
                XCTAssertEqualObjects(@"NOT_A_NUMBER", aError.domain, @"Wrong error type stored in exception.");
        }
        
        {
            NSError *aError = nil;
            NSString *domainRfcPhoneContext = @"tel:555-1234;phone-context=www.google.com";
            [phoneUtil parse:domainRfcPhoneContext defaultRegion:@"ZZ" error:&aError];
            if (aError == nil)
                XCTFail(@"Unknown region code not allowed: should fail.");
            else
                // Expected this exception.
                XCTAssertEqualObjects(@"INVALID_COUNTRY_CODE", aError.domain, @"Wrong error type stored in exception.");
        }
        
        {
            NSError *aError = nil;
            // This is invalid because no '+' sign is present as part of phone-context.
            // This should not succeed in being parsed.
            
            NSString *invalidRfcPhoneContext = @"tel:555-1234;phone-context=1-331";
            [phoneUtil parse:invalidRfcPhoneContext defaultRegion:@"ZZ" error:&aError];
            if (aError == nil)
                XCTFail(@"Unknown region code not allowed: should fail.");
            else
                // Expected this exception.
                XCTAssertEqualObjects(@"INVALID_COUNTRY_CODE", aError.domain, @"Wrong error type stored in exception.");
        }
    }
    

    #pragma mark - testParseNumbersWithPlusWithNoRegion
    {
        NSLog(@"-------------- testParseNumbersWithPlusWithNoRegion");
        NSError *aError;
        // @"ZZ is allowed only if the number starts with a '+' - then the
        // country calling code can be calculated.
        XCTAssertTrue([NZ_NUMBER isEqual:[phoneUtil parse:@"+64 3 331 6005" defaultRegion:@"ZZ" error:&aError]]);
        // Test with full-width plus.
        XCTAssertTrue([NZ_NUMBER isEqual:[phoneUtil parse:@"\uFF0B64 3 331 6005" defaultRegion:@"ZZ" error:&aError]]);
        // Test with normal plus but leading characters that need to be stripped.
        XCTAssertTrue([NZ_NUMBER isEqual:[phoneUtil parse:@"Tel: +64 3 331 6005" defaultRegion:@"ZZ" error:&aError]]);
        XCTAssertTrue([NZ_NUMBER isEqual:[phoneUtil parse:@"+64 3 331 6005" defaultRegion:nil error:&aError]]);
        XCTAssertTrue([INTERNATIONAL_TOLL_FREE isEqual:[phoneUtil parse:@"+800 1234 5678" defaultRegion:nil error:&aError]]);
        XCTAssertTrue([UNIVERSAL_PREMIUM_RATE isEqual:[phoneUtil parse:@"+979 123 456 789" defaultRegion:nil error:&aError]]);
        
        // Test parsing RFC3966 format with a phone context.
        XCTAssertTrue([NZ_NUMBER isEqual:[phoneUtil parse:@"tel:03-331-6005;phone-context=+64" defaultRegion:@"ZZ" error:&aError]]);
        XCTAssertTrue([NZ_NUMBER isEqual:[phoneUtil parse:@"  tel:03-331-6005;phone-context=+64" defaultRegion:@"ZZ" error:&aError]]);
        XCTAssertTrue([NZ_NUMBER isEqual:[phoneUtil parse:@"tel:03-331-6005;isub=12345;phone-context=+64" defaultRegion:@"ZZ" error:&aError]]);
        
        // It is important that we set the carrier code to an empty string, since we
        // used ParseAndKeepRawInput and no carrier code was found.
        
        id nzNumberWithRawInput = [NZ_NUMBER copy];
        [nzNumberWithRawInput setRawInput:@"+64 3 331 6005"];
        [nzNumberWithRawInput setCountryCodeSource:[NSNumber numberWithInt:NBECountryCodeSourceFROM_NUMBER_WITH_PLUS_SIGN]];
        [nzNumberWithRawInput setPreferredDomesticCarrierCode:@""];
        XCTAssertTrue([nzNumberWithRawInput isEqual:[phoneUtil parseAndKeepRawInput:@"+64 3 331 6005" defaultRegion:@"ZZ" error:&aError]]);
        // nil is also allowed for the region code in these cases.
        XCTAssertTrue([nzNumberWithRawInput isEqual:[phoneUtil parseAndKeepRawInput:@"+64 3 331 6005" defaultRegion:nil error:&aError]]);
    }


    #pragma mark - testParseExtensions
    {
        NSError *aError = nil;
        NSLog(@"-------------- testParseExtensions");
        NBPhoneNumber *nzNumber = [[NBPhoneNumber alloc] init];
        [nzNumber setCountryCode:@64];
        [nzNumber setNationalNumber:@33316005];
        [nzNumber setExtension:@"3456"];
        XCTAssertTrue([nzNumber isEqual:[phoneUtil parse:@"03 331 6005 ext 3456" defaultRegion:@"NZ" error:&aError]]);
        XCTAssertTrue([nzNumber isEqual:[phoneUtil parse:@"03-3316005x3456" defaultRegion:@"NZ" error:&aError]]);
        XCTAssertTrue([nzNumber isEqual:[phoneUtil parse:@"03-3316005 int.3456" defaultRegion:@"NZ" error:&aError]]);
        XCTAssertTrue([nzNumber isEqual:[phoneUtil parse:@"03 3316005 #3456" defaultRegion:@"NZ" error:&aError]]);
        
        // Test the following do not extract extensions:
        XCTAssertTrue([ALPHA_NUMERIC_NUMBER isEqual:[phoneUtil parse:@"1800 six-flags" defaultRegion:@"US" error:&aError]]);
        XCTAssertTrue([ALPHA_NUMERIC_NUMBER isEqual:[phoneUtil parse:@"1800 SIX FLAGS" defaultRegion:@"US" error:&aError]]);
        XCTAssertTrue([ALPHA_NUMERIC_NUMBER isEqual:[phoneUtil parse:@"0~0 1800 7493 5247" defaultRegion:@"PL" error:&aError]]);
        XCTAssertTrue([ALPHA_NUMERIC_NUMBER isEqual:[phoneUtil parse:@"(1800) 7493.5247" defaultRegion:@"US" error:&aError]]);
        
        // Check that the last instance of an extension token is matched.
        
        id extnNumber = [ALPHA_NUMERIC_NUMBER copy];
        [extnNumber setExtension:@"1234"];
        XCTAssertTrue([extnNumber isEqual:[phoneUtil parse:@"0~0 1800 7493 5247 ~1234" defaultRegion:@"PL" error:&aError]]);
        
        // Verifying bug-fix where the last digit of a number was previously omitted
        // if it was a 0 when extracting the extension. Also verifying a few different
        // cases of extensions.
        
        id ukNumber = [[NBPhoneNumber alloc] init];
        [ukNumber setCountryCode:@44];
        [ukNumber setNationalNumber:@2034567890];
        [ukNumber setExtension:@"456"];
        XCTAssertTrue([ukNumber isEqual:[phoneUtil parse:@"+44 2034567890x456" defaultRegion:@"NZ" error:&aError]]);
        XCTAssertTrue([ukNumber isEqual:[phoneUtil parse:@"+44 2034567890x456" defaultRegion:@"GB" error:&aError]]);
        XCTAssertTrue([ukNumber isEqual:[phoneUtil parse:@"+44 2034567890 x456" defaultRegion:@"GB" error:&aError]]);
        XCTAssertTrue([ukNumber isEqual:[phoneUtil parse:@"+44 2034567890 X456" defaultRegion:@"GB" error:&aError]]);
        XCTAssertTrue([ukNumber isEqual:[phoneUtil parse:@"+44 2034567890 X 456" defaultRegion:@"GB" error:&aError]]);
        XCTAssertTrue([ukNumber isEqual:[phoneUtil parse:@"+44 2034567890 X  456" defaultRegion:@"GB" error:&aError]]);
        XCTAssertTrue([ukNumber isEqual:[phoneUtil parse:@"+44 2034567890 x 456  " defaultRegion:@"GB" error:&aError]]);
        XCTAssertTrue([ukNumber isEqual:[phoneUtil parse:@"+44 2034567890  X 456" defaultRegion:@"GB" error:&aError]]);
        XCTAssertTrue([ukNumber isEqual:[phoneUtil parse:@"+44-2034567890;ext=456" defaultRegion:@"GB" error:&aError]]);
        XCTAssertTrue([ukNumber isEqual:[phoneUtil parse:@"tel:2034567890;ext=456;phone-context=+44" defaultRegion:@"ZZ" error:&aError]]);
        // Full-width extension, @"extn' only.
        XCTAssertTrue([ukNumber isEqual:[phoneUtil parse:@"+442034567890\uFF45\uFF58\uFF54\uFF4E456" defaultRegion:@"GB" error:&aError]]);
        // 'xtn' only.
        XCTAssertTrue([ukNumber isEqual:[phoneUtil parse:@"+442034567890\uFF58\uFF54\uFF4E456" defaultRegion:@"GB" error:&aError]]);
        // 'xt' only.
        XCTAssertTrue([ukNumber isEqual:[phoneUtil parse:@"+442034567890\uFF58\uFF54456" defaultRegion:@"GB" error:&aError]]);
        
        id usWithExtension = [[NBPhoneNumber alloc] init];
        [usWithExtension setCountryCode:@1];
        [usWithExtension setNationalNumber:@8009013355];
        [usWithExtension setExtension:@"7246433"];
        XCTAssertTrue([usWithExtension isEqual:[phoneUtil parse:@"(800) 901-3355 x 7246433" defaultRegion:@"US" error:&aError]]);
        XCTAssertTrue([usWithExtension isEqual:[phoneUtil parse:@"(800) 901-3355 , ext 7246433" defaultRegion:@"US" error:&aError]]);
        XCTAssertTrue([usWithExtension isEqual:[phoneUtil parse:@"(800) 901-3355 ,extension 7246433" defaultRegion:@"US" error:&aError]]);
        XCTAssertTrue([usWithExtension isEqual:[phoneUtil parse:@"(800) 901-3355 ,extensi\u00F3n 7246433" defaultRegion:@"US" error:&aError]]);
        
        // Repeat with the small letter o with acute accent created by combining
        // characters.
        XCTAssertTrue([usWithExtension isEqual:[phoneUtil parse:@"(800) 901-3355 ,extensio\u0301n 7246433" defaultRegion:@"US" error:&aError]]);
        XCTAssertTrue([usWithExtension isEqual:[phoneUtil parse:@"(800) 901-3355 , 7246433" defaultRegion:@"US" error:&aError]]);
        XCTAssertTrue([usWithExtension isEqual:[phoneUtil parse:@"(800) 901-3355 ext: 7246433" defaultRegion:@"US" error:&aError]]);
        
        // Test that if a number has two extensions specified, we ignore the second.
        id usWithTwoExtensionsNumber = [[NBPhoneNumber alloc] init];
        [usWithTwoExtensionsNumber setCountryCode:@1];
        [usWithTwoExtensionsNumber setNationalNumber:@2121231234];
        [usWithTwoExtensionsNumber setExtension:@"508"];
        XCTAssertTrue([usWithTwoExtensionsNumber isEqual:[phoneUtil parse:@"(212)123-1234 x508/x1234" defaultRegion:@"US" error:&aError]]);
        XCTAssertTrue([usWithTwoExtensionsNumber isEqual:[phoneUtil parse:@"(212)123-1234 x508/ x1234" defaultRegion:@"US" error:&aError]]);
        XCTAssertTrue([usWithTwoExtensionsNumber isEqual:[phoneUtil parse:@"(212)123-1234 x508\\x1234" defaultRegion:@"US" error:&aError]]);
        
        // Test parsing numbers in the form (645) 123-1234-910# works, where the last
        // 3 digits before the # are an extension.
        usWithExtension = [[NBPhoneNumber alloc] init];
        [usWithExtension setCountryCode:@1];
        [usWithExtension setNationalNumber:@6451231234];
        [usWithExtension setExtension:@"910"];
        XCTAssertTrue([usWithExtension isEqual:[phoneUtil parse:@"+1 (645) 123 1234-910#" defaultRegion:@"US" error:&aError]]);
        // Retry with the same number in a slightly different format.
        XCTAssertTrue([usWithExtension isEqual:[phoneUtil parse:@"+1 (645) 123 1234 ext. 910#" defaultRegion:@"US" error:&aError]]);
    }
    
        
    #pragma mark - testParseAndKeepRaw
    {
        NSError *aError;
        NSLog(@"-------------- testParseAndKeepRaw");
        NBPhoneNumber *alphaNumericNumber = [ALPHA_NUMERIC_NUMBER copy];
        [alphaNumericNumber setRawInput:@"800 six-flags"];
        [alphaNumericNumber setCountryCodeSource:[NSNumber numberWithInt:NBECountryCodeSourceFROM_DEFAULT_COUNTRY]];
        [alphaNumericNumber setPreferredDomesticCarrierCode:@""];
        XCTAssertTrue([alphaNumericNumber isEqual:[phoneUtil parseAndKeepRawInput:@"800 six-flags" defaultRegion:@"US" error:&aError]]);
        
        id shorterAlphaNumber = [[NBPhoneNumber alloc] init];
        [shorterAlphaNumber setCountryCode:@1];
        [shorterAlphaNumber setNationalNumber:@8007493524];
        [shorterAlphaNumber setRawInput:@"1800 six-flag"];
        [shorterAlphaNumber setCountryCodeSource:[NSNumber numberWithInt:NBECountryCodeSourceFROM_NUMBER_WITHOUT_PLUS_SIGN]];
        [shorterAlphaNumber setPreferredDomesticCarrierCode:@""];
        XCTAssertTrue([shorterAlphaNumber isEqual:[phoneUtil parseAndKeepRawInput:@"1800 six-flag" defaultRegion:@"US" error:&aError]]);
        
        [shorterAlphaNumber setRawInput:@"+1800 six-flag"];
        [shorterAlphaNumber setCountryCodeSource:[NSNumber numberWithInt:NBECountryCodeSourceFROM_NUMBER_WITH_PLUS_SIGN]];
        XCTAssertTrue([shorterAlphaNumber isEqual:[phoneUtil parseAndKeepRawInput:@"+1800 six-flag" defaultRegion:@"NZ" error:&aError]]);
        
        [alphaNumericNumber setCountryCode:@1];
        [alphaNumericNumber setNationalNumber:@8007493524];
        [alphaNumericNumber setRawInput:@"001800 six-flag"];
        [alphaNumericNumber setCountryCodeSource:[NSNumber numberWithInt:NBECountryCodeSourceFROM_NUMBER_WITH_IDD]];
        XCTAssertTrue([alphaNumericNumber isEqual:[phoneUtil parseAndKeepRawInput:@"001800 six-flag" defaultRegion:@"NZ" error:&aError]]);
        
        // Invalid region code supplied.
        {
            [phoneUtil parseAndKeepRawInput:@"123 456 7890" defaultRegion:@"CS" error:&aError];
            if (aError == nil)
                XCTFail(@"Deprecated region code not allowed: should fail.");
            else {
                // Expected this exception.
                XCTAssertEqualObjects(@"INVALID_COUNTRY_CODE", aError.domain, @"Wrong error type stored in exception.");
            }
        }
        
        id koreanNumber = [[NBPhoneNumber alloc] init];
        [koreanNumber setCountryCode:@82];
        [koreanNumber setNationalNumber:@22123456];
        [koreanNumber setRawInput:@"08122123456"];
        [koreanNumber setCountryCodeSource:[NSNumber numberWithInt:NBECountryCodeSourceFROM_DEFAULT_COUNTRY]];
        [koreanNumber setPreferredDomesticCarrierCode:@"81"];
        XCTAssertTrue([koreanNumber isEqual:[phoneUtil parseAndKeepRawInput:@"08122123456" defaultRegion:@"KR" error:&aError]]);
    }
    
        
    #pragma mark - testCountryWithNoNumberDesc
    {
        NSLog(@"-------------- testCountryWithNoNumberDesc");
        // Andorra is a country where we don't have PhoneNumberDesc info in the
        // metadata.
        NBPhoneNumber *adNumber = [[NBPhoneNumber alloc] init];
        [adNumber setCountryCode:@376];
        [adNumber setNationalNumber:@12345];
        XCTAssertEqualObjects(@"+376 12345", [phoneUtil format:adNumber numberFormat:NBEPhoneNumberFormatINTERNATIONAL]);
        XCTAssertEqualObjects(@"+37612345", [phoneUtil format:adNumber numberFormat:NBEPhoneNumberFormatE164]);
        XCTAssertEqualObjects(@"12345", [phoneUtil format:adNumber numberFormat:NBEPhoneNumberFormatNATIONAL]);
        XCTAssertEqual(NBEPhoneNumberTypeUNKNOWN, [phoneUtil getNumberType:adNumber]);
        XCTAssertTrue([phoneUtil isValidNumber:adNumber]);
        
        // Test dialing a US number from within Andorra.
        XCTAssertEqualObjects(@"00 1 650 253 0000", [phoneUtil formatOutOfCountryCallingNumber:US_NUMBER regionCallingFrom:@"AD"]);
    }

    
    #pragma mark - testUnknownCountryCallingCode
    {
        NSLog(@"-------------- testUnknownCountryCallingCode");
        XCTAssertFalse([phoneUtil isValidNumber:UNKNOWN_COUNTRY_CODE_NO_RAW_INPUT]);
        // It's not very well defined as to what the E164 representation for a number
        // with an invalid country calling code is, but just prefixing the country
        // code and national number is about the best we can do.
        XCTAssertEqualObjects(@"+212345", [phoneUtil format:UNKNOWN_COUNTRY_CODE_NO_RAW_INPUT numberFormat:NBEPhoneNumberFormatE164]);
    }

    
    #pragma mark - testIsNumberMatchMatches
    {
        NSLog(@"-------------- testIsNumberMatchMatches");
        // Test simple matches where formatting is different, or leading zeroes,
        // or country calling code has been specified.
        
        NSError *aError = nil;
        
        NBPhoneNumber *num1 = [phoneUtil parse:@"+64 3 331 6005" defaultRegion:@"NZ" error:&aError];
        NBPhoneNumber *num2 = [phoneUtil parse:@"+64 03 331 6005" defaultRegion:@"NZ" error:&aError];
        XCTAssertEqual(NBEMatchTypeEXACT_MATCH, [phoneUtil isNumberMatch:num1 second:num2]);
        XCTAssertEqual(NBEMatchTypeEXACT_MATCH, [phoneUtil isNumberMatch:@"+64 3 331 6005" second:@"+64 03 331 6005"]);
        XCTAssertEqual(NBEMatchTypeEXACT_MATCH, [phoneUtil isNumberMatch:@"+800 1234 5678" second:@"+80012345678"]);
        XCTAssertEqual(NBEMatchTypeEXACT_MATCH, [phoneUtil isNumberMatch:@"+64 03 331-6005" second:@"+64 03331 6005"]);
        XCTAssertEqual(NBEMatchTypeEXACT_MATCH, [phoneUtil isNumberMatch:@"+643 331-6005" second:@"+64033316005"]);
        XCTAssertEqual(NBEMatchTypeEXACT_MATCH, [phoneUtil isNumberMatch:@"+643 331-6005" second:@"+6433316005"]);
        XCTAssertEqual(NBEMatchTypeEXACT_MATCH, [phoneUtil isNumberMatch:@"+64 3 331-6005" second:@"+6433316005"]);
        XCTAssertEqual(NBEMatchTypeEXACT_MATCH, [phoneUtil isNumberMatch:@"+64 3 331-6005" second:@"tel:+64-3-331-6005;isub=123"]);
        // Test alpha numbers.
        XCTAssertEqual(NBEMatchTypeEXACT_MATCH, [phoneUtil isNumberMatch:@"+1800 siX-Flags" second:@"+1 800 7493 5247"]);
        // Test numbers with extensions.
        XCTAssertEqual(NBEMatchTypeEXACT_MATCH, [phoneUtil isNumberMatch:@"+64 3 331-6005 extn 1234" second:@"+6433316005#1234"]);
        // Test proto buffers.
        XCTAssertEqual(NBEMatchTypeEXACT_MATCH, [phoneUtil isNumberMatch:NZ_NUMBER second:@"+6403 331 6005"]);
        
        NBPhoneNumber *nzNumber = [NZ_NUMBER copy];
        [nzNumber setExtension:@"3456"];
        XCTAssertEqual(NBEMatchTypeEXACT_MATCH, [phoneUtil isNumberMatch:nzNumber second:@"+643 331 6005 ext 3456"]);
        // Check empty extensions are ignored.
        [nzNumber setExtension:@""];
        XCTAssertEqual(NBEMatchTypeEXACT_MATCH, [phoneUtil isNumberMatch:nzNumber second:@"+6403 331 6005"]);
        // Check variant with two proto buffers.
        XCTAssertEqual(NBEMatchTypeEXACT_MATCH, [phoneUtil isNumberMatch:nzNumber second:NZ_NUMBER], @"Numbers did not match");
        
        // Check raw_input, country_code_source and preferred_domestic_carrier_code
        // are ignored.
        
        NBPhoneNumber *brNumberOne = [[NBPhoneNumber alloc] init];
        
        NBPhoneNumber *brNumberTwo = [[NBPhoneNumber alloc] init];
        [brNumberOne setCountryCode:@55];
        [brNumberOne setNationalNumber:@3121286979];
        [brNumberOne setCountryCodeSource:[NSNumber numberWithInt:NBECountryCodeSourceFROM_NUMBER_WITH_PLUS_SIGN]];
        [brNumberOne setPreferredDomesticCarrierCode:@"12"];
        [brNumberOne setRawInput:@"012 3121286979"];
        [brNumberTwo setCountryCode:@55];
        [brNumberTwo setNationalNumber:@3121286979];
        [brNumberTwo setCountryCodeSource:[NSNumber numberWithInt:NBECountryCodeSourceFROM_DEFAULT_COUNTRY]];
        [brNumberTwo setPreferredDomesticCarrierCode:@"14"];
        [brNumberTwo setRawInput:@"143121286979"];
        XCTAssertEqual(NBEMatchTypeEXACT_MATCH, [phoneUtil isNumberMatch:brNumberOne second:brNumberTwo]);
    }

    #pragma mark - testIsNumberMatchNonMatches
    {
        NSLog(@"-------------- testIsNumberMatchNonMatches");
        // Non-matches.
        XCTAssertEqual(NBEMatchTypeNO_MATCH, [phoneUtil isNumberMatch:@"03 331 6005" second:@"03 331 6006"]);
        XCTAssertEqual(NBEMatchTypeNO_MATCH, [phoneUtil isNumberMatch:@"+800 1234 5678" second:@"+1 800 1234 5678"]);
        // Different country calling code, partial number match.
        XCTAssertEqual(NBEMatchTypeNO_MATCH, [phoneUtil isNumberMatch:@"+64 3 331-6005" second:@"+16433316005"]);
        // Different country calling code, same number.
        XCTAssertEqual(NBEMatchTypeNO_MATCH, [phoneUtil isNumberMatch:@"+64 3 331-6005" second:@"+6133316005"]);
        // Extension different, all else the same.
        XCTAssertEqual(NBEMatchTypeNO_MATCH, [phoneUtil isNumberMatch:@"+64 3 331-6005 extn 1234" second:@"0116433316005#1235"]);
        XCTAssertEqual(NBEMatchTypeNO_MATCH, [phoneUtil isNumberMatch:@"+64 3 331-6005 extn 1234" second:@"tel:+64-3-331-6005;ext=1235"]);
        // NSN matches, but extension is different - not the same number.
        XCTAssertEqual(NBEMatchTypeNO_MATCH, [phoneUtil isNumberMatch:@"+64 3 331-6005 ext.1235" second:@"3 331 6005#1234"]);
        
        // Invalid numbers that can't be parsed.
        XCTAssertEqual(NBEMatchTypeNOT_A_NUMBER, [phoneUtil isNumberMatch:@"4" second:@"3 331 6043"]);
        XCTAssertEqual(NBEMatchTypeNOT_A_NUMBER, [phoneUtil isNumberMatch:@"+43" second:@"+64 3 331 6005"]);
        XCTAssertEqual(NBEMatchTypeNOT_A_NUMBER, [phoneUtil isNumberMatch:@"+43" second:@"64 3 331 6005"]);
        XCTAssertEqual(NBEMatchTypeNOT_A_NUMBER, [phoneUtil isNumberMatch:@"Dog" second:@"64 3 331 6005"]);
    }

    
    #pragma mark - testIsNumberMatchNsnMatches
    {
        NSLog(@"-------------- testIsNumberMatchNsnMatches");
        // NSN matches.
        XCTAssertEqual(NBEMatchTypeNSN_MATCH, [phoneUtil isNumberMatch:@"+64 3 331-6005" second:@"03 331 6005"]);
        XCTAssertEqual(NBEMatchTypeNSN_MATCH, [phoneUtil isNumberMatch:@"+64 3 331-6005" second:@"tel:03-331-6005;isub=1234;phone-context=abc.nz"]);
        XCTAssertEqual(NBEMatchTypeNSN_MATCH, [phoneUtil isNumberMatch:NZ_NUMBER second:@"03 331 6005"]);
        // Here the second number possibly starts with the country calling code for
        // New Zealand, although we are unsure.
        
        NBPhoneNumber *unchangedNzNumber = [NZ_NUMBER copy];
        XCTAssertEqual(NBEMatchTypeNSN_MATCH, [phoneUtil isNumberMatch:unchangedNzNumber second:@"(64-3) 331 6005"]);
        // Check the phone number proto was not edited during the method call.
        XCTAssertTrue([NZ_NUMBER isEqual:unchangedNzNumber]);
        
        // Here, the 1 might be a national prefix, if we compare it to the US number,
        // so the resultant match is an NSN match.
        XCTAssertEqual(NBEMatchTypeNSN_MATCH, [phoneUtil isNumberMatch:US_NUMBER second:@"1-650-253-0000"]);
        XCTAssertEqual(NBEMatchTypeNSN_MATCH, [phoneUtil isNumberMatch:US_NUMBER second:@"6502530000"]);
        XCTAssertEqual(NBEMatchTypeNSN_MATCH, [phoneUtil isNumberMatch:@"+1 650-253 0000" second:@"1 650 253 0000"]);
        XCTAssertEqual(NBEMatchTypeNSN_MATCH, [phoneUtil isNumberMatch:@"1 650-253 0000" second:@"1 650 253 0000"]);
        XCTAssertEqual(NBEMatchTypeNSN_MATCH, [phoneUtil isNumberMatch:@"1 650-253 0000" second:@"+1 650 253 0000"]);
        // For this case, the match will be a short NSN match, because we cannot
        // assume that the 1 might be a national prefix, so don't remove it when
        // parsing.
        
        NBPhoneNumber *randomNumber = [[NBPhoneNumber alloc] init];
        [randomNumber setCountryCode:@41];
        [randomNumber setNationalNumber:@6502530000];
        XCTAssertEqual(NBEMatchTypeSHORT_NSN_MATCH, [phoneUtil isNumberMatch:randomNumber second:@"1-650-253-0000"]);
    }

    
    #pragma mark - testIsNumberMatchShortNsnMatches
    {
        NSLog(@"-------------- testIsNumberMatchShortNsnMatches");
        // Short NSN matches with the country not specified for either one or both
        // numbers.
        XCTAssertEqual(NBEMatchTypeSHORT_NSN_MATCH, [phoneUtil isNumberMatch:@"+64 3 331-6005" second:@"331 6005"]);
        XCTAssertEqual(NBEMatchTypeSHORT_NSN_MATCH, [phoneUtil isNumberMatch:@"+64 3 331-6005" second:@"tel:331-6005;phone-context=abc.nz"]);
        XCTAssertEqual(NBEMatchTypeSHORT_NSN_MATCH, [phoneUtil isNumberMatch:@"+64 3 331-6005" second:@"tel:331-6005;isub=1234;phone-context=abc.nz"]);
        XCTAssertEqual(NBEMatchTypeSHORT_NSN_MATCH, [phoneUtil isNumberMatch:@"+64 3 331-6005" second:@"tel:331-6005;isub=1234;phone-context=abc.nz;a=%A1"]);
        // We did not know that the '0' was a national prefix since neither number has
        // a country code, so this is considered a SHORT_NSN_MATCH.
        XCTAssertEqual(NBEMatchTypeSHORT_NSN_MATCH, [phoneUtil isNumberMatch:@"3 331-6005" second:@"03 331 6005"]);
        XCTAssertEqual(NBEMatchTypeSHORT_NSN_MATCH, [phoneUtil isNumberMatch:@"3 331-6005" second:@"331 6005"]);
        XCTAssertEqual(NBEMatchTypeSHORT_NSN_MATCH, [phoneUtil isNumberMatch:@"3 331-6005" second:@"tel:331-6005;phone-context=abc.nz"]);
        XCTAssertEqual(NBEMatchTypeSHORT_NSN_MATCH, [phoneUtil isNumberMatch:@"3 331-6005" second:@"+64 331 6005"]);
        // Short NSN match with the country specified.
        XCTAssertEqual(NBEMatchTypeSHORT_NSN_MATCH, [phoneUtil isNumberMatch:@"03 331-6005" second:@"331 6005"]);
        XCTAssertEqual(NBEMatchTypeSHORT_NSN_MATCH, [phoneUtil isNumberMatch:@"1 234 345 6789" second:@"345 6789"]);
        XCTAssertEqual(NBEMatchTypeSHORT_NSN_MATCH, [phoneUtil isNumberMatch:@"+1 (234) 345 6789" second:@"345 6789"]);
        // NSN matches, country calling code omitted for one number, extension missing
        // for one.
        XCTAssertEqual(NBEMatchTypeSHORT_NSN_MATCH, [phoneUtil isNumberMatch:@"+64 3 331-6005" second:@"3 331 6005#1234"]);
        // One has Italian leading zero, one does not.
        
        NBPhoneNumber *italianNumberOne = [[NBPhoneNumber alloc] init];
        [italianNumberOne setCountryCode:@39];
        [italianNumberOne setNationalNumber:@1234];
        [italianNumberOne setItalianLeadingZero:YES];
        
        NBPhoneNumber *italianNumberTwo = [[NBPhoneNumber alloc] init];
        [italianNumberTwo setCountryCode:@39];
        [italianNumberTwo setNationalNumber:@1234];
        XCTAssertEqual(NBEMatchTypeSHORT_NSN_MATCH, [phoneUtil isNumberMatch:italianNumberOne second:italianNumberTwo]);
        // One has an extension, the other has an extension of ''.
        [italianNumberOne setExtension:@"1234"];
        italianNumberOne.italianLeadingZero = NO;
        [italianNumberTwo setExtension:@""];
        XCTAssertEqual(NBEMatchTypeSHORT_NSN_MATCH, [phoneUtil isNumberMatch:italianNumberOne second:italianNumberTwo]);
    }

    
    #pragma mark - testCanBeInternationallyDialled
    {
        NSLog(@"-------------- testCanBeInternationallyDialled");
        // We have no-international-dialling rules for the US in our test metadata
        // that say that toll-free numbers cannot be dialled internationally.
        XCTAssertFalse([phoneUtil canBeInternationallyDialled:US_TOLLFREE]);
        
        // Normal US numbers can be internationally dialled.
        XCTAssertTrue([phoneUtil canBeInternationallyDialled:US_NUMBER]);
        
        // Invalid number.
        XCTAssertTrue([phoneUtil canBeInternationallyDialled:US_LOCAL_NUMBER]);
        
        // We have no data for NZ - should return true.
        XCTAssertTrue([phoneUtil canBeInternationallyDialled:NZ_NUMBER]);
        XCTAssertTrue([phoneUtil canBeInternationallyDialled:INTERNATIONAL_TOLL_FREE]);
    }

    
    #pragma mark - testIsAlphaNumber
    {
        NSLog(@"-------------- testIsAlphaNumber");
        XCTAssertTrue([phoneUtil isAlphaNumber:@"1800 six-flags"]);
        XCTAssertTrue([phoneUtil isAlphaNumber:@"1800 six-flags ext. 1234"]);
        XCTAssertTrue([phoneUtil isAlphaNumber:@"+800 six-flags"]);
        XCTAssertTrue([phoneUtil isAlphaNumber:@"180 six-flags"]);
        XCTAssertFalse([phoneUtil isAlphaNumber:@"1800 123-1234"]);
        XCTAssertFalse([phoneUtil isAlphaNumber:@"1 six-flags"]);
        XCTAssertFalse([phoneUtil isAlphaNumber:@"18 six-flags"]);
        XCTAssertFalse([phoneUtil isAlphaNumber:@"1800 123-1234 extension: 1234"]);
        XCTAssertFalse([phoneUtil isAlphaNumber:@"+800 1234-1234"]);
    }
}
@end
