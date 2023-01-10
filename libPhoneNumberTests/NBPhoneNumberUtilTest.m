//
//  NBPhoneNumberUtilTests.m
//  NBPhoneNumberUtilTests
//
//

#import <XCTest/XCTest.h>

#import "NBMetadataHelper.h"
#import "NBPhoneMetaData.h"

#import "NBNumberFormat.h"
#import "NBPhoneNumber.h"
#import "NBPhoneNumberDesc.h"
#import "NBPhoneNumberUtil.h"

#import "NBTestingMetaData.h"

// Create an entry array for a phone number desc based on numberPattern
static NSArray *PhoneNumberDescEntryForNationalNumberPattern(NSString *numberPattern) {
  // nationalNumberPattern is entry #2
  return @[ [NSNull null], [NSNull null], numberPattern ];
}

@interface NBPhoneNumberUtil (FOR_UNIT_TEST)

- (BOOL)canBeInternationallyDialled:(NBPhoneNumber *)number;
- (BOOL)truncateTooLongNumber:(NBPhoneNumber *)number;
- (NBEValidationResult)isPossibleNumberWithReason:(NBPhoneNumber *)number;
- (BOOL)isPossibleNumber:(NBPhoneNumber *)number;
- (NBEValidationResult)validateNumberLength:(NSString *)number
                                   metadata:(NBPhoneMetaData *)metadata
                                       type:(NBEPhoneNumberType)type;
- (NBEMatchType)isNumberMatch:(id)firstNumberIn second:(id)secondNumberIn;
- (int)getLengthOfGeographicalAreaCode:(NBPhoneNumber *)phoneNumber;
- (int)getLengthOfNationalDestinationCode:(NBPhoneNumber *)phoneNumber;
- (BOOL)maybeStripNationalPrefixAndCarrierCode:(NSString **)numberStr
                                      metadata:(NBPhoneMetaData *)metadata
                                   carrierCode:(NSString **)carrierCode;
- (NBECountryCodeSource)maybeStripInternationalPrefixAndNormalize:(NSString **)numberStr
                                                possibleIddPrefix:(NSString *)possibleIddPrefix;
- (NSString *)format:(NBPhoneNumber *)phoneNumber numberFormat:(NBEPhoneNumberFormat)numberFormat;
- (NSString *)formatByPattern:(NBPhoneNumber *)number
                 numberFormat:(NBEPhoneNumberFormat)numberFormat
           userDefinedFormats:(NSArray *)userDefinedFormats;
- (NSString *)formatNumberForMobileDialing:(NBPhoneNumber *)number
                         regionCallingFrom:(NSString *)regionCallingFrom
                            withFormatting:(BOOL)withFormatting;
- (NSString *)formatOutOfCountryCallingNumber:(NBPhoneNumber *)number
                            regionCallingFrom:(NSString *)regionCallingFrom;
- (NSString *)formatOutOfCountryKeepingAlphaChars:(NBPhoneNumber *)number
                                regionCallingFrom:(NSString *)regionCallingFrom;
- (NSString *)formatNationalNumberWithCarrierCode:(NBPhoneNumber *)number
                                      carrierCode:(NSString *)carrierCode;
- (NSString *)formatInOriginalFormat:(NBPhoneNumber *)number
                   regionCallingFrom:(NSString *)regionCallingFrom;
- (NSString *)formatNationalNumberWithPreferredCarrierCode:(NBPhoneNumber *)number
                                       fallbackCarrierCode:(NSString *)fallbackCarrierCode;

@end

@interface NBPhoneNumberUtilTest : XCTestCase

@property(nonatomic, strong) NBPhoneNumberUtil *aUtil;
@property(nonatomic, strong) NBMetadataHelper *helper;

@property(nonatomic, readonly, copy) NBPhoneNumber *alphaNumbericNumber;
@property(nonatomic, readonly, copy) NBPhoneNumber *arMobile;
@property(nonatomic, readonly, copy) NBPhoneNumber *arNumber;
@property(nonatomic, readonly, copy) NBPhoneNumber *auNumber;
@property(nonatomic, readonly, copy) NBPhoneNumber *bsMobile;
@property(nonatomic, readonly, copy) NBPhoneNumber *bsNumber;
@property(nonatomic, readonly, copy) NBPhoneNumber *deNumber;
@property(nonatomic, readonly, copy) NBPhoneNumber *deShortNumber;
@property(nonatomic, readonly, copy) NBPhoneNumber *gbMobile;
@property(nonatomic, readonly, copy) NBPhoneNumber *gbNumber;
@property(nonatomic, readonly, copy) NBPhoneNumber *internationalTollFreeNumber;
@property(nonatomic, readonly, copy) NBPhoneNumber *itMobile;
@property(nonatomic, readonly, copy) NBPhoneNumber *itNumber;
@property(nonatomic, readonly, copy) NBPhoneNumber *mxNumber;
@property(nonatomic, readonly, copy) NBPhoneNumber *mxMobile1;
@property(nonatomic, readonly, copy) NBPhoneNumber *mxMobile2;
@property(nonatomic, readonly, copy) NBPhoneNumber *nzNumber;
@property(nonatomic, readonly, copy) NBPhoneNumber *sgNumber;
@property(nonatomic, readonly, copy) NBPhoneNumber *universalPremiumRateNumber;
@property(nonatomic, readonly, copy) NBPhoneNumber *unknownCountryCodeNoRawInput;
@property(nonatomic, readonly, copy) NBPhoneNumber *usLocalNumber;
@property(nonatomic, readonly, copy) NBPhoneNumber *usNumber;
@property(nonatomic, readonly, copy) NBPhoneNumber *usPremiumNumber;
@property(nonatomic, readonly, copy) NBPhoneNumber *usShortByOneNumber;
@property(nonatomic, readonly, copy) NBPhoneNumber *usTollFreeNumber;

// Too-long and hence invalid numbers.
@property(nonatomic, readonly, copy) NBPhoneNumber *usTooLongNumber;
@property(nonatomic, readonly, copy) NBPhoneNumber *internationalTollFreeTooLongNumber;

@end

@implementation NBPhoneNumberUtilTest

- (void)setUp {
  [super setUp];
  NSBundle *bundle = [NSBundle bundleForClass:[self class]];
  NSString *path = [bundle pathForResource:@"libPhoneNumberMetadataForTesting" ofType:nil];
  NSData *data = [NSData dataWithContentsOfFile:path];
  self.helper =
      [[NBMetadataHelper alloc] initWithZippedData:data
                                    expandedLength:kPhoneNumberMetaDataForTestingExpandedLength];
  self.aUtil = [[NBPhoneNumberUtil alloc] initWithMetadataHelper:self.helper];
}

- (void)tearDown {
  [super tearDown];
}

- (NSString *)stringForNumberType:(NBEPhoneNumberType)type {
  switch (type) {
    case 0:
      return @"FIXED_LINE";
    case 1:
      return @"MOBILE";
    case 2:
      return @"FIXED_LINE_OR_MOBILE";
    case 3:
      return @"TOLL_FREE";
    case 4:
      return @"PREMIUM_RATE";
    case 5:
      return @"SHARED_COST";
    case 6:
      return @"VOIP";
    case 7:
      return @"PERSONAL_NUMBER";
    case 8:
      return @"PAGER";
    case 9:
      return @"UAN";
    case 10:
      return @"VOICEMAIL";
    default:
      return @"UNKNOWN";
  }
}

- (NBPhoneNumber *)alphaNumbericNumber {
  NBPhoneNumber *alphaNumbericNumber = [[NBPhoneNumber alloc] init];
  alphaNumbericNumber.countryCode = @1;
  alphaNumbericNumber.nationalNumber = @80074935247;
  return alphaNumbericNumber;
}

- (NBPhoneNumber *)arMobile {
  NBPhoneNumber *arMobile = [[NBPhoneNumber alloc] init];
  arMobile.countryCode = @54;
  arMobile.nationalNumber = @91187654321;
  return arMobile;
}

- (NBPhoneNumber *)arNumber {
  NBPhoneNumber *arNumber = [[NBPhoneNumber alloc] init];
  arNumber.countryCode = @54;
  arNumber.nationalNumber = @1187654321;
  return arNumber;
}

- (NBPhoneNumber *)auNumber {
  NBPhoneNumber *auNumber = [[NBPhoneNumber alloc] init];
  auNumber.countryCode = @61;
  auNumber.nationalNumber = @236618300;
  return auNumber;
}

- (NBPhoneNumber *)bsMobile {
  NBPhoneNumber *bsMobile = [[NBPhoneNumber alloc] init];
  bsMobile.countryCode = @1;
  bsMobile.nationalNumber = @2423570000;
  return bsMobile;
}

- (NBPhoneNumber *)bsNumber {
  NBPhoneNumber *bsNumber = [[NBPhoneNumber alloc] init];
  bsNumber.countryCode = @1;
  bsNumber.nationalNumber = @2423651234;
  return bsNumber;
}

- (NBPhoneNumber *)deShortNumber {
  NBPhoneNumber *deShortNumber = [[NBPhoneNumber alloc] init];
  deShortNumber.countryCode = @49;
  deShortNumber.nationalNumber = @1234;
  return deShortNumber;
}

- (NBPhoneNumber *)gbMobile {
  NBPhoneNumber *gbMobile = [[NBPhoneNumber alloc] init];
  gbMobile.countryCode = @44;
  gbMobile.nationalNumber = @7912345678;
  return gbMobile;
}

- (NBPhoneNumber *)itMobile {
  NBPhoneNumber *itMobile = [[NBPhoneNumber alloc] init];
  itMobile.countryCode = @39;
  itMobile.nationalNumber = @345678901;
  return itMobile;
}

- (NBPhoneNumber *)itNumber {
  NBPhoneNumber *itNumber = [[NBPhoneNumber alloc] init];
  itNumber.countryCode = @39;
  itNumber.nationalNumber = @236618300;
  itNumber.italianLeadingZero = YES;
  return itNumber;
}

- (NBPhoneNumber *)sgNumber {
  NBPhoneNumber *sgNumber = [[NBPhoneNumber alloc] init];
  sgNumber.countryCode = @65;
  sgNumber.nationalNumber = @65218000;
  return sgNumber;
}

- (NBPhoneNumber *)nzNumber {
  NBPhoneNumber *nzNumber = [[NBPhoneNumber alloc] init];
  [nzNumber setCountryCode:@64];
  [nzNumber setNationalNumber:@33316005];
  return nzNumber;
}

- (NBPhoneNumber *)usPremiumNumber {
  NBPhoneNumber *usPremiumNumber = [[NBPhoneNumber alloc] init];
  usPremiumNumber.countryCode = @1;
  usPremiumNumber.nationalNumber = @9002530000;
  return usPremiumNumber;
}

- (NBPhoneNumber *)usLocalNumber {
  // Too short, but still possible US numbers.
  NBPhoneNumber *usLocalNumber = [[NBPhoneNumber alloc] init];
  usLocalNumber.countryCode = @1;
  usLocalNumber.nationalNumber = @2530000;
  return usLocalNumber;
}

- (NBPhoneNumber *)usShortByOneNumber {
  // Too short, but still possible US numbers.
  NBPhoneNumber *usShortByOneNumber = [[NBPhoneNumber alloc] init];
  usShortByOneNumber.countryCode = @1;
  usShortByOneNumber.nationalNumber = @650253000;
  return usShortByOneNumber;
}

- (NBPhoneNumber *)usTollFreeNumber {
  NBPhoneNumber *usTollFreeNumber = [[NBPhoneNumber alloc] init];
  usTollFreeNumber.countryCode = @1;
  usTollFreeNumber.nationalNumber = @8002530000;
  return usTollFreeNumber;
}

- (NBPhoneNumber *)universalPremiumRateNumber {
  NBPhoneNumber *universalPremiumRateNumber = [[NBPhoneNumber alloc] init];
  universalPremiumRateNumber.countryCode = @979;
  universalPremiumRateNumber.nationalNumber = @123456789;
  return universalPremiumRateNumber;
}

- (NBPhoneNumber *)gbNumber {
  NBPhoneNumber *gbNumber = [[NBPhoneNumber alloc] init];
  gbNumber.countryCode = @44;
  gbNumber.nationalNumber = @2070313000;
  return gbNumber;
}

- (NBPhoneNumber *)usNumber {
  NBPhoneNumber *usNumber = [[NBPhoneNumber alloc] init];
  usNumber.countryCode = @1;
  usNumber.nationalNumber = @6502530000;
  return usNumber;
}

- (NBPhoneNumber *)deNumber {
  // Note that this is the same as the example number for DE in the metadata.
  NBPhoneNumber *deNumber = [[NBPhoneNumber alloc] init];
  deNumber.countryCode = @49;
  deNumber.nationalNumber = @30123456;
  return deNumber;
}

// Numbers to test the formatting rules from Mexico.
- (NBPhoneNumber *)mxMobile1 {
  // Note that this is the same as the example number for DE in the metadata.
  NBPhoneNumber *number = [[NBPhoneNumber alloc] init];
  number.countryCode = @52;
  number.nationalNumber = @12345678900;
  return number;
}

- (NBPhoneNumber *)mxMobile2 {
  // Note that this is the same as the example number for DE in the metadata.
  NBPhoneNumber *number = [[NBPhoneNumber alloc] init];
  number.countryCode = @52;
  number.nationalNumber = @15512345678;
  return number;
}

- (NBPhoneNumber *)mxNumber {
  NBPhoneNumber *mxNumber = [[NBPhoneNumber alloc] init];
  mxNumber.countryCode = @52;
  mxNumber.nationalNumber = @3312345678;
  return mxNumber;
}

- (NBPhoneNumber *)usTooLongNumber {
  NBPhoneNumber *usTooLongNumber = [[NBPhoneNumber alloc] init];
  usTooLongNumber.countryCode = @1;
  usTooLongNumber.nationalNumber = @65025300001;
  return usTooLongNumber;
}

- (NBPhoneNumber *)internationalTollFreeTooLongNumber {
  NBPhoneNumber *internationalTollFreeTooLongNumber = [[NBPhoneNumber alloc] init];
  internationalTollFreeTooLongNumber.countryCode = @800;
  internationalTollFreeTooLongNumber.nationalNumber = @123456789;
  return internationalTollFreeTooLongNumber;
}

- (NBPhoneNumber *)internationalTollFreeNumber {
  NBPhoneNumber *internationalTollFreeNumber = [[NBPhoneNumber alloc] init];
  internationalTollFreeNumber.countryCode = @800;
  internationalTollFreeNumber.nationalNumber = @12345678;
  return internationalTollFreeNumber;
}

- (NBPhoneNumber *)unknownCountryCodeNoRawInput {
  NBPhoneNumber *unknownCountryCodeNoRawInput = [[NBPhoneNumber alloc] init];
  unknownCountryCodeNoRawInput.countryCode = @2;
  unknownCountryCodeNoRawInput.nationalNumber = @12345;
  return unknownCountryCodeNoRawInput;
}

- (void)testForGetMetadata {
  XCTAssertNotNil([self.helper getMetadataForRegion:@"US"]);
  XCTAssertNotNil([self.helper getMetadataForRegion:@"KR"]);
  XCTAssertNil([self.helper getMetadataForRegion:nil]);
  XCTAssertNil([self.helper getMetadataForRegion:NULL]);
  XCTAssertNil([self.helper getMetadataForRegion:@""]);
  XCTAssertNotNil([self.helper getMetadataForRegion:@" AU"]);
  XCTAssertNotNil([self.helper getMetadataForRegion:@" JP        "]);
}

- (void)testNSDictionaryableKey {
  NSError *anError = nil;

  NBPhoneNumber *myNumber1 = [_aUtil parse:@"971600123456" defaultRegion:@"AE" error:&anError];
  NBPhoneNumber *myNumber2 = [_aUtil parse:@"5491187654321" defaultRegion:@"AR" error:&anError];
  NBPhoneNumber *myNumber3 = [_aUtil parse:@"12423570000" defaultRegion:@"BS" error:&anError];
  NBPhoneNumber *myNumber4 = [_aUtil parse:@"39236618300" defaultRegion:@"IT" error:&anError];
  NBPhoneNumber *myNumber5 = [_aUtil parse:@"16502530000" defaultRegion:@"US" error:&anError];

  NSMutableDictionary *dicTest = [[NSMutableDictionary alloc] init];
  [dicTest setObject:@"AE" forKey:myNumber1];
  [dicTest setObject:@"AR" forKey:myNumber2];
  [dicTest setObject:@"BS" forKey:myNumber3];
  [dicTest setObject:@"IT" forKey:myNumber4];
  [dicTest setObject:@"US" forKey:myNumber5];

  XCTAssertEqualObjects(@"AE", [dicTest objectForKey:myNumber1]);
  XCTAssertEqualObjects(@"AR", [dicTest objectForKey:myNumber2]);
  XCTAssertEqualObjects(@"BS", [dicTest objectForKey:myNumber3]);
  XCTAssertEqualObjects(@"IT", [dicTest objectForKey:myNumber4]);
  XCTAssertEqualObjects(@"US", [dicTest objectForKey:myNumber5]);
}

- (void)testGetInstanceLoadUSMetadata {
  NBPhoneMetaData *metadata = [self.helper getMetadataForRegion:@"US"];

  XCTAssertEqualObjects(@"US", metadata.codeID);
  XCTAssertEqualObjects(@1, metadata.countryCode);
  XCTAssertEqualObjects(@"011", metadata.internationalPrefix);
  XCTAssertTrue(metadata.nationalPrefix != nil);
  XCTAssertEqual(2, (int)[metadata.numberFormats count]);
  XCTAssertEqualObjects(@"(\\d{3})(\\d{3})(\\d{4})",
                        ((NBNumberFormat *)metadata.numberFormats[1]).pattern);
  XCTAssertEqualObjects(@"$1 $2 $3", ((NBNumberFormat *)metadata.numberFormats[1]).format);
  XCTAssertEqualObjects(@"[13-689]\\d{9}|2[0-35-9]\\d{8}",
                        metadata.generalDesc.nationalNumberPattern);
  XCTAssertEqualObjects(@"[13-689]\\d{9}|2[0-35-9]\\d{8}",
                        metadata.fixedLine.nationalNumberPattern);
  XCTAssertEqualObjects(@"900\\d{7}", metadata.premiumRate.nationalNumberPattern);
  // No shared-cost data is available, so its national number data should not be
  // set.
  XCTAssertFalse([metadata.sharedCost nationalNumberPattern] != nil);
}

- (void)testGetInstanceLoadDEMetadata {
  NBPhoneMetaData *metadata = [self.helper getMetadataForRegion:@"DE"];
  XCTAssertEqualObjects(@"DE", metadata.codeID);
  XCTAssertEqualObjects(@49, metadata.countryCode);
  XCTAssertEqualObjects(@"00", metadata.internationalPrefix);
  XCTAssertEqualObjects(@"0", metadata.nationalPrefix);
  XCTAssertEqual(6, (int)[metadata.numberFormats count]);
  XCTAssertEqual(1,
                 (int)[((NBNumberFormat *)metadata.numberFormats[5]).leadingDigitsPatterns count]);
  XCTAssertEqualObjects(@"900",
                        ((NBNumberFormat *)metadata.numberFormats[5]).leadingDigitsPatterns[0]);
  XCTAssertEqualObjects(@"(\\d{3})(\\d{3,4})(\\d{4})",
                        ((NBNumberFormat *)metadata.numberFormats[5]).pattern);
  XCTAssertEqualObjects(@"$1 $2 $3", ((NBNumberFormat *)metadata.numberFormats[5]).format);
  XCTAssertEqualObjects(@"(?:[24-6]\\d{2}|3[03-9]\\d|[789](?:0[2-9]|[1-9]\\d))\\d{1,8}",
                        metadata.fixedLine.nationalNumberPattern);
  XCTAssertEqualObjects(@"30123456", metadata.fixedLine.exampleNumber);
  XCTAssertEqualObjects(@"900([135]\\d{6}|9\\d{7})", metadata.premiumRate.nationalNumberPattern);
}

- (void)testGetInstanceLoadARMetadata {
  NBPhoneMetaData *metadata = [self.helper getMetadataForRegion:@"AR"];
  XCTAssertEqualObjects(@"AR", metadata.codeID);
  XCTAssertEqualObjects(@54, metadata.countryCode);
  XCTAssertEqualObjects(@"00", metadata.internationalPrefix);
  XCTAssertEqualObjects(@"0", metadata.nationalPrefix);
  XCTAssertEqualObjects(@"0(?:(11|343|3715)15)?", metadata.nationalPrefixForParsing);
  XCTAssertEqualObjects(@"9$1", metadata.nationalPrefixTransformRule);
  XCTAssertEqualObjects(@"$2 15 $3-$4", ((NBNumberFormat *)metadata.numberFormats[2]).format);
  XCTAssertEqualObjects(@"(\\d)(\\d{4})(\\d{2})(\\d{4})",
                        ((NBNumberFormat *)metadata.numberFormats[3]).pattern);
  XCTAssertEqualObjects(@"(\\d)(\\d{4})(\\d{2})(\\d{4})",
                        ((NBNumberFormat *)metadata.intlNumberFormats[3]).pattern);
  XCTAssertEqualObjects(@"$1 $2 $3 $4", ((NBNumberFormat *)metadata.intlNumberFormats[3]).format);
}

- (void)testGetInstanceLoadInternationalTollFreeMetadata {
  NBPhoneMetaData *metadata = [self.helper getMetadataForNonGeographicalRegion:@800];
  XCTAssertEqualObjects(@"001", metadata.codeID);
  XCTAssertEqualObjects(@800, metadata.countryCode);
  XCTAssertEqualObjects(@"$1 $2", ((NBNumberFormat *)metadata.numberFormats[0]).format);
  XCTAssertEqualObjects(@"(\\d{4})(\\d{4})", ((NBNumberFormat *)metadata.numberFormats[0]).pattern);
  XCTAssertEqual(0, metadata.generalDesc.possibleLengthLocalOnly.count);
  XCTAssertEqual(1, metadata.generalDesc.possibleLength.count);
  XCTAssertEqualObjects(@"12345678", metadata.tollFree.exampleNumber);
}

- (void)testIsNumberGeographical {
  // Bahamas, mobile phone number.
  XCTAssertFalse([_aUtil isNumberGeographical:self.bsMobile]);
  // Australian fixed line number.
  XCTAssertTrue([_aUtil isNumberGeographical:self.auNumber]);
  // International toll free number.
  XCTAssertFalse([_aUtil isNumberGeographical:self.internationalTollFreeNumber]);
  // We test that mobile phone numbers in relevant regions are indeed considered
  // geographical.
  // Argentina, mobile phone number.
  XCTAssertTrue([_aUtil isNumberGeographical:self.arMobile]);
  // Mexico, mobile phone number.
  XCTAssertTrue([_aUtil isNumberGeographical:[self mxMobile1]]);
  // Mexico, another mobile phone number.
  XCTAssertTrue([_aUtil isNumberGeographical:[self mxMobile2]]);
}

- (void)testgetLengthOfGeographicalAreaCode {
  // Google MTV, which has area code '650'.
  XCTAssertEqual(3, [_aUtil getLengthOfGeographicalAreaCode:self.usNumber]);

  // A North America toll-free number, which has no area code.
  XCTAssertEqual(0, [_aUtil getLengthOfGeographicalAreaCode:self.usTollFreeNumber]);

  // Google London, which has area code '20'.
  XCTAssertEqual(2, [_aUtil getLengthOfGeographicalAreaCode:self.gbNumber]);

  // A UK mobile phone, which has no area code.
  XCTAssertEqual(0, [_aUtil getLengthOfGeographicalAreaCode:self.gbMobile]);

  // Google Buenos Aires, which has area code '11'.
  XCTAssertEqual(2, [_aUtil getLengthOfGeographicalAreaCode:self.arNumber]);

  // Google Sydney, which has area code '2'.
  XCTAssertEqual(1, [_aUtil getLengthOfGeographicalAreaCode:self.auNumber]);

  // Italian numbers - there is no national prefix, but it still has an area
  // code.
  XCTAssertEqual(2, [_aUtil getLengthOfGeographicalAreaCode:self.itNumber]);

  // Google Singapore. Singapore has no area code and no national prefix.
  XCTAssertEqual(0, [_aUtil getLengthOfGeographicalAreaCode:self.sgNumber]);

  // An invalid US number (1 digit shorter), which has no area code.
  XCTAssertEqual(0, [_aUtil getLengthOfGeographicalAreaCode:self.usShortByOneNumber]);

  // An international toll free number, which has no area code.
  XCTAssertEqual(0, [_aUtil getLengthOfGeographicalAreaCode:self.internationalTollFreeNumber]);
}

- (void)testGetLengthOfNationalDestinationCode {
  // Google MTV, which has national destination code (NDC) '650'.
  XCTAssertEqual(3, [_aUtil getLengthOfNationalDestinationCode:self.usNumber]);

  // A North America toll-free number, which has NDC '800'.
  XCTAssertEqual(3, [_aUtil getLengthOfNationalDestinationCode:self.usTollFreeNumber]);

  // Google London, which has NDC '20'.
  XCTAssertEqual(2, [_aUtil getLengthOfNationalDestinationCode:self.gbNumber]);

  // A UK mobile phone, which has NDC '7912'.
  XCTAssertEqual(4, [_aUtil getLengthOfNationalDestinationCode:self.gbMobile]);

  // Google Buenos Aires, which has NDC '11'.
  XCTAssertEqual(2, [_aUtil getLengthOfNationalDestinationCode:self.arNumber]);

  // An Argentinian mobile which has NDC '911'.
  XCTAssertEqual(3, [_aUtil getLengthOfNationalDestinationCode:self.arMobile]);

  // Google Sydney, which has NDC '2'.
  XCTAssertEqual(1, [_aUtil getLengthOfNationalDestinationCode:self.auNumber]);

  // Google Singapore, which has NDC '6521'.
  XCTAssertEqual(4, [_aUtil getLengthOfNationalDestinationCode:self.sgNumber]);

  // An invalid US number (1 digit shorter), which has no NDC.
  XCTAssertEqual(0, [_aUtil getLengthOfNationalDestinationCode:self.usShortByOneNumber]);

  // A number containing an invalid country calling code, which shouldn't have
  // any NDC.

  NBPhoneNumber *number = [[NBPhoneNumber alloc] init];
  [number setCountryCode:@123];
  [number setNationalNumber:@6502530000];
  XCTAssertEqual(0, [_aUtil getLengthOfNationalDestinationCode:number]);

  // An international toll free number, which has NDC '1234'.
  XCTAssertEqual(4, [_aUtil getLengthOfNationalDestinationCode:self.internationalTollFreeNumber]);
}

- (void)testGetSupportedRegions {
  XCTAssertTrue([_aUtil getSupportedRegions].count > 0);
  XCTAssertTrue([[_aUtil getSupportedRegions] containsObject:@"US"]);
  XCTAssertFalse([[_aUtil getSupportedRegions] containsObject:@"UN001"]);
  XCTAssertFalse([[_aUtil getSupportedRegions] containsObject:@"800"]);
}

- (void)testGetNationalSignificantNumber {
  XCTAssertEqualObjects(@"6502530000", [_aUtil getNationalSignificantNumber:self.usNumber]);

  // An Italian mobile number.
  XCTAssertEqualObjects(@"345678901", [_aUtil getNationalSignificantNumber:self.itMobile]);

  // An Italian fixed line number.
  XCTAssertEqualObjects(@"0236618300", [_aUtil getNationalSignificantNumber:self.itNumber]);

  XCTAssertEqualObjects(@"12345678",
                        [_aUtil getNationalSignificantNumber:self.internationalTollFreeNumber]);
}

- (void)testGetExampleNumber {
  XCTAssertTrue([self.deNumber isEqual:[_aUtil getExampleNumber:@"DE" error:nil]]);

  XCTAssertTrue([self.deNumber isEqual:[_aUtil getExampleNumberForType:@"DE"
                                                                  type:NBEPhoneNumberTypeFIXED_LINE
                                                                 error:nil]]);
  XCTAssertTrue(
      [self.deNumber isEqual:[_aUtil getExampleNumberForType:@"DE"
                                                        type:NBEPhoneNumberTypeFIXED_LINE_OR_MOBILE
                                                       error:nil]]);
  // For the US, the example number is placed under general description, and
  // hence should be used for both fixed line and mobile, so neither of these
  // should return nil.
  XCTAssertNotNil([_aUtil getExampleNumberForType:@"US"
                                             type:NBEPhoneNumberTypeFIXED_LINE
                                            error:nil]);
  XCTAssertNotNil([_aUtil getExampleNumberForType:@"US" type:NBEPhoneNumberTypeMOBILE error:nil]);
  // CS is an invalid region, so we have no data for it.
  XCTAssertNil([_aUtil getExampleNumberForType:@"CS" type:NBEPhoneNumberTypeMOBILE error:nil]);
  // RegionCode 001 is reserved for supporting non-geographical country calling
  // code. We don't support getting an example number for it with this method.
  XCTAssertNil([_aUtil getExampleNumber:@"001" error:nil]);
}

- (void)testexampleNumberForNonGeoEntity {
  XCTAssertTrue([self.internationalTollFreeNumber
      isEqual:[_aUtil getExampleNumberForNonGeoEntity:@800 error:nil]]);
  XCTAssertTrue([self.universalPremiumRateNumber
      isEqual:[_aUtil getExampleNumberForNonGeoEntity:@979 error:nil]]);
}

- (void)testConvertAlphaCharactersInNumber {
  NSString *input = @"1800-ABC-DEF";
  // Alpha chars are converted to digits; everything else is left untouched.

  NSString *expectedOutput = @"1800-222-333";
  XCTAssertEqualObjects(expectedOutput, [_aUtil convertAlphaCharactersInNumber:input]);
}

- (void)testNormaliseRemovePunctuation {
  NSString *inputNumber = @"034-56&+#2\u00AD34";
  NSString *expectedOutput = @"03456234";
  XCTAssertEqualObjects(expectedOutput, [_aUtil normalize:inputNumber],
                        @"Conversion did not correctly remove punctuation");
}

- (void)testNormaliseReplaceAlphaCharacters {
  NSString *inputNumber = @"034-I-am-HUNGRY";
  NSString *expectedOutput = @"034426486479";
  XCTAssertEqualObjects(expectedOutput, [_aUtil normalize:inputNumber],
                        @"Conversion did not correctly replace alpha characters");
}

- (void)testNormaliseOtherDigits {
  NSString *inputNumber = @"\uFF125\u0665";
  NSString *expectedOutput = @"255";
  XCTAssertEqualObjects(expectedOutput, [_aUtil normalize:inputNumber],
                        @"Conversion did not correctly replace non-latin digits");
  // Eastern-Arabic digits.
  inputNumber = @"\u06F52\u06F0";
  expectedOutput = @"520";
  XCTAssertEqualObjects(expectedOutput, [_aUtil normalize:inputNumber],
                        @"Conversion did not correctly replace non-latin digits");
}

- (void)testNormaliseStripAlphaCharacters {
  NSString *inputNumber = @"034-56&+a#234";
  NSString *expectedOutput = @"03456234";
  XCTAssertEqualObjects(expectedOutput, [_aUtil normalizeDigitsOnly:inputNumber],
                        @"Conversion did not correctly remove alpha character");
}

- (void)testNormalizeStripNonDiallableCharacters {
  NSString *inputNumber = @"03*4-56&+1a#234";
  NSString *expectedOutput = @"03*456+1#234";
  XCTAssertEqualObjects(expectedOutput, [_aUtil normalizeDiallableCharsOnly:inputNumber],
                        @"Conversion did not correctly remove non-diallable characters");
}

- (void)testFormatUSNumber {
  XCTAssertEqualObjects(@"650 253 0000", [_aUtil format:self.usNumber
                                             numberFormat:NBEPhoneNumberFormatNATIONAL]);
  XCTAssertEqualObjects(@"+1 650 253 0000", [_aUtil format:self.usNumber
                                                numberFormat:NBEPhoneNumberFormatINTERNATIONAL]);
  XCTAssertEqualObjects(@"800 253 0000", [_aUtil format:self.usTollFreeNumber
                                             numberFormat:NBEPhoneNumberFormatNATIONAL]);
  XCTAssertEqualObjects(@"+1 800 253 0000", [_aUtil format:self.usTollFreeNumber
                                                numberFormat:NBEPhoneNumberFormatINTERNATIONAL]);
  XCTAssertEqualObjects(@"900 253 0000", [_aUtil format:self.usPremiumNumber
                                             numberFormat:NBEPhoneNumberFormatNATIONAL]);
  XCTAssertEqualObjects(@"+1 900 253 0000", [_aUtil format:self.usPremiumNumber
                                                numberFormat:NBEPhoneNumberFormatINTERNATIONAL]);
  XCTAssertEqualObjects(@"tel:+1-900-253-0000", [_aUtil format:self.usPremiumNumber
                                                    numberFormat:NBEPhoneNumberFormatRFC3966]);
  // Numbers with all zeros in the national number part will be formatted by
  // using the raw_input if that is available no matter which format is
  // specified.
  NBPhoneNumber *usSpoofWithRawInput = [[NBPhoneNumber alloc] init];
  usSpoofWithRawInput.countryCode = @1;
  usSpoofWithRawInput.nationalNumber = @0;
  usSpoofWithRawInput.rawInput = @"000-000-0000";

  XCTAssertEqualObjects(@"000-000-0000", [_aUtil format:usSpoofWithRawInput
                                             numberFormat:NBEPhoneNumberFormatNATIONAL]);

  NBPhoneNumber *usSpoof = [[NBPhoneNumber alloc] init];
  usSpoof.countryCode = @1;
  usSpoof.nationalNumber = @0;
  XCTAssertEqualObjects(@"0", [_aUtil format:usSpoof numberFormat:NBEPhoneNumberFormatNATIONAL]);
}

- (void)testFormatBSNumber {
  XCTAssertEqualObjects(@"242 365 1234", [_aUtil format:self.bsNumber
                                             numberFormat:NBEPhoneNumberFormatNATIONAL]);
  XCTAssertEqualObjects(@"+1 242 365 1234", [_aUtil format:self.bsNumber
                                                numberFormat:NBEPhoneNumberFormatINTERNATIONAL]);
}

- (void)testFormatGBNumber {
  NBPhoneNumber *gbNumber = self.gbNumber;
  XCTAssertEqualObjects(@"(020) 7031 3000", [_aUtil format:gbNumber
                                                numberFormat:NBEPhoneNumberFormatNATIONAL]);
  XCTAssertEqualObjects(@"+44 20 7031 3000", [_aUtil format:gbNumber
                                                 numberFormat:NBEPhoneNumberFormatINTERNATIONAL]);
  XCTAssertEqualObjects(@"(07912) 345 678", [_aUtil format:self.gbMobile
                                                numberFormat:NBEPhoneNumberFormatNATIONAL]);
  XCTAssertEqualObjects(@"+44 7912 345 678", [_aUtil format:self.gbMobile
                                                 numberFormat:NBEPhoneNumberFormatINTERNATIONAL]);
}

- (void)testFormatDENumber {
  id deNumber = [[NBPhoneNumber alloc] init];
  [deNumber setCountryCode:@49];
  [deNumber setNationalNumber:@301234];
  XCTAssertEqualObjects(@"030/1234", [_aUtil format:deNumber
                                         numberFormat:NBEPhoneNumberFormatNATIONAL]);
  XCTAssertEqualObjects(@"+49 30/1234", [_aUtil format:deNumber
                                            numberFormat:NBEPhoneNumberFormatINTERNATIONAL]);
  XCTAssertEqualObjects(@"tel:+49-30-1234", [_aUtil format:deNumber
                                                numberFormat:NBEPhoneNumberFormatRFC3966]);

  deNumber = [[NBPhoneNumber alloc] init];
  [deNumber setCountryCode:@49];
  [deNumber setNationalNumber:@291123];
  XCTAssertEqualObjects(@"0291 123", [_aUtil format:deNumber
                                         numberFormat:NBEPhoneNumberFormatNATIONAL]);
  XCTAssertEqualObjects(@"+49 291 123", [_aUtil format:deNumber
                                            numberFormat:NBEPhoneNumberFormatINTERNATIONAL]);

  deNumber = [[NBPhoneNumber alloc] init];
  [deNumber setCountryCode:@49];
  [deNumber setNationalNumber:@29112345678];
  XCTAssertEqualObjects(@"0291 12345678", [_aUtil format:deNumber
                                              numberFormat:NBEPhoneNumberFormatNATIONAL]);
  XCTAssertEqualObjects(@"+49 291 12345678", [_aUtil format:deNumber
                                                 numberFormat:NBEPhoneNumberFormatINTERNATIONAL]);

  deNumber = [[NBPhoneNumber alloc] init];
  [deNumber setCountryCode:@49];
  [deNumber setNationalNumber:@912312345];
  XCTAssertEqualObjects(@"09123 12345", [_aUtil format:deNumber
                                            numberFormat:NBEPhoneNumberFormatNATIONAL]);
  XCTAssertEqualObjects(@"+49 9123 12345", [_aUtil format:deNumber
                                               numberFormat:NBEPhoneNumberFormatINTERNATIONAL]);

  deNumber = [[NBPhoneNumber alloc] init];
  [deNumber setCountryCode:@49];
  [deNumber setNationalNumber:@80212345];
  XCTAssertEqualObjects(@"08021 2345", [_aUtil format:deNumber
                                           numberFormat:NBEPhoneNumberFormatNATIONAL]);
  XCTAssertEqualObjects(@"+49 8021 2345", [_aUtil format:deNumber
                                              numberFormat:NBEPhoneNumberFormatINTERNATIONAL]);

  // Note this number is correctly formatted without national prefix. Most of
  // the numbers that are treated as invalid numbers by the library are short
  // numbers, and they are usually not dialed with national prefix.
  XCTAssertEqualObjects(@"1234", [_aUtil format:self.deShortNumber
                                     numberFormat:NBEPhoneNumberFormatNATIONAL]);
  XCTAssertEqualObjects(@"+49 1234", [_aUtil format:self.deShortNumber
                                         numberFormat:NBEPhoneNumberFormatINTERNATIONAL]);

  deNumber = [[NBPhoneNumber alloc] init];
  [deNumber setCountryCode:@49];
  [deNumber setNationalNumber:@41341234];
  XCTAssertEqualObjects(@"04134 1234", [_aUtil format:deNumber
                                           numberFormat:NBEPhoneNumberFormatNATIONAL]);
}

- (void)testFormatITNumber {
  XCTAssertEqualObjects(@"02 3661 8300", [_aUtil format:self.itNumber
                                             numberFormat:NBEPhoneNumberFormatNATIONAL]);
  XCTAssertEqualObjects(@"+39 02 3661 8300", [_aUtil format:self.itNumber
                                                 numberFormat:NBEPhoneNumberFormatINTERNATIONAL]);
  XCTAssertEqualObjects(@"+390236618300", [_aUtil format:self.itNumber
                                              numberFormat:NBEPhoneNumberFormatE164]);
  XCTAssertEqualObjects(@"345 678 901", [_aUtil format:self.itMobile
                                            numberFormat:NBEPhoneNumberFormatNATIONAL]);
  XCTAssertEqualObjects(@"+39 345 678 901", [_aUtil format:self.itMobile
                                                numberFormat:NBEPhoneNumberFormatINTERNATIONAL]);
  XCTAssertEqualObjects(@"+39345678901", [_aUtil format:self.itMobile
                                             numberFormat:NBEPhoneNumberFormatE164]);
}

- (void)testFormatAUNumber {
  XCTAssertEqualObjects(@"02 3661 8300", [_aUtil format:self.auNumber
                                             numberFormat:NBEPhoneNumberFormatNATIONAL]);
  XCTAssertEqualObjects(@"+61 2 3661 8300", [_aUtil format:self.auNumber
                                                numberFormat:NBEPhoneNumberFormatINTERNATIONAL]);
  XCTAssertEqualObjects(@"+61236618300", [_aUtil format:self.auNumber
                                             numberFormat:NBEPhoneNumberFormatE164]);

  id auNumber = [[NBPhoneNumber alloc] init];
  [auNumber setCountryCode:@61];
  [auNumber setNationalNumber:@1800123456];
  XCTAssertEqualObjects(@"1800 123 456", [_aUtil format:auNumber
                                             numberFormat:NBEPhoneNumberFormatNATIONAL]);
  XCTAssertEqualObjects(@"+61 1800 123 456", [_aUtil format:auNumber
                                                 numberFormat:NBEPhoneNumberFormatINTERNATIONAL]);
  XCTAssertEqualObjects(@"+611800123456", [_aUtil format:auNumber
                                              numberFormat:NBEPhoneNumberFormatE164]);
}

- (void)testFormatARNumber {
  XCTAssertEqualObjects(@"011 8765-4321", [_aUtil format:self.arNumber
                                              numberFormat:NBEPhoneNumberFormatNATIONAL]);
  XCTAssertEqualObjects(@"+54 11 8765-4321", [_aUtil format:self.arNumber
                                                 numberFormat:NBEPhoneNumberFormatINTERNATIONAL]);
  XCTAssertEqualObjects(@"+541187654321", [_aUtil format:self.arNumber
                                              numberFormat:NBEPhoneNumberFormatE164]);
  XCTAssertEqualObjects(@"011 15 8765-4321", [_aUtil format:self.arMobile
                                                 numberFormat:NBEPhoneNumberFormatNATIONAL]);
  XCTAssertEqualObjects(@"+54 9 11 8765 4321", [_aUtil format:self.arMobile
                                                   numberFormat:NBEPhoneNumberFormatINTERNATIONAL]);
  XCTAssertEqualObjects(@"+5491187654321", [_aUtil format:self.arMobile
                                               numberFormat:NBEPhoneNumberFormatE164]);
}

- (void)testFormatMXNumber {
  NBPhoneNumber *mxMobile1 = [[NBPhoneNumber alloc] init];
  mxMobile1.countryCode = @52;
  mxMobile1.nationalNumber = @12345678900;
  XCTAssertEqualObjects(@"045 234 567 8900", [_aUtil format:mxMobile1
                                                 numberFormat:NBEPhoneNumberFormatNATIONAL]);
  XCTAssertEqualObjects(@"+52 1 234 567 8900", [_aUtil format:mxMobile1
                                                   numberFormat:NBEPhoneNumberFormatINTERNATIONAL]);
  XCTAssertEqualObjects(@"+5212345678900", [_aUtil format:mxMobile1
                                               numberFormat:NBEPhoneNumberFormatE164]);
  NBPhoneNumber *mxMobile2 = [[NBPhoneNumber alloc] init];
  mxMobile2.countryCode = @52;
  mxMobile2.nationalNumber = @15512345678;
  XCTAssertEqualObjects(@"045 55 1234 5678", [_aUtil format:mxMobile2
                                                 numberFormat:NBEPhoneNumberFormatNATIONAL]);
  XCTAssertEqualObjects(@"+52 1 55 1234 5678", [_aUtil format:mxMobile2
                                                   numberFormat:NBEPhoneNumberFormatINTERNATIONAL]);
  XCTAssertEqualObjects(@"+5215512345678", [_aUtil format:mxMobile2
                                               numberFormat:NBEPhoneNumberFormatE164]);
  XCTAssertEqualObjects(@"01 33 1234 5678", [_aUtil format:self.mxNumber
                                                numberFormat:NBEPhoneNumberFormatNATIONAL]);
  XCTAssertEqualObjects(@"+52 33 1234 5678", [_aUtil format:self.mxNumber
                                                 numberFormat:NBEPhoneNumberFormatINTERNATIONAL]);
  XCTAssertEqualObjects(@"+523312345678", [_aUtil format:self.mxNumber
                                              numberFormat:NBEPhoneNumberFormatE164]);
  NBPhoneNumber *mxNumber2 = [[NBPhoneNumber alloc] init];
  mxNumber2.countryCode = @52;
  mxNumber2.nationalNumber = @8211234567;
  XCTAssertEqualObjects(@"01 821 123 4567", [_aUtil format:mxNumber2
                                                numberFormat:NBEPhoneNumberFormatNATIONAL]);
  XCTAssertEqualObjects(@"+52 821 123 4567", [_aUtil format:mxNumber2
                                                 numberFormat:NBEPhoneNumberFormatINTERNATIONAL]);
  XCTAssertEqualObjects(@"+528211234567", [_aUtil format:mxNumber2
                                              numberFormat:NBEPhoneNumberFormatE164]);
}

- (void)testFormatOutOfCountryCallingNumber {
  XCTAssertEqualObjects(@"00 1 900 253 0000",
                        [_aUtil formatOutOfCountryCallingNumber:self.usPremiumNumber
                                              regionCallingFrom:@"DE"]);
  XCTAssertEqualObjects(@"1 650 253 0000", [_aUtil formatOutOfCountryCallingNumber:self.usNumber
                                                                 regionCallingFrom:@"BS"]);
  XCTAssertEqualObjects(@"00 1 650 253 0000", [_aUtil formatOutOfCountryCallingNumber:self.usNumber
                                                                    regionCallingFrom:@"PL"]);
  XCTAssertEqualObjects(@"011 44 7912 345 678",
                        [_aUtil formatOutOfCountryCallingNumber:self.gbMobile
                                              regionCallingFrom:@"US"]);
  XCTAssertEqualObjects(@"00 49 1234", [_aUtil formatOutOfCountryCallingNumber:self.deShortNumber
                                                             regionCallingFrom:@"GB"]);
  // Note this number is correctly formatted without national prefix. Most of
  // the numbers that are treated as invalid numbers by the library are short
  // numbers, and they are usually not dialed with national prefix.
  XCTAssertEqualObjects(@"1234", [_aUtil formatOutOfCountryCallingNumber:self.deShortNumber
                                                       regionCallingFrom:@"DE"]);
  XCTAssertEqualObjects(@"011 39 02 3661 8300",
                        [_aUtil formatOutOfCountryCallingNumber:self.itNumber
                                              regionCallingFrom:@"US"]);
  XCTAssertEqualObjects(@"02 3661 8300", [_aUtil formatOutOfCountryCallingNumber:self.itNumber
                                                               regionCallingFrom:@"IT"]);
  XCTAssertEqualObjects(@"+39 02 3661 8300", [_aUtil formatOutOfCountryCallingNumber:self.itNumber
                                                                   regionCallingFrom:@"SG"]);
  XCTAssertEqualObjects(@"6521 8000", [_aUtil formatOutOfCountryCallingNumber:self.sgNumber
                                                            regionCallingFrom:@"SG"]);
  XCTAssertEqualObjects(@"011 54 9 11 8765 4321",
                        [_aUtil formatOutOfCountryCallingNumber:self.arMobile
                                              regionCallingFrom:@"US"]);
  XCTAssertEqualObjects(@"011 800 1234 5678",
                        [_aUtil formatOutOfCountryCallingNumber:self.internationalTollFreeNumber
                                              regionCallingFrom:@"US"]);

  id arNumberWithExtn = self.arMobile;
  [arNumberWithExtn setExtension:@"1234"];
  XCTAssertEqualObjects(@"011 54 9 11 8765 4321 ext. 1234",
                        [_aUtil formatOutOfCountryCallingNumber:arNumberWithExtn
                                              regionCallingFrom:@"US"]);
  XCTAssertEqualObjects(@"0011 54 9 11 8765 4321 ext. 1234",
                        [_aUtil formatOutOfCountryCallingNumber:arNumberWithExtn
                                              regionCallingFrom:@"AU"]);
  XCTAssertEqualObjects(@"011 15 8765-4321 ext. 1234",
                        [_aUtil formatOutOfCountryCallingNumber:arNumberWithExtn
                                              regionCallingFrom:@"AR"]);
}

- (void)testFormatOutOfCountryWithInvalidRegion {
  // AQ/Antarctica isn't a valid region code for phone number formatting,
  // so this falls back to intl formatting.
  XCTAssertEqualObjects(@"+1 650 253 0000", [_aUtil formatOutOfCountryCallingNumber:self.usNumber
                                                                  regionCallingFrom:@"AQ"]);
  // For region code 001, the out-of-country format always turns into the
  // international format.
  XCTAssertEqualObjects(@"+1 650 253 0000", [_aUtil formatOutOfCountryCallingNumber:self.usNumber
                                                                  regionCallingFrom:@"001"]);
}

- (void)testFormatOutOfCountryWithPreferredIntlPrefix {
  // This should use 0011, since that is the preferred international prefix
  // (both 0011 and 0012 are accepted as possible international prefixes in our
  // test metadta.)
  XCTAssertEqualObjects(@"0011 39 02 3661 8300",
                        [_aUtil formatOutOfCountryCallingNumber:self.itNumber
                                              regionCallingFrom:@"AU"]);
}

- (void)testFormatOutOfCountryKeepingAlphaChars {
  id alphaNumericNumber = [[NBPhoneNumber alloc] init];
  [alphaNumericNumber setCountryCode:@1];
  [alphaNumericNumber setNationalNumber:@8007493524];
  [alphaNumericNumber setRawInput:@"1800 six-flag"];
  XCTAssertEqualObjects(@"0011 1 800 SIX-FLAG",
                        [_aUtil formatOutOfCountryKeepingAlphaChars:alphaNumericNumber
                                                  regionCallingFrom:@"AU"]);

  [alphaNumericNumber setRawInput:@"1-800-SIX-flag"];
  XCTAssertEqualObjects(@"0011 1 800-SIX-FLAG",
                        [_aUtil formatOutOfCountryKeepingAlphaChars:alphaNumericNumber
                                                  regionCallingFrom:@"AU"]);

  [alphaNumericNumber setRawInput:@"Call us from UK: 00 1 800 SIX-flag"];
  XCTAssertEqualObjects(@"0011 1 800 SIX-FLAG",
                        [_aUtil formatOutOfCountryKeepingAlphaChars:alphaNumericNumber
                                                  regionCallingFrom:@"AU"]);

  [alphaNumericNumber setRawInput:@"800 SIX-flag"];
  XCTAssertEqualObjects(@"0011 1 800 SIX-FLAG",
                        [_aUtil formatOutOfCountryKeepingAlphaChars:alphaNumericNumber
                                                  regionCallingFrom:@"AU"]);

  // Formatting from within the NANPA region.
  XCTAssertEqualObjects(@"1 800 SIX-FLAG",
                        [_aUtil formatOutOfCountryKeepingAlphaChars:alphaNumericNumber
                                                  regionCallingFrom:@"US"]);
  XCTAssertEqualObjects(@"1 800 SIX-FLAG",
                        [_aUtil formatOutOfCountryKeepingAlphaChars:alphaNumericNumber
                                                  regionCallingFrom:@"BS"]);

  // Testing that if the raw input doesn't exist, it is formatted using
  // formatOutOfCountryCallingNumber.
  [alphaNumericNumber setRawInput:nil];
  XCTAssertEqualObjects(@"00 1 800 749 3524",
                        [_aUtil formatOutOfCountryKeepingAlphaChars:alphaNumericNumber
                                                  regionCallingFrom:@"DE"]);

  // Testing AU alpha number formatted from Australia.
  [alphaNumericNumber setCountryCode:@61];
  [alphaNumericNumber setNationalNumber:@827493524];
  [alphaNumericNumber setRawInput:@"+61 82749-FLAG"];
  // This number should have the national prefix fixed.
  XCTAssertEqualObjects(@"082749-FLAG",
                        [_aUtil formatOutOfCountryKeepingAlphaChars:alphaNumericNumber
                                                  regionCallingFrom:@"AU"]);

  [alphaNumericNumber setRawInput:@"082749-FLAG"];
  XCTAssertEqualObjects(@"082749-FLAG",
                        [_aUtil formatOutOfCountryKeepingAlphaChars:alphaNumericNumber
                                                  regionCallingFrom:@"AU"]);

  [alphaNumericNumber setNationalNumber:@18007493524];
  [alphaNumericNumber setRawInput:@"1-800-SIX-flag"];
  // This number should not have the national prefix prefixed, in accordance
  // with the override for this specific formatting rule.
  XCTAssertEqualObjects(@"1-800-SIX-FLAG",
                        [_aUtil formatOutOfCountryKeepingAlphaChars:alphaNumericNumber
                                                  regionCallingFrom:@"AU"]);

  // The metadata should not be permanently changed, since we copied it before
  // modifying patterns. Here we check this.
  [alphaNumericNumber setNationalNumber:@1800749352];
  XCTAssertEqualObjects(@"1800 749 352", [_aUtil formatOutOfCountryCallingNumber:alphaNumericNumber
                                                               regionCallingFrom:@"AU"]);

  // Testing a region with multiple international prefixes.
  XCTAssertEqualObjects(@"+61 1-800-SIX-FLAG",
                        [_aUtil formatOutOfCountryKeepingAlphaChars:alphaNumericNumber
                                                  regionCallingFrom:@"SG"]);
  // Testing the case of calling from a non-supported region.
  XCTAssertEqualObjects(@"+61 1-800-SIX-FLAG",
                        [_aUtil formatOutOfCountryKeepingAlphaChars:alphaNumericNumber
                                                  regionCallingFrom:@"AQ"]);

  // Testing the case with an invalid country calling code.
  [alphaNumericNumber setCountryCode:0];
  [alphaNumericNumber setNationalNumber:@18007493524];
  [alphaNumericNumber setRawInput:@"1-800-SIX-flag"];
  // Uses the raw input only.
  XCTAssertEqualObjects(@"1-800-SIX-flag",
                        [_aUtil formatOutOfCountryKeepingAlphaChars:alphaNumericNumber
                                                  regionCallingFrom:@"DE"]);

  // Testing the case of an invalid alpha number.
  [alphaNumericNumber setCountryCode:@1];
  [alphaNumericNumber setNationalNumber:@80749];
  [alphaNumericNumber setRawInput:@"180-SIX"];
  // No country-code stripping can be done.
  XCTAssertEqualObjects(@"00 1 180-SIX",
                        [_aUtil formatOutOfCountryKeepingAlphaChars:alphaNumericNumber
                                                  regionCallingFrom:@"DE"]);

  // Testing the case of calling from a non-supported region.
  [alphaNumericNumber setCountryCode:@1];
  [alphaNumericNumber setNationalNumber:@80749];
  [alphaNumericNumber setRawInput:@"180-SIX"];
  // No country-code stripping can be done since the number is invalid.
  XCTAssertEqualObjects(@"+1 180-SIX",
                        [_aUtil formatOutOfCountryKeepingAlphaChars:alphaNumericNumber
                                                  regionCallingFrom:@"AQ"]);
}

- (void)testFormatWithCarrierCod {
  // We only support this for AR in our test metadata, and only for mobile
  // numbers starting with certain values.

  NBPhoneNumber *arMobile = [[NBPhoneNumber alloc] init];
  [arMobile setCountryCode:@54];
  [arMobile setNationalNumber:@92234654321];
  XCTAssertEqualObjects(@"02234 65-4321", [_aUtil format:arMobile
                                              numberFormat:NBEPhoneNumberFormatNATIONAL]);
  // Here we force 14 as the carrier code.
  XCTAssertEqualObjects(@"02234 14 65-4321", [_aUtil formatNationalNumberWithCarrierCode:arMobile
                                                                             carrierCode:@"14"]);
  // Here we force the number to be shown with no carrier code.
  XCTAssertEqualObjects(@"02234 65-4321", [_aUtil formatNationalNumberWithCarrierCode:arMobile
                                                                          carrierCode:@""]);
  // Here the international rule is used, so no carrier code should be present.
  XCTAssertEqualObjects(@"+5492234654321", [_aUtil format:arMobile
                                               numberFormat:NBEPhoneNumberFormatE164]);
  // We don't support this for the US so there should be no change.
  XCTAssertEqualObjects(@"650 253 0000", [_aUtil formatNationalNumberWithCarrierCode:self.usNumber
                                                                         carrierCode:@"15"]);
  // Invalid country code should just get the NSN.
  XCTAssertEqualObjects(
      @"12345", [_aUtil formatNationalNumberWithCarrierCode:self.unknownCountryCodeNoRawInput
                                                carrierCode:@"89"]);
}

- (void)testFormatWithPreferredCarrierCode {
  // We only support this for AR in our test metadata.

  NBPhoneNumber *arNumber = [[NBPhoneNumber alloc] init];
  [arNumber setCountryCode:@54];
  [arNumber setNationalNumber:@91234125678];
  // Test formatting with no preferred carrier code stored in the number itself.
  XCTAssertEqualObjects(@"01234 15 12-5678",
                        [_aUtil formatNationalNumberWithPreferredCarrierCode:arNumber
                                                         fallbackCarrierCode:@"15"]);
  XCTAssertEqualObjects(@"01234 12-5678",
                        [_aUtil formatNationalNumberWithPreferredCarrierCode:arNumber
                                                         fallbackCarrierCode:@""]);
  // Test formatting with preferred carrier code present.
  [arNumber setPreferredDomesticCarrierCode:@"19"];
  XCTAssertEqualObjects(@"01234 12-5678", [_aUtil format:arNumber
                                              numberFormat:NBEPhoneNumberFormatNATIONAL]);
  XCTAssertEqualObjects(@"01234 19 12-5678",
                        [_aUtil formatNationalNumberWithPreferredCarrierCode:arNumber
                                                         fallbackCarrierCode:@"15"]);
  XCTAssertEqualObjects(@"01234 19 12-5678",
                        [_aUtil formatNationalNumberWithPreferredCarrierCode:arNumber
                                                         fallbackCarrierCode:@""]);
  // When the preferred_domestic_carrier_code is present (even when it contains
  // an empty string), use it instead of the default carrier code passed in.
  [arNumber setPreferredDomesticCarrierCode:@""];
  XCTAssertEqualObjects(@"01234 12-5678",
                        [_aUtil formatNationalNumberWithPreferredCarrierCode:arNumber
                                                         fallbackCarrierCode:@"15"]);
  // We don't support this for the US so there should be no change.

  NBPhoneNumber *usNumber = [[NBPhoneNumber alloc] init];
  [usNumber setCountryCode:@1];
  [usNumber setNationalNumber:@4241231234];
  [usNumber setPreferredDomesticCarrierCode:@"99"];
  XCTAssertEqualObjects(@"424 123 1234", [_aUtil format:usNumber
                                             numberFormat:NBEPhoneNumberFormatNATIONAL]);
  XCTAssertEqualObjects(@"424 123 1234",
                        [_aUtil formatNationalNumberWithPreferredCarrierCode:usNumber
                                                         fallbackCarrierCode:@"15"]);
}

- (void)testFormatNumberForMobileDialing {
  // Numbers are normally dialed in national format in-country, and
  // international format from outside the country.
  XCTAssertEqualObjects(@"030123456", [_aUtil formatNumberForMobileDialing:self.deNumber
                                                         regionCallingFrom:@"DE"
                                                            withFormatting:NO]);
  XCTAssertEqualObjects(@"+4930123456", [_aUtil formatNumberForMobileDialing:self.deNumber
                                                           regionCallingFrom:@"CH"
                                                              withFormatting:NO]);
  id deNumberWithExtn = self.deNumber;
  [deNumberWithExtn setExtension:@"1234"];
  XCTAssertEqualObjects(@"030123456", [_aUtil formatNumberForMobileDialing:deNumberWithExtn
                                                         regionCallingFrom:@"DE"
                                                            withFormatting:NO]);
  XCTAssertEqualObjects(@"+4930123456", [_aUtil formatNumberForMobileDialing:deNumberWithExtn
                                                           regionCallingFrom:@"CH"
                                                              withFormatting:NO]);

  // US toll free numbers are marked as noInternationalDialling in the test
  // metadata for testing purposes.
  XCTAssertEqualObjects(@"800 253 0000", [_aUtil formatNumberForMobileDialing:self.usTollFreeNumber
                                                            regionCallingFrom:@"US"
                                                               withFormatting:YES]);
  XCTAssertEqualObjects(@"", [_aUtil formatNumberForMobileDialing:self.usTollFreeNumber
                                                regionCallingFrom:@"CN"
                                                   withFormatting:YES]);
  XCTAssertEqualObjects(@"+1 650 253 0000", [_aUtil formatNumberForMobileDialing:self.usNumber
                                                               regionCallingFrom:@"US"
                                                                  withFormatting:YES]);

  id usNumberWithExtn = self.usNumber;
  [usNumberWithExtn setExtension:@"1234"];
  XCTAssertEqualObjects(@"+1 650 253 0000", [_aUtil formatNumberForMobileDialing:usNumberWithExtn
                                                               regionCallingFrom:@"US"
                                                                  withFormatting:YES]);
  XCTAssertEqualObjects(@"8002530000", [_aUtil formatNumberForMobileDialing:self.usTollFreeNumber
                                                          regionCallingFrom:@"US"
                                                             withFormatting:NO]);
  XCTAssertEqualObjects(@"", [_aUtil formatNumberForMobileDialing:self.usTollFreeNumber
                                                regionCallingFrom:@"CN"
                                                   withFormatting:NO]);
  XCTAssertEqualObjects(@"+16502530000", [_aUtil formatNumberForMobileDialing:self.usNumber
                                                            regionCallingFrom:@"US"
                                                               withFormatting:NO]);
  XCTAssertEqualObjects(@"+16502530000", [_aUtil formatNumberForMobileDialing:usNumberWithExtn
                                                            regionCallingFrom:@"US"
                                                               withFormatting:NO]);

  // An invalid US number, which is one digit too long.
  XCTAssertEqualObjects(@"+165025300001", [_aUtil formatNumberForMobileDialing:self.usTooLongNumber
                                                             regionCallingFrom:@"US"
                                                                withFormatting:NO]);
  XCTAssertEqualObjects(@"+1 65025300001", [_aUtil formatNumberForMobileDialing:self.usTooLongNumber
                                                              regionCallingFrom:@"US"
                                                                 withFormatting:YES]);

  // Star numbers. In real life they appear in Israel, but we have them in JP
  // in our test metadata.
  NBPhoneNumber *jpStarNumber = [[NBPhoneNumber alloc] init];
  jpStarNumber.countryCode = @81;
  jpStarNumber.nationalNumber = @2345;
  XCTAssertEqualObjects(@"*2345", [_aUtil formatNumberForMobileDialing:jpStarNumber
                                                     regionCallingFrom:@"JP"
                                                        withFormatting:NO]);
  XCTAssertEqualObjects(@"*2345", [_aUtil formatNumberForMobileDialing:jpStarNumber
                                                     regionCallingFrom:@"JP"
                                                        withFormatting:YES]);
  XCTAssertEqualObjects(@"+80012345678",
                        [_aUtil formatNumberForMobileDialing:self.internationalTollFreeNumber
                                           regionCallingFrom:@"JP"
                                              withFormatting:NO]);
  XCTAssertEqualObjects(@"+800 1234 5678",
                        [_aUtil formatNumberForMobileDialing:self.internationalTollFreeNumber
                                           regionCallingFrom:@"JP"
                                              withFormatting:YES]);

  // UAE numbers beginning with 600 (classified as UAN) need to be dialled
  // without +971 locally.
  NBPhoneNumber *aeUAN = [[NBPhoneNumber alloc] init];
  aeUAN.countryCode = @971;
  aeUAN.nationalNumber = @600123456;
  XCTAssertEqualObjects(@"+971600123456", [_aUtil formatNumberForMobileDialing:aeUAN
                                                             regionCallingFrom:@"JP"
                                                                withFormatting:NO]);
  XCTAssertEqualObjects(@"600123456", [_aUtil formatNumberForMobileDialing:aeUAN
                                                         regionCallingFrom:@"AE"
                                                            withFormatting:NO]);
  XCTAssertEqualObjects(@"+523312345678", [_aUtil formatNumberForMobileDialing:self.mxNumber
                                                             regionCallingFrom:@"MX"
                                                                withFormatting:NO]);
  XCTAssertEqualObjects(@"+523312345678", [_aUtil formatNumberForMobileDialing:self.mxNumber
                                                             regionCallingFrom:@"US"
                                                                withFormatting:NO]);

  // Non-geographical numbers should always be dialed in international format.
  XCTAssertEqualObjects(@"+80012345678",
                        [_aUtil formatNumberForMobileDialing:self.internationalTollFreeNumber
                                           regionCallingFrom:@"US"
                                              withFormatting:NO]);
  XCTAssertEqualObjects(@"+80012345678",
                        [_aUtil formatNumberForMobileDialing:self.internationalTollFreeNumber
                                           regionCallingFrom:@"UN001"
                                              withFormatting:NO]);
}

- (void)testFormatByPattern {
  NBNumberFormat *newNumFormat = [[NBNumberFormat alloc] init];
  [newNumFormat setPattern:@"(\\d{3})(\\d{3})(\\d{4})"];
  [newNumFormat setFormat:@"($1) $2-$3"];

  XCTAssertEqualObjects(@"(650) 253-0000", [_aUtil formatByPattern:self.usNumber
                                                      numberFormat:NBEPhoneNumberFormatNATIONAL
                                                userDefinedFormats:@[ newNumFormat ]]);

  XCTAssertEqualObjects(@"+1 (650) 253-0000",
                        [_aUtil formatByPattern:self.usNumber
                                   numberFormat:NBEPhoneNumberFormatINTERNATIONAL
                             userDefinedFormats:@[ newNumFormat ]]);
  XCTAssertEqualObjects(@"tel:+1-650-253-0000", [_aUtil formatByPattern:self.usNumber
                                                           numberFormat:NBEPhoneNumberFormatRFC3966
                                                     userDefinedFormats:@[ newNumFormat ]]);

  // $NP is set to '1' for the US. Here we check that for other NANPA countries
  // the US rules are followed.
  [newNumFormat setNationalPrefixFormattingRule:@"$NP ($FG)"];
  [newNumFormat setFormat:@"$1 $2-$3"];
  XCTAssertEqualObjects(@"1 (242) 365-1234", [_aUtil formatByPattern:self.bsNumber
                                                        numberFormat:NBEPhoneNumberFormatNATIONAL
                                                  userDefinedFormats:@[ newNumFormat ]]);
  XCTAssertEqualObjects(@"+1 242 365-1234",
                        [_aUtil formatByPattern:self.bsNumber
                                   numberFormat:NBEPhoneNumberFormatINTERNATIONAL
                             userDefinedFormats:@[ newNumFormat ]]);

  [newNumFormat setPattern:@"(\\d{2})(\\d{5})(\\d{3})"];
  [newNumFormat setFormat:@"$1-$2 $3"];

  XCTAssertEqualObjects(@"02-36618 300", [_aUtil formatByPattern:self.itNumber
                                                    numberFormat:NBEPhoneNumberFormatNATIONAL
                                              userDefinedFormats:@[ newNumFormat ]]);
  XCTAssertEqualObjects(@"+39 02-36618 300",
                        [_aUtil formatByPattern:self.itNumber
                                   numberFormat:NBEPhoneNumberFormatINTERNATIONAL
                             userDefinedFormats:@[ newNumFormat ]]);

  [newNumFormat setNationalPrefixFormattingRule:@"$NP$FG"];
  [newNumFormat setPattern:@"(\\d{2})(\\d{4})(\\d{4})"];
  [newNumFormat setFormat:@"$1 $2 $3"];
  NBPhoneNumber *gbNumber = self.gbNumber;
  XCTAssertEqualObjects(@"020 7031 3000", [_aUtil formatByPattern:gbNumber
                                                     numberFormat:NBEPhoneNumberFormatNATIONAL
                                               userDefinedFormats:@[ newNumFormat ]]);

  [newNumFormat setNationalPrefixFormattingRule:@"($NP$FG)"];
  XCTAssertEqualObjects(@"(020) 7031 3000", [_aUtil formatByPattern:gbNumber
                                                       numberFormat:NBEPhoneNumberFormatNATIONAL
                                                 userDefinedFormats:@[ newNumFormat ]]);

  [newNumFormat setNationalPrefixFormattingRule:@""];
  XCTAssertEqualObjects(@"20 7031 3000", [_aUtil formatByPattern:gbNumber
                                                    numberFormat:NBEPhoneNumberFormatNATIONAL
                                              userDefinedFormats:@[ newNumFormat ]]);
  XCTAssertEqualObjects(@"+44 20 7031 3000",
                        [_aUtil formatByPattern:gbNumber
                                   numberFormat:NBEPhoneNumberFormatINTERNATIONAL
                             userDefinedFormats:@[ newNumFormat ]]);
}

- (void)testFormatE164Number {
  XCTAssertEqualObjects(@"+16502530000", [_aUtil format:self.usNumber
                                             numberFormat:NBEPhoneNumberFormatE164]);
  XCTAssertEqualObjects(@"+4930123456", [_aUtil format:self.deNumber
                                            numberFormat:NBEPhoneNumberFormatE164]);
  XCTAssertEqualObjects(@"+80012345678", [_aUtil format:self.internationalTollFreeNumber
                                             numberFormat:NBEPhoneNumberFormatE164]);
}

- (void)testFormatNumberWithExtension {
  NBPhoneNumber *nzNumber = [[NBPhoneNumber alloc] init];
  nzNumber.countryCode = @64;
  nzNumber.nationalNumber = @33316005;

  [nzNumber setExtension:@"1234"];
  // Uses default extension prefix:
  XCTAssertEqualObjects(@"03-331 6005 ext. 1234", [_aUtil format:nzNumber
                                                      numberFormat:NBEPhoneNumberFormatNATIONAL]);
  // Uses RFC 3966 syntax.
  XCTAssertEqualObjects(@"tel:+64-3-331-6005;ext=1234",
                        [_aUtil format:nzNumber numberFormat:NBEPhoneNumberFormatRFC3966]);
  // Extension prefix overridden in the territory information for the US:

  id usNumberWithExtension = self.usNumber;
  [usNumberWithExtension setExtension:@"4567"];
  XCTAssertEqualObjects(@"650 253 0000 extn. 4567", [_aUtil format:usNumberWithExtension
                                                        numberFormat:NBEPhoneNumberFormatNATIONAL]);
}

- (void)testFormatInOriginalFormat {
  NSError *anError = nil;
  NBPhoneNumber *number1 = [_aUtil parseAndKeepRawInput:@"+442087654321"
                                          defaultRegion:@"GB"
                                                  error:&anError];
  XCTAssertEqualObjects(@"+44 20 8765 4321", [_aUtil formatInOriginalFormat:number1
                                                          regionCallingFrom:@"GB"]);

  NBPhoneNumber *number2 = [_aUtil parseAndKeepRawInput:@"02087654321"
                                          defaultRegion:@"GB"
                                                  error:&anError];
  XCTAssertEqualObjects(@"(020) 8765 4321", [_aUtil formatInOriginalFormat:number2
                                                         regionCallingFrom:@"GB"]);

  NBPhoneNumber *number3 = [_aUtil parseAndKeepRawInput:@"011442087654321"
                                          defaultRegion:@"US"
                                                  error:&anError];
  XCTAssertEqualObjects(@"011 44 20 8765 4321", [_aUtil formatInOriginalFormat:number3
                                                             regionCallingFrom:@"US"]);

  NBPhoneNumber *number4 = [_aUtil parseAndKeepRawInput:@"442087654321"
                                          defaultRegion:@"GB"
                                                  error:&anError];
  XCTAssertEqualObjects(@"44 20 8765 4321", [_aUtil formatInOriginalFormat:number4
                                                         regionCallingFrom:@"GB"]);

  NBPhoneNumber *number5 = [_aUtil parse:@"+442087654321" defaultRegion:@"GB" error:&anError];
  XCTAssertEqualObjects(@"(020) 8765 4321", [_aUtil formatInOriginalFormat:number5
                                                         regionCallingFrom:@"GB"]);

  // Invalid numbers that we have a formatting pattern for should be formatted
  // properly. Note area codes starting with 7 are intentionally excluded in
  // the test metadata for testing purposes.
  NBPhoneNumber *number6 = [_aUtil parseAndKeepRawInput:@"7345678901"
                                          defaultRegion:@"US"
                                                  error:&anError];
  XCTAssertEqualObjects(@"734 567 8901", [_aUtil formatInOriginalFormat:number6
                                                      regionCallingFrom:@"US"]);

  // US is not a leading zero country, and the presence of the leading zero
  // leads us to format the number using raw_input.
  NBPhoneNumber *number7 = [_aUtil parseAndKeepRawInput:@"0734567 8901"
                                          defaultRegion:@"US"
                                                  error:&anError];
  XCTAssertEqualObjects(@"0734567 8901", [_aUtil formatInOriginalFormat:number7
                                                      regionCallingFrom:@"US"]);

  // This number is valid, but we don't have a formatting pattern for it.
  // Fall back to the raw input.
  NBPhoneNumber *number8 = [_aUtil parseAndKeepRawInput:@"02-4567-8900"
                                          defaultRegion:@"KR"
                                                  error:&anError];
  XCTAssertEqualObjects(@"02-4567-8900", [_aUtil formatInOriginalFormat:number8
                                                      regionCallingFrom:@"KR"]);

  NBPhoneNumber *number9 = [_aUtil parseAndKeepRawInput:@"01180012345678"
                                          defaultRegion:@"US"
                                                  error:&anError];
  XCTAssertEqualObjects(@"011 800 1234 5678", [_aUtil formatInOriginalFormat:number9
                                                           regionCallingFrom:@"US"]);

  NBPhoneNumber *number10 = [_aUtil parseAndKeepRawInput:@"+80012345678"
                                           defaultRegion:@"KR"
                                                   error:&anError];
  XCTAssertEqualObjects(@"+800 1234 5678", [_aUtil formatInOriginalFormat:number10
                                                        regionCallingFrom:@"KR"]);

  // US local numbers are formatted correctly, as we have formatting patterns
  // for them.
  NBPhoneNumber *localNumberUS = [_aUtil parseAndKeepRawInput:@"2530000"
                                                defaultRegion:@"US"
                                                        error:&anError];
  XCTAssertEqualObjects(@"253 0000", [_aUtil formatInOriginalFormat:localNumberUS
                                                  regionCallingFrom:@"US"]);

  NBPhoneNumber *numberWithNationalPrefixUS = [_aUtil parseAndKeepRawInput:@"18003456789"
                                                             defaultRegion:@"US"
                                                                     error:&anError];
  XCTAssertEqualObjects(@"1 800 345 6789", [_aUtil formatInOriginalFormat:numberWithNationalPrefixUS
                                                        regionCallingFrom:@"US"]);

  NBPhoneNumber *numberWithoutNationalPrefixGB = [_aUtil parseAndKeepRawInput:@"2087654321"
                                                                defaultRegion:@"GB"
                                                                        error:&anError];
  XCTAssertEqualObjects(@"20 8765 4321",
                        [_aUtil formatInOriginalFormat:numberWithoutNationalPrefixGB
                                     regionCallingFrom:@"GB"]);

  // Make sure no metadata is modified as a result of the previous function
  // call.
  XCTAssertEqualObjects(@"(020) 8765 4321", [_aUtil formatInOriginalFormat:number5
                                                         regionCallingFrom:@"GB"
                                                                     error:&anError]);

  NBPhoneNumber *numberWithNationalPrefixMX = [_aUtil parseAndKeepRawInput:@"013312345678"
                                                             defaultRegion:@"MX"
                                                                     error:&anError];
  XCTAssertEqualObjects(@"01 33 1234 5678",
                        [_aUtil formatInOriginalFormat:numberWithNationalPrefixMX
                                     regionCallingFrom:@"MX"]);

  NBPhoneNumber *numberWithoutNationalPrefixMX = [_aUtil parseAndKeepRawInput:@"3312345678"
                                                                defaultRegion:@"MX"
                                                                        error:&anError];
  XCTAssertEqualObjects(@"33 1234 5678",
                        [_aUtil formatInOriginalFormat:numberWithoutNationalPrefixMX
                                     regionCallingFrom:@"MX"]);

  NBPhoneNumber *italianFixedLineNumber = [_aUtil parseAndKeepRawInput:@"0212345678"
                                                         defaultRegion:@"IT"
                                                                 error:&anError];
  XCTAssertEqualObjects(@"02 1234 5678", [_aUtil formatInOriginalFormat:italianFixedLineNumber
                                                      regionCallingFrom:@"IT"]);

  NBPhoneNumber *numberWithNationalPrefixJP = [_aUtil parseAndKeepRawInput:@"00777012"
                                                             defaultRegion:@"JP"
                                                                     error:&anError];
  XCTAssertEqualObjects(@"0077-7012", [_aUtil formatInOriginalFormat:numberWithNationalPrefixJP
                                                   regionCallingFrom:@"JP"]);

  NBPhoneNumber *numberWithoutNationalPrefixJP = [_aUtil parseAndKeepRawInput:@"0777012"
                                                                defaultRegion:@"JP"
                                                                        error:&anError];
  XCTAssertEqualObjects(@"0777012", [_aUtil formatInOriginalFormat:numberWithoutNationalPrefixJP
                                                 regionCallingFrom:@"JP"]);

  NBPhoneNumber *numberWithCarrierCodeBR = [_aUtil parseAndKeepRawInput:@"012 3121286979"
                                                          defaultRegion:@"BR"
                                                                  error:&anError];
  XCTAssertEqualObjects(@"012 3121286979", [_aUtil formatInOriginalFormat:numberWithCarrierCodeBR
                                                        regionCallingFrom:@"BR"]);

  // The default national prefix used in this case is 045. When a number with
  // national prefix 044 is entered, we return the raw input as we don't want to
  // change the number entered.
  NBPhoneNumber *numberWithNationalPrefixMX1 = [_aUtil parseAndKeepRawInput:@"044(33)1234-5678"
                                                              defaultRegion:@"MX"
                                                                      error:&anError];
  XCTAssertEqualObjects(@"044(33)1234-5678",
                        [_aUtil formatInOriginalFormat:numberWithNationalPrefixMX1
                                     regionCallingFrom:@"MX"]);

  NBPhoneNumber *numberWithNationalPrefixMX2 = [_aUtil parseAndKeepRawInput:@"045(33)1234-5678"
                                                              defaultRegion:@"MX"
                                                                      error:&anError];
  XCTAssertEqualObjects(@"045 33 1234 5678",
                        [_aUtil formatInOriginalFormat:numberWithNationalPrefixMX2
                                     regionCallingFrom:@"MX"]);

  // The default international prefix used in this case is 0011. When a number
  // with international prefix 0012 is entered, we return the raw input as we
  // don't want to change the number entered.
  id outOfCountryNumberFromAU1 = [_aUtil parseAndKeepRawInput:@"0012 16502530000"
                                                defaultRegion:@"AU"
                                                        error:&anError];
  XCTAssertEqualObjects(@"0012 16502530000",
                        [_aUtil formatInOriginalFormat:outOfCountryNumberFromAU1
                                     regionCallingFrom:@"AU"]);

  id outOfCountryNumberFromAU2 = [_aUtil parseAndKeepRawInput:@"0011 16502530000"
                                                defaultRegion:@"AU"
                                                        error:&anError];
  XCTAssertEqualObjects(@"0011 1 650 253 0000",
                        [_aUtil formatInOriginalFormat:outOfCountryNumberFromAU2
                                     regionCallingFrom:@"AU"]);

  // Test the star sign is not removed from or added to the original input by
  // this method.
  id starNumber = [_aUtil parseAndKeepRawInput:@"*1234" defaultRegion:@"JP" error:&anError];
  XCTAssertEqualObjects(@"*1234", [_aUtil formatInOriginalFormat:starNumber
                                               regionCallingFrom:@"JP"]);

  NBPhoneNumber *numberWithoutStar = [_aUtil parseAndKeepRawInput:@"1234"
                                                    defaultRegion:@"JP"
                                                            error:&anError];
  XCTAssertEqualObjects(@"1234", [_aUtil formatInOriginalFormat:numberWithoutStar
                                              regionCallingFrom:@"JP"]);

  // Test an invalid national number without raw input is just formatted as the
  // national number.
  XCTAssertEqualObjects(@"650253000", [_aUtil formatInOriginalFormat:self.usShortByOneNumber
                                                   regionCallingFrom:@"US"]);
}

- (void)testIsPremiumRate {
  XCTAssertEqual(NBEPhoneNumberTypePREMIUM_RATE, [_aUtil getNumberType:self.usPremiumNumber]);

  NBPhoneNumber *premiumRateNumber = [[NBPhoneNumber alloc] init];
  premiumRateNumber = [[NBPhoneNumber alloc] init];
  [premiumRateNumber setCountryCode:@39];
  [premiumRateNumber setNationalNumber:@892123];
  XCTAssertEqual(NBEPhoneNumberTypePREMIUM_RATE, [_aUtil getNumberType:premiumRateNumber]);

  premiumRateNumber = [[NBPhoneNumber alloc] init];
  [premiumRateNumber setCountryCode:@44];
  [premiumRateNumber setNationalNumber:@9187654321];
  XCTAssertEqual(NBEPhoneNumberTypePREMIUM_RATE, [_aUtil getNumberType:premiumRateNumber]);

  premiumRateNumber = [[NBPhoneNumber alloc] init];
  [premiumRateNumber setCountryCode:@49];
  [premiumRateNumber setNationalNumber:@9001654321];
  XCTAssertEqual(NBEPhoneNumberTypePREMIUM_RATE, [_aUtil getNumberType:premiumRateNumber]);

  premiumRateNumber = [[NBPhoneNumber alloc] init];
  [premiumRateNumber setCountryCode:@49];
  [premiumRateNumber setNationalNumber:@90091234567];
  XCTAssertEqual(NBEPhoneNumberTypePREMIUM_RATE, [_aUtil getNumberType:premiumRateNumber]);
  XCTAssertEqual(NBEPhoneNumberTypePREMIUM_RATE,
                 [_aUtil getNumberType:self.universalPremiumRateNumber]);
}

- (void)testIsTollFree {
  NBPhoneNumber *tollFreeNumber = [[NBPhoneNumber alloc] init];

  [tollFreeNumber setCountryCode:@1];
  [tollFreeNumber setNationalNumber:@8881234567];
  XCTAssertEqual(NBEPhoneNumberTypeTOLL_FREE, [_aUtil getNumberType:tollFreeNumber]);

  tollFreeNumber = [[NBPhoneNumber alloc] init];
  [tollFreeNumber setCountryCode:@39];
  [tollFreeNumber setNationalNumber:@803123];
  XCTAssertEqual(NBEPhoneNumberTypeTOLL_FREE, [_aUtil getNumberType:tollFreeNumber]);

  tollFreeNumber = [[NBPhoneNumber alloc] init];
  [tollFreeNumber setCountryCode:@44];
  [tollFreeNumber setNationalNumber:@8012345678];
  XCTAssertEqual(NBEPhoneNumberTypeTOLL_FREE, [_aUtil getNumberType:tollFreeNumber]);

  tollFreeNumber = [[NBPhoneNumber alloc] init];
  [tollFreeNumber setCountryCode:@49];
  [tollFreeNumber setNationalNumber:@8001234567];
  XCTAssertEqual(NBEPhoneNumberTypeTOLL_FREE, [_aUtil getNumberType:tollFreeNumber]);

  XCTAssertEqual(NBEPhoneNumberTypeTOLL_FREE,
                 [_aUtil getNumberType:self.internationalTollFreeNumber]);
}

- (void)testIsMobile {
  XCTAssertEqual(NBEPhoneNumberTypeMOBILE, [_aUtil getNumberType:self.bsMobile]);
  XCTAssertEqual(NBEPhoneNumberTypeMOBILE, [_aUtil getNumberType:self.gbMobile]);
  XCTAssertEqual(NBEPhoneNumberTypeMOBILE, [_aUtil getNumberType:self.itMobile]);
  XCTAssertEqual(NBEPhoneNumberTypeMOBILE, [_aUtil getNumberType:self.arMobile]);

  NBPhoneNumber *mobileNumber = [[NBPhoneNumber alloc] init];
  [mobileNumber setCountryCode:@49];
  [mobileNumber setNationalNumber:@15123456789];
  XCTAssertEqual(NBEPhoneNumberTypeMOBILE, [_aUtil getNumberType:mobileNumber]);
}

- (void)testIsFixedLine {
  XCTAssertEqual(NBEPhoneNumberTypeFIXED_LINE, [_aUtil getNumberType:self.bsNumber]);
  XCTAssertEqual(NBEPhoneNumberTypeFIXED_LINE, [_aUtil getNumberType:self.itNumber]);
  XCTAssertEqual(NBEPhoneNumberTypeFIXED_LINE, [_aUtil getNumberType:self.gbNumber]);
  XCTAssertEqual(NBEPhoneNumberTypeFIXED_LINE, [_aUtil getNumberType:self.deNumber]);
}

- (void)testIsFixedLineAndMobile {
  XCTAssertEqual(NBEPhoneNumberTypeFIXED_LINE_OR_MOBILE, [_aUtil getNumberType:self.usNumber]);

  NBPhoneNumber *fixedLineAndMobileNumber = [[NBPhoneNumber alloc] init];
  [fixedLineAndMobileNumber setCountryCode:@54];
  [fixedLineAndMobileNumber setNationalNumber:@1987654321];
  XCTAssertEqual(NBEPhoneNumberTypeFIXED_LINE_OR_MOBILE,
                 [_aUtil getNumberType:fixedLineAndMobileNumber]);
}

- (void)testIsSharedCost {
  NBPhoneNumber *gbNumber = [[NBPhoneNumber alloc] init];
  [gbNumber setCountryCode:@44];
  [gbNumber setNationalNumber:@8431231234];
  XCTAssertEqual(NBEPhoneNumberTypeSHARED_COST, [_aUtil getNumberType:gbNumber]);
}

- (void)testIsVoip {
  NBPhoneNumber *gbNumber = [[NBPhoneNumber alloc] init];
  [gbNumber setCountryCode:@44];
  [gbNumber setNationalNumber:@5631231234];
  XCTAssertEqual(NBEPhoneNumberTypeVOIP, [_aUtil getNumberType:gbNumber]);
}

- (void)testIsPersonalNumber {
  NBPhoneNumber *gbNumber = [[NBPhoneNumber alloc] init];
  [gbNumber setCountryCode:@44];
  [gbNumber setNationalNumber:@7031231234];
  XCTAssertEqual(NBEPhoneNumberTypePERSONAL_NUMBER, [_aUtil getNumberType:gbNumber]);
}

- (void)testIsUnknown {
  // Invalid numbers should be of type UNKNOWN.
  XCTAssertEqual(NBEPhoneNumberTypeUNKNOWN, [_aUtil getNumberType:self.usLocalNumber]);
}

- (void)testisValidNumber {
  XCTAssertTrue([_aUtil isValidNumber:self.usNumber]);
  XCTAssertTrue([_aUtil isValidNumber:self.itNumber]);
  XCTAssertTrue([_aUtil isValidNumber:self.gbMobile]);
  XCTAssertTrue([_aUtil isValidNumber:self.internationalTollFreeNumber]);
  XCTAssertTrue([_aUtil isValidNumber:self.universalPremiumRateNumber]);
  XCTAssertTrue([_aUtil isValidNumber:self.nzNumber]);
}

- (void)testIsValidForRegion {
  // This number is valid for the Bahamas, but is not a valid US number.
  XCTAssertTrue([_aUtil isValidNumber:self.bsNumber]);
  XCTAssertTrue([_aUtil isValidNumberForRegion:self.bsNumber regionCode:@"BS"]);
  XCTAssertFalse([_aUtil isValidNumberForRegion:self.bsNumber regionCode:@"US"]);

  NBPhoneNumber *bsInvalidNumber = [[NBPhoneNumber alloc] init];
  [bsInvalidNumber setCountryCode:@1];
  [bsInvalidNumber setNationalNumber:@2421232345];
  // This number is no longer valid.
  XCTAssertFalse([_aUtil isValidNumber:bsInvalidNumber]);

  // La Mayotte and Reunion use 'leadingDigits' to differentiate them.

  NBPhoneNumber *reNumber = [[NBPhoneNumber alloc] init];
  [reNumber setCountryCode:@262];
  [reNumber setNationalNumber:@262123456];
  XCTAssertTrue([_aUtil isValidNumber:reNumber]);
  XCTAssertTrue([_aUtil isValidNumberForRegion:reNumber regionCode:@"RE"]);
  XCTAssertFalse([_aUtil isValidNumberForRegion:reNumber regionCode:@"YT"]);

  // Now change the number to be a number for La Mayotte.
  [reNumber setNationalNumber:@269601234];
  XCTAssertTrue([_aUtil isValidNumberForRegion:reNumber regionCode:@"YT"]);
  XCTAssertFalse([_aUtil isValidNumberForRegion:reNumber regionCode:@"RE"]);

  // This number is no longer valid for La Reunion.
  [reNumber setNationalNumber:@269123456];
  XCTAssertFalse([_aUtil isValidNumberForRegion:reNumber regionCode:@"YT"]);
  XCTAssertFalse([_aUtil isValidNumberForRegion:reNumber regionCode:@"RE"]);
  XCTAssertFalse([_aUtil isValidNumber:reNumber]);

  // However, it should be recognised as from La Mayotte, since it is valid for
  // this region.
  XCTAssertEqualObjects(@"YT", [_aUtil getRegionCodeForNumber:reNumber]);

  // This number is valid in both places.
  [reNumber setNationalNumber:@800123456];
  XCTAssertTrue([_aUtil isValidNumberForRegion:reNumber regionCode:@"YT"]);
  XCTAssertTrue([_aUtil isValidNumberForRegion:reNumber regionCode:@"RE"]);
  XCTAssertTrue([_aUtil isValidNumberForRegion:self.internationalTollFreeNumber regionCode:@"001"]);
  XCTAssertFalse([_aUtil isValidNumberForRegion:self.internationalTollFreeNumber regionCode:@"US"]);
  XCTAssertFalse([_aUtil isValidNumberForRegion:self.internationalTollFreeNumber
                                     regionCode:NB_UNKNOWN_REGION]);

  NBPhoneNumber *invalidNumber = [[NBPhoneNumber alloc] init];
  // Invalid country calling codes.
  [invalidNumber setCountryCode:@3923];
  [invalidNumber setNationalNumber:@2366];
  XCTAssertFalse([_aUtil isValidNumberForRegion:invalidNumber regionCode:NB_UNKNOWN_REGION]);
  XCTAssertFalse([_aUtil isValidNumberForRegion:invalidNumber regionCode:@"001"]);
  [invalidNumber setCountryCode:0];
  XCTAssertFalse([_aUtil isValidNumberForRegion:invalidNumber regionCode:@"001"]);
  XCTAssertFalse([_aUtil isValidNumberForRegion:invalidNumber regionCode:NB_UNKNOWN_REGION]);
}
- (void)testIsNotValidNumber {
  XCTAssertFalse([_aUtil isValidNumber:self.usLocalNumber]);

  NBPhoneNumber *invalidNumber = [[NBPhoneNumber alloc] init];
  [invalidNumber setCountryCode:@39];
  [invalidNumber setNationalNumber:@23661830000];
  [invalidNumber setItalianLeadingZero:YES];
  XCTAssertFalse([_aUtil isValidNumber:invalidNumber]);

  invalidNumber = [[NBPhoneNumber alloc] init];
  [invalidNumber setCountryCode:@44];
  [invalidNumber setNationalNumber:@791234567];
  XCTAssertFalse([_aUtil isValidNumber:invalidNumber]);

  invalidNumber = [[NBPhoneNumber alloc] init];
  [invalidNumber setCountryCode:@0];
  [invalidNumber setNationalNumber:@1234];
  XCTAssertFalse([_aUtil isValidNumber:invalidNumber]);

  invalidNumber = [[NBPhoneNumber alloc] init];
  [invalidNumber setCountryCode:@64];
  [invalidNumber setNationalNumber:@3316005];
  XCTAssertFalse([_aUtil isValidNumber:invalidNumber]);

  invalidNumber = [[NBPhoneNumber alloc] init];
  // Invalid country calling codes.
  [invalidNumber setCountryCode:@3923];
  [invalidNumber setNationalNumber:@2366];
  XCTAssertFalse([_aUtil isValidNumber:invalidNumber]);
  [invalidNumber setCountryCode:@0];
  XCTAssertFalse([_aUtil isValidNumber:invalidNumber]);

  XCTAssertFalse([_aUtil isValidNumber:self.internationalTollFreeTooLongNumber]);
}

- (void)testgetRegionCodeForCountryCode {
  XCTAssertEqualObjects(@"US", [_aUtil getRegionCodeForCountryCode:@1]);
  XCTAssertEqualObjects(@"GB", [_aUtil getRegionCodeForCountryCode:@44]);
  XCTAssertEqualObjects(@"DE", [_aUtil getRegionCodeForCountryCode:@49]);
  XCTAssertEqualObjects(@"001", [_aUtil getRegionCodeForCountryCode:@800]);
  XCTAssertEqualObjects(@"001", [_aUtil getRegionCodeForCountryCode:@979]);
}

- (void)testgetRegionCodeForNumber {
  XCTAssertEqualObjects(@"BS", [_aUtil getRegionCodeForNumber:self.bsNumber]);
  XCTAssertEqualObjects(@"US", [_aUtil getRegionCodeForNumber:self.usNumber]);
  XCTAssertEqualObjects(@"GB", [_aUtil getRegionCodeForNumber:self.gbMobile]);
  XCTAssertEqualObjects(@"001", [_aUtil getRegionCodeForNumber:self.internationalTollFreeNumber]);
  XCTAssertEqualObjects(@"001", [_aUtil getRegionCodeForNumber:self.universalPremiumRateNumber]);
}

- (void)testGetRegionCodesForCountryCode {
  NSArray *regionCodesForNANPA = [_aUtil getRegionCodesForCountryCode:@1];
  XCTAssertTrue([regionCodesForNANPA containsObject:@"US"]);
  XCTAssertTrue([regionCodesForNANPA containsObject:@"BS"]);
  XCTAssertTrue([[_aUtil getRegionCodesForCountryCode:@44] containsObject:@"GB"]);
  XCTAssertTrue([[_aUtil getRegionCodesForCountryCode:@49] containsObject:@"DE"]);
  XCTAssertTrue([[_aUtil getRegionCodesForCountryCode:@800] containsObject:@"001"]);
  // Test with invalid country calling code.
  XCTAssertTrue([[_aUtil getRegionCodesForCountryCode:@-1] count] == 0);
}

- (void)testGetCountryCodeForRegion {
  XCTAssertEqualObjects(@1, [_aUtil getCountryCodeForRegion:@"US"]);
  XCTAssertEqualObjects(@64, [_aUtil getCountryCodeForRegion:@"NZ"]);
  XCTAssertEqualObjects(@0, [_aUtil getCountryCodeForRegion:nil]);
  XCTAssertEqualObjects(@0, [_aUtil getCountryCodeForRegion:NB_UNKNOWN_REGION]);
  XCTAssertEqualObjects(@0, [_aUtil getCountryCodeForRegion:@"001"]);
  // CS is already deprecated so the library doesn't support it.
  XCTAssertEqualObjects(@0, [_aUtil getCountryCodeForRegion:@"CS"]);
}

- (void)testGetNationalDiallingPrefixForRegion {
  XCTAssertEqualObjects(@"1", [_aUtil getNddPrefixForRegion:@"US" stripNonDigits:NO]);

  // Test non-main country to see it gets the national dialling prefix for the
  // main country with that country calling code.
  XCTAssertEqualObjects(@"1", [_aUtil getNddPrefixForRegion:@"BS" stripNonDigits:NO]);
  XCTAssertEqualObjects(@"0", [_aUtil getNddPrefixForRegion:@"NZ" stripNonDigits:NO]);

  // Test case with non digit in the national prefix.
  XCTAssertEqualObjects(@"0~0", [_aUtil getNddPrefixForRegion:@"AO" stripNonDigits:NO]);
  XCTAssertEqualObjects(@"00", [_aUtil getNddPrefixForRegion:@"AO" stripNonDigits:YES]);

  // Test cases with invalid regions.
  XCTAssertNil([_aUtil getNddPrefixForRegion:nil stripNonDigits:NO]);
  XCTAssertNil([_aUtil getNddPrefixForRegion:NB_UNKNOWN_REGION stripNonDigits:NO]);
  XCTAssertNil([_aUtil getNddPrefixForRegion:@"001" stripNonDigits:NO]);

  // CS is already deprecated so the library doesn't support it.
  XCTAssertNil([_aUtil getNddPrefixForRegion:@"CS" stripNonDigits:NO]);
}

- (void)testIsNANPACountry {
  XCTAssertTrue([_aUtil isNANPACountry:@"US"]);
  XCTAssertTrue([_aUtil isNANPACountry:@"BS"]);
  XCTAssertFalse([_aUtil isNANPACountry:@"DE"]);
  XCTAssertFalse([_aUtil isNANPACountry:NB_UNKNOWN_REGION]);
  XCTAssertFalse([_aUtil isNANPACountry:@"001"]);
  XCTAssertFalse([_aUtil isNANPACountry:nil]);
}

- (void)testIsPossibleNumber {
  XCTAssertTrue([_aUtil isPossibleNumber:self.usNumber]);
  XCTAssertTrue([_aUtil isPossibleNumber:self.usLocalNumber]);
  XCTAssertTrue([_aUtil isPossibleNumber:self.gbNumber]);
  XCTAssertTrue([_aUtil isPossibleNumber:self.internationalTollFreeNumber]);

  XCTAssertTrue([_aUtil isPossibleNumberString:@"+1 650 253 0000"
                             regionDialingFrom:@"US"
                                         error:nil]);
  XCTAssertTrue([_aUtil isPossibleNumberString:@"+1 650 GOO OGLE"
                             regionDialingFrom:@"US"
                                         error:nil]);
  XCTAssertTrue([_aUtil isPossibleNumberString:@"(650) 253-0000"
                             regionDialingFrom:@"US"
                                         error:nil]);
  XCTAssertTrue([_aUtil isPossibleNumberString:@"253-0000" regionDialingFrom:@"US" error:nil]);
  XCTAssertTrue([_aUtil isPossibleNumberString:@"+1 650 253 0000"
                             regionDialingFrom:@"GB"
                                         error:nil]);
  XCTAssertTrue([_aUtil isPossibleNumberString:@"+44 20 7031 3000"
                             regionDialingFrom:@"GB"
                                         error:nil]);
  XCTAssertTrue([_aUtil isPossibleNumberString:@"(020) 7031 3000"
                             regionDialingFrom:@"GB"
                                         error:nil]);
  XCTAssertTrue([_aUtil isPossibleNumberString:@"7031 3000" regionDialingFrom:@"GB" error:nil]);
  XCTAssertTrue([_aUtil isPossibleNumberString:@"3331 6005" regionDialingFrom:@"NZ" error:nil]);
  XCTAssertTrue([_aUtil isPossibleNumberString:@"+800 1234 5678"
                             regionDialingFrom:@"001"
                                         error:nil]);
}

- (void)testIsPossibleNumberWithReason {
  // National numbers for country calling code +1 that are within 7 to 10 digits
  // are possible.
  XCTAssertEqual(NBEValidationResultIS_POSSIBLE, [_aUtil isPossibleNumberWithReason:self.usNumber]);
  XCTAssertEqual(NBEValidationResultIS_POSSIBLE,
                 [_aUtil isPossibleNumberWithReason:self.usLocalNumber]);
  XCTAssertEqual(NBEValidationResultTOO_LONG,
                 [_aUtil isPossibleNumberWithReason:self.usTooLongNumber]);

  NBPhoneNumber *number = [[NBPhoneNumber alloc] init];
  [number setCountryCode:@0];
  [number setNationalNumber:@2530000];
  XCTAssertEqual(NBEValidationResultINVALID_COUNTRY_CODE,
                 [_aUtil isPossibleNumberWithReason:number]);

  number = [[NBPhoneNumber alloc] init];
  [number setCountryCode:@1];
  [number setNationalNumber:@253000];
  XCTAssertEqual(NBEValidationResultTOO_SHORT, [_aUtil isPossibleNumberWithReason:number]);

  number = [[NBPhoneNumber alloc] init];
  [number setCountryCode:@65];
  [number setNationalNumber:@1234567890];
  XCTAssertEqual(NBEValidationResultIS_POSSIBLE, [_aUtil isPossibleNumberWithReason:number]);
  XCTAssertEqual(NBEValidationResultTOO_LONG,
                 [_aUtil isPossibleNumberWithReason:self.internationalTollFreeTooLongNumber]);
}

- (void)testIsNotPossibleNumber {
  XCTAssertFalse([_aUtil isPossibleNumber:self.usTooLongNumber]);
  XCTAssertFalse([_aUtil isPossibleNumber:self.internationalTollFreeTooLongNumber]);

  NBPhoneNumber *number = [[NBPhoneNumber alloc] init];
  [number setCountryCode:@1];
  [number setNationalNumber:@253000];
  XCTAssertFalse([_aUtil isPossibleNumber:number]);

  number = [[NBPhoneNumber alloc] init];
  [number setCountryCode:@44];
  [number setNationalNumber:@300];
  XCTAssertFalse([_aUtil isPossibleNumber:number]);
  XCTAssertFalse([_aUtil isPossibleNumberString:@"+1 650 253 00000"
                              regionDialingFrom:@"US"
                                          error:nil]);
  XCTAssertFalse([_aUtil isPossibleNumberString:@"(650) 253-00000"
                              regionDialingFrom:@"US"
                                          error:nil]);
  XCTAssertFalse([_aUtil isPossibleNumberString:@"I want a Pizza"
                              regionDialingFrom:@"US"
                                          error:nil]);
  XCTAssertFalse([_aUtil isPossibleNumberString:@"253-000" regionDialingFrom:@"US" error:nil]);
  XCTAssertFalse([_aUtil isPossibleNumberString:@"1 3000" regionDialingFrom:@"GB" error:nil]);
  XCTAssertFalse([_aUtil isPossibleNumberString:@"+44 300" regionDialingFrom:@"GB" error:nil]);
  XCTAssertFalse([_aUtil isPossibleNumberString:@"+800 1234 5678 9"
                              regionDialingFrom:@"001"
                                          error:nil]);
}

- (void)testTruncateTooLongNumber {
  // GB number 080 1234 5678, but entered with 4 extra digits at the end.
  NBPhoneNumber *tooLongNumber = [[NBPhoneNumber alloc] init];
  [tooLongNumber setCountryCode:@44];
  [tooLongNumber setNationalNumber:@80123456780123];

  NBPhoneNumber *validNumber = [[NBPhoneNumber alloc] init];
  [validNumber setCountryCode:@44];
  [validNumber setNationalNumber:@8012345678];
  XCTAssertTrue([_aUtil truncateTooLongNumber:tooLongNumber]);
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
  XCTAssertTrue([_aUtil truncateTooLongNumber:tooLongNumber]);
  XCTAssertTrue([validNumber isEqual:tooLongNumber]);

  // US number 650-253-0000, but entered with one additional digit at the end.
  tooLongNumber = self.usTooLongNumber;
  XCTAssertTrue([_aUtil truncateTooLongNumber:tooLongNumber]);
  XCTAssertTrue([self.usNumber isEqual:tooLongNumber]);

  tooLongNumber = self.internationalTollFreeTooLongNumber;
  XCTAssertTrue([_aUtil truncateTooLongNumber:tooLongNumber]);
  XCTAssertTrue([self.internationalTollFreeNumber isEqual:tooLongNumber]);

  // Tests what happens when a valid number is passed in.

  NBPhoneNumber *validNumberCopy = [validNumber copy];
  XCTAssertTrue([_aUtil truncateTooLongNumber:validNumber]);
  // Tests the number is not modified.
  XCTAssertTrue([validNumber isEqual:validNumberCopy]);

  // Tests what happens when a number with invalid prefix is passed in.

  NBPhoneNumber *numberWithInvalidPrefix = [[NBPhoneNumber alloc] init];
  // The test metadata says US numbers cannot have prefix 240.
  [numberWithInvalidPrefix setCountryCode:@1];
  [numberWithInvalidPrefix setNationalNumber:@2401234567];

  NBPhoneNumber *invalidNumberCopy = [numberWithInvalidPrefix copy];
  XCTAssertFalse([_aUtil truncateTooLongNumber:numberWithInvalidPrefix]);
  // Tests the number is not modified.
  XCTAssertTrue([numberWithInvalidPrefix isEqual:invalidNumberCopy]);

  // Tests what happens when a too short number is passed in.

  NBPhoneNumber *tooShortNumber = [[NBPhoneNumber alloc] init];
  [tooShortNumber setCountryCode:@1];
  [tooShortNumber setNationalNumber:@1234];

  NBPhoneNumber *tooShortNumberCopy = [tooShortNumber copy];
  XCTAssertFalse([_aUtil truncateTooLongNumber:tooShortNumber]);
  // Tests the number is not modified.
  XCTAssertTrue([tooShortNumber isEqual:tooShortNumberCopy]);
}

- (void)testIsViablePhoneNumber {
  XCTAssertFalse([_aUtil isViablePhoneNumber:@"1"]);
  // Only one or two digits before strange non-possible punctuation.
  XCTAssertFalse([_aUtil isViablePhoneNumber:@"1+1+1"]);
  XCTAssertFalse([_aUtil isViablePhoneNumber:@"80+0"]);
  // Two digits is viable.
  XCTAssertTrue([_aUtil isViablePhoneNumber:@"00"]);
  XCTAssertTrue([_aUtil isViablePhoneNumber:@"111"]);
  // Alpha numbers.
  XCTAssertTrue([_aUtil isViablePhoneNumber:@"0800-4-pizza"]);
  XCTAssertTrue([_aUtil isViablePhoneNumber:@"0800-4-PIZZA"]);
  // We need at least three digits before any alpha characters.
  XCTAssertFalse([_aUtil isViablePhoneNumber:@"08-PIZZA"]);
  XCTAssertFalse([_aUtil isViablePhoneNumber:@"8-PIZZA"]);
  XCTAssertFalse([_aUtil isViablePhoneNumber:@"12. March"]);
}

- (void)testIsViablePhoneNumberNonAscii {
  // Only one or two digits before possible punctuation followed by more digits.
  XCTAssertTrue([_aUtil isViablePhoneNumber:@"1\u300034"]);
  XCTAssertFalse([_aUtil isViablePhoneNumber:@"1\u30003+4"]);
  // Unicode variants of possible starting character and other allowed
  // punctuation/digits.
  XCTAssertTrue([_aUtil isViablePhoneNumber:@"\uFF081\uFF09\u30003456789"]);
  // Testing a leading + is okay.
  XCTAssertTrue([_aUtil isViablePhoneNumber:@"+1\uFF09\u30003456789"]);
}

- (void)testExtractPossibleNumber {
  // Removes preceding funky punctuation and letters but leaves the rest
  // untouched.
  XCTAssertEqualObjects(@"0800-345-600", [_aUtil extractPossibleNumber:@"Tel:0800-345-600"]);
  XCTAssertEqualObjects(@"0800 FOR PIZZA", [_aUtil extractPossibleNumber:@"Tel:0800 FOR PIZZA"]);
  // Should not remove plus sign
  XCTAssertEqualObjects(@"+800-345-600", [_aUtil extractPossibleNumber:@"Tel:+800-345-600"]);
  // Should recognise wide digits as possible start values.
  XCTAssertEqualObjects(@"\uFF10\uFF12\uFF13",
                        [_aUtil extractPossibleNumber:@"\uFF10\uFF12\uFF13"]);
  // Dashes are not possible start values and should be removed.
  XCTAssertEqualObjects(@"\uFF11\uFF12\uFF13",
                        [_aUtil extractPossibleNumber:@"Num-\uFF11\uFF12\uFF13"]);
  // If not possible number present, return empty string.
  XCTAssertEqualObjects(@"", [_aUtil extractPossibleNumber:@"Num-...."]);
  // Leading brackets are stripped - these are not used when parsing.
  XCTAssertEqualObjects(@"650) 253-0000", [_aUtil extractPossibleNumber:@"(650) 253-0000"]);

  // Trailing non-alpha-numeric characters should be removed.
  XCTAssertEqualObjects(@"650) 253-0000", [_aUtil extractPossibleNumber:@"(650) 253-0000..- .."]);
  XCTAssertEqualObjects(@"650) 253-0000", [_aUtil extractPossibleNumber:@"(650) 253-0000."]);
  // This case has a trailing RTL char.
  XCTAssertEqualObjects(@"650) 253-0000", [_aUtil extractPossibleNumber:@"(650) 253-0000\u200F"]);
}

- (void)testMaybeStripNationalPrefix {
  NBPhoneMetaData *metadata = [[NBPhoneMetaData alloc] init];
  [metadata setNationalPrefixForParsing:@"34"];
  NSArray *entry = PhoneNumberDescEntryForNationalNumberPattern(@"\\d{4,8}");
  NBPhoneNumberDesc *generalDesc = [[NBPhoneNumberDesc alloc] initWithEntry:entry];
  [metadata setGeneralDesc:generalDesc];

  NBPhoneNumber *numberToStrip = [[NBPhoneNumber alloc] init];
  [numberToStrip setRawInput:@"34356778"];

  NSString *strippedNumber = @"356778";
  NSString *rawInput = numberToStrip.rawInput;
  XCTAssertTrue([_aUtil maybeStripNationalPrefixAndCarrierCode:&rawInput
                                                      metadata:metadata
                                                   carrierCode:nil]);
  XCTAssertEqualObjects(strippedNumber, rawInput, @"Should have had national prefix stripped.");

  // Retry stripping - now the number should not start with the national prefix,
  // so no more stripping should occur.
  XCTAssertFalse([_aUtil maybeStripNationalPrefixAndCarrierCode:&rawInput
                                                       metadata:metadata
                                                    carrierCode:nil]);
  XCTAssertEqualObjects(strippedNumber, rawInput,
                        @"Should have had no change - no national prefix present.");

  // Some countries have no national prefix. Repeat test with none specified.
  [metadata setNationalPrefixForParsing:@""];
  XCTAssertFalse([_aUtil maybeStripNationalPrefixAndCarrierCode:&rawInput
                                                       metadata:metadata
                                                    carrierCode:nil]);
  XCTAssertEqualObjects(strippedNumber, rawInput,
                        @"Should not strip anything with empty national prefix.");

  // If the resultant number doesn't match the national rule, it shouldn't be
  // stripped.
  [metadata setNationalPrefixForParsing:@"3"];
  numberToStrip.rawInput = @"3123";
  rawInput = numberToStrip.rawInput;
  strippedNumber = @"3123";
  XCTAssertFalse([_aUtil maybeStripNationalPrefixAndCarrierCode:&rawInput
                                                       metadata:metadata
                                                    carrierCode:nil]);
  XCTAssertEqualObjects(
      strippedNumber, rawInput,
      @"Should have had no change - after stripping, it would not have matched the national rule.");

  // Test extracting carrier selection code.
  [metadata setNationalPrefixForParsing:@"0(81)?"];
  numberToStrip.rawInput = @"08122123456";
  strippedNumber = @"22123456";
  rawInput = numberToStrip.rawInput;
  NSString *carrierCode = @"";
  XCTAssertTrue([_aUtil maybeStripNationalPrefixAndCarrierCode:&rawInput
                                                      metadata:metadata
                                                   carrierCode:&carrierCode]);
  XCTAssertEqualObjects(@"81", carrierCode);
  XCTAssertEqualObjects(strippedNumber, rawInput,
                        @"Should have had national prefix and carrier code stripped.");

  // If there was a transform rule, check it was applied.
  [metadata setNationalPrefixTransformRule:@"5$15"];
  // Note that a capturing group is present here.
  [metadata setNationalPrefixForParsing:@"0(\\d{2})"];
  numberToStrip.rawInput = @"031123";
  rawInput = numberToStrip.rawInput;
  NSString *transformedNumber = @"5315123";
  XCTAssertTrue([_aUtil maybeStripNationalPrefixAndCarrierCode:&rawInput
                                                      metadata:metadata
                                                   carrierCode:nil]);
  XCTAssertEqualObjects(transformedNumber, rawInput, @"Should transform the 031 to a 5315.");
}

- (void)testMaybeStripInternationalPrefix {
  NSString *internationalPrefix = @"00[39]";

  NSString *numberToStripPrefix = @"0034567700-3898003";

  // Note the dash is removed as part of the normalization.
  NSString *strippedNumberString = @"45677003898003";
  XCTAssertEqual(NBECountryCodeSourceFROM_NUMBER_WITH_IDD,
                 [_aUtil maybeStripInternationalPrefixAndNormalize:&numberToStripPrefix
                                                 possibleIddPrefix:internationalPrefix]);
  XCTAssertEqualObjects(strippedNumberString, numberToStripPrefix,
                        @"The number supplied was not stripped of its international prefix.");
  // Now the number no longer starts with an IDD prefix, so it should now report
  // FROM_DEFAULT_COUNTRY.
  XCTAssertEqual(NBECountryCodeSourceFROM_DEFAULT_COUNTRY,
                 [_aUtil maybeStripInternationalPrefixAndNormalize:&numberToStripPrefix
                                                 possibleIddPrefix:internationalPrefix]);

  numberToStripPrefix = @"00945677003898003";
  XCTAssertEqual(NBECountryCodeSourceFROM_NUMBER_WITH_IDD,
                 [_aUtil maybeStripInternationalPrefixAndNormalize:&numberToStripPrefix
                                                 possibleIddPrefix:internationalPrefix]);
  XCTAssertEqualObjects(strippedNumberString, numberToStripPrefix,
                        @"The number supplied was not stripped of its international prefix.");
  // Test it works when the international prefix is broken up by spaces.
  numberToStripPrefix = @"00 9 45677003898003";
  XCTAssertEqual(NBECountryCodeSourceFROM_NUMBER_WITH_IDD,
                 [_aUtil maybeStripInternationalPrefixAndNormalize:&numberToStripPrefix
                                                 possibleIddPrefix:internationalPrefix]);
  XCTAssertEqualObjects(strippedNumberString, numberToStripPrefix,
                        @"The number supplied was not stripped of its international prefix.");
  // Now the number no longer starts with an IDD prefix, so it should now report
  // FROM_DEFAULT_COUNTRY.
  XCTAssertEqual(NBECountryCodeSourceFROM_DEFAULT_COUNTRY,
                 [_aUtil maybeStripInternationalPrefixAndNormalize:&numberToStripPrefix
                                                 possibleIddPrefix:internationalPrefix]);

  // Test the + symbol is also recognised and stripped.
  numberToStripPrefix = @"+45677003898003";
  strippedNumberString = @"45677003898003";
  XCTAssertEqual(NBECountryCodeSourceFROM_NUMBER_WITH_PLUS_SIGN,
                 [_aUtil maybeStripInternationalPrefixAndNormalize:&numberToStripPrefix
                                                 possibleIddPrefix:internationalPrefix]);
  XCTAssertEqualObjects(strippedNumberString, numberToStripPrefix,
                        @"The number supplied was not stripped of the plus symbol.");

  // If the number afterwards is a zero, we should not strip this - no country
  // calling code begins with 0.
  numberToStripPrefix = @"0090112-3123";
  strippedNumberString = @"00901123123";
  XCTAssertEqual(NBECountryCodeSourceFROM_DEFAULT_COUNTRY,
                 [_aUtil maybeStripInternationalPrefixAndNormalize:&numberToStripPrefix
                                                 possibleIddPrefix:internationalPrefix]);
  XCTAssertEqualObjects(strippedNumberString, numberToStripPrefix,
                        @"The number supplied had a 0 after the match so should not be stripped.");
  // Here the 0 is separated by a space from the IDD.
  numberToStripPrefix = @"009 0-112-3123";
  XCTAssertEqual(NBECountryCodeSourceFROM_DEFAULT_COUNTRY,
                 [_aUtil maybeStripInternationalPrefixAndNormalize:&numberToStripPrefix
                                                 possibleIddPrefix:internationalPrefix]);
}

- (void)testMaybeExtractCountryCode {
  NBPhoneNumber *number = [[NBPhoneNumber alloc] init];
  NBPhoneMetaData *metadata = [self.helper getMetadataForRegion:@"US"];

  // Note that for the US, the IDD is 011.
  NSString *phoneNumber = @"011112-3456789";
  NSString *strippedNumber = @"123456789";
  NSNumber *countryCallingCode = @1;

  NSString *numberToFill = @"";

  {
    NSError *anError = nil;
    XCTAssertEqualObjects(countryCallingCode, [_aUtil maybeExtractCountryCode:phoneNumber
                                                                     metadata:metadata
                                                               nationalNumber:&numberToFill
                                                                 keepRawInput:YES
                                                                  phoneNumber:&number
                                                                        error:&anError]);
    XCTAssertEqual(NBECountryCodeSourceFROM_NUMBER_WITH_IDD,
                   [number.countryCodeSource integerValue]);
    // Should strip and normalize national significant number.
    XCTAssertEqualObjects(strippedNumber, numberToFill);
    if (anError) XCTFail(@"Should not have thrown an exception: %@", anError.description);
  }
  XCTAssertEqual(NBECountryCodeSourceFROM_NUMBER_WITH_IDD, [number.countryCodeSource integerValue],
                 @"Did not figure out CountryCodeSource correctly");
  // Should strip and normalize national significant number.
  XCTAssertEqualObjects(strippedNumber, numberToFill,
                        @"Did not strip off the country calling code correctly.");

  number = [[NBPhoneNumber alloc] init];
  phoneNumber = @"+6423456789";
  countryCallingCode = @64;
  numberToFill = @"";
  XCTAssertEqualObjects(countryCallingCode, [_aUtil maybeExtractCountryCode:phoneNumber
                                                                   metadata:metadata
                                                             nationalNumber:&numberToFill
                                                               keepRawInput:YES
                                                                phoneNumber:&number
                                                                      error:nil]);
  XCTAssertEqual(NBECountryCodeSourceFROM_NUMBER_WITH_PLUS_SIGN,
                 [number.countryCodeSource integerValue],
                 @"Did not figure out CountryCodeSource correctly");

  number = [[NBPhoneNumber alloc] init];
  phoneNumber = @"+80012345678";
  countryCallingCode = @800;
  numberToFill = @"";
  XCTAssertEqualObjects(countryCallingCode, [_aUtil maybeExtractCountryCode:phoneNumber
                                                                   metadata:metadata
                                                             nationalNumber:&numberToFill
                                                               keepRawInput:YES
                                                                phoneNumber:&number
                                                                      error:nil]);
  XCTAssertEqual(NBECountryCodeSourceFROM_NUMBER_WITH_PLUS_SIGN,
                 [number.countryCodeSource integerValue],
                 @"Did not figure out CountryCodeSource correctly");

  number = [[NBPhoneNumber alloc] init];
  phoneNumber = @"2345-6789";
  numberToFill = @"";
  XCTAssertEqual(@0, [_aUtil maybeExtractCountryCode:phoneNumber
                                            metadata:metadata
                                      nationalNumber:&numberToFill
                                        keepRawInput:YES
                                         phoneNumber:&number
                                               error:nil]);
  XCTAssertEqual(NBECountryCodeSourceFROM_DEFAULT_COUNTRY, [number.countryCodeSource integerValue],
                 @"Did not figure out CountryCodeSource correctly");

  number = [[NBPhoneNumber alloc] init];
  phoneNumber = @"0119991123456789";
  numberToFill = @"";
  {
    NSError *anError = nil;
    [_aUtil maybeExtractCountryCode:phoneNumber
                           metadata:metadata
                     nationalNumber:&numberToFill
                       keepRawInput:YES
                        phoneNumber:&number
                              error:&anError];
    if (anError == nil)
      XCTFail(@"Should have thrown an exception, no valid country calling code present.");
    else  // Expected.
      XCTAssertEqualObjects(@"INVALID_COUNTRY_CODE", anError.domain);
  }

  number = [[NBPhoneNumber alloc] init];
  phoneNumber = @"(1 610) 619 4466";
  countryCallingCode = @1;
  numberToFill = @"";
  {
    NSError *anError = nil;
    XCTAssertEqualObjects(
        countryCallingCode,
        [_aUtil maybeExtractCountryCode:phoneNumber
                               metadata:metadata
                         nationalNumber:&numberToFill
                           keepRawInput:YES
                            phoneNumber:&number
                                  error:&anError],
        @"Should have extracted the country calling code of the region passed in");
    XCTAssertEqual(NBECountryCodeSourceFROM_NUMBER_WITHOUT_PLUS_SIGN,
                   [number.countryCodeSource integerValue],
                   @"Did not figure out CountryCodeSource correctly");
  }

  number = [[NBPhoneNumber alloc] init];
  phoneNumber = @"(1 610) 619 4466";
  countryCallingCode = @1;
  numberToFill = @"";
  {
    NSError *anError = nil;
    XCTAssertEqualObjects(countryCallingCode, [_aUtil maybeExtractCountryCode:phoneNumber
                                                                     metadata:metadata
                                                               nationalNumber:&numberToFill
                                                                 keepRawInput:NO
                                                                  phoneNumber:&number
                                                                        error:&anError]);
  }

  number = [[NBPhoneNumber alloc] init];
  phoneNumber = @"(1 610) 619 446";
  numberToFill = @"";
  {
    NSError *anError = nil;
    XCTAssertEqualObjects(@0, [_aUtil maybeExtractCountryCode:phoneNumber
                                                     metadata:metadata
                                               nationalNumber:&numberToFill
                                                 keepRawInput:NO
                                                  phoneNumber:&number
                                                        error:&anError]);
    XCTAssertFalse(number.countryCodeSource != nil, @"Should not contain CountryCodeSource.");
  }

  number = [[NBPhoneNumber alloc] init];
  phoneNumber = @"(1 610) 619";
  numberToFill = @"";
  {
    NSError *anError = nil;
    XCTAssertEqual(@0, [_aUtil maybeExtractCountryCode:phoneNumber
                                              metadata:metadata
                                        nationalNumber:&numberToFill
                                          keepRawInput:YES
                                           phoneNumber:&number
                                                 error:&anError]);
    XCTAssertEqual(NBECountryCodeSourceFROM_DEFAULT_COUNTRY,
                   [number.countryCodeSource integerValue]);
  }
}

- (void)testParseNationalNumber {
  NSError *anError;
  // National prefix attached.
  XCTAssertTrue([self.nzNumber isEqual:[_aUtil parse:@"033316005"
                                           defaultRegion:@"NZ"
                                                   error:&anError]]);
  XCTAssertTrue([self.nzNumber isEqual:[_aUtil parse:@"33316005"
                                           defaultRegion:@"NZ"
                                                   error:&anError]]);

  // National prefix attached and some formatting present.
  XCTAssertTrue([self.nzNumber isEqual:[_aUtil parse:@"03-331 6005"
                                           defaultRegion:@"NZ"
                                                   error:&anError]]);
  XCTAssertTrue([self.nzNumber isEqual:[_aUtil parse:@"03 331 6005"
                                           defaultRegion:@"NZ"
                                                   error:&anError]]);

  // Test parsing RFC3966 format with a phone context.
  XCTAssertTrue([self.nzNumber isEqual:[_aUtil parse:@"tel:03-331-6005;phone-context=+64"
                                           defaultRegion:@"NZ"
                                                   error:&anError]]);
  XCTAssertTrue([self.nzNumber isEqual:[_aUtil parse:@"tel:331-6005;phone-context=+64-3"
                                           defaultRegion:@"NZ"
                                                   error:&anError]]);
  XCTAssertTrue([self.nzNumber isEqual:[_aUtil parse:@"tel:331-6005;phone-context=+64-3"
                                           defaultRegion:@"US"
                                                   error:&anError]]);

  // Test parsing RFC3966 format with optional user-defined parameters. The
  // parameters will appear after the context if present.
  XCTAssertTrue([self.nzNumber isEqual:[_aUtil parse:@"tel:03-331-6005;phone-context=+64;a=%A1"
                                           defaultRegion:@"NZ"
                                                   error:&anError]]);

  // Test parsing RFC3966 with an ISDN subaddress.
  XCTAssertTrue([self.nzNumber isEqual:[_aUtil parse:@"tel:03-331-6005;isub=12345;phone-context=+64"
                                           defaultRegion:@"NZ"
                                                   error:&anError]]);
  XCTAssertTrue([self.nzNumber isEqual:[_aUtil parse:@"tel:+64-3-331-6005;isub=12345"
                                           defaultRegion:@"NZ"
                                                   error:&anError]]);

  // Testing international prefixes.
  // Should strip country calling code.
  XCTAssertTrue([self.nzNumber isEqual:[_aUtil parse:@"0064 3 331 6005"
                                           defaultRegion:@"NZ"
                                                   error:&anError]]);

  // Try again, but this time we have an international number with Region Code
  // US. It should recognise the country calling code and parse accordingly.
  XCTAssertTrue([self.nzNumber isEqual:[_aUtil parse:@"01164 3 331 6005"
                                           defaultRegion:@"US"
                                                   error:&anError]]);
  XCTAssertTrue([self.nzNumber isEqual:[_aUtil parse:@"+64 3 331 6005"
                                           defaultRegion:@"US"
                                                   error:&anError]]);
  // We should ignore the leading plus here, since it is not followed by a valid
  // country code but instead is followed by the IDD for the US.
  XCTAssertTrue([self.nzNumber isEqual:[_aUtil parse:@"+01164 3 331 6005"
                                           defaultRegion:@"US"
                                                   error:&anError]]);
  XCTAssertTrue([self.nzNumber isEqual:[_aUtil parse:@"+0064 3 331 6005"
                                           defaultRegion:@"NZ"
                                                   error:&anError]]);
  XCTAssertTrue([self.nzNumber isEqual:[_aUtil parse:@"+ 00 64 3 331 6005"
                                           defaultRegion:@"NZ"
                                                   error:&anError]]);

  XCTAssertTrue(
      [self.usLocalNumber isEqual:[_aUtil parse:@"tel:253-0000;phone-context=www.google.com"
                                      defaultRegion:@"US"
                                              error:&anError]]);
  XCTAssertTrue([self.usLocalNumber
      isEqual:[_aUtil parse:@"tel:253-0000;isub=12345;phone-context=www.google.com"
                  defaultRegion:@"US"
                          error:&anError]]);
  // This is invalid because no "+" sign is present as part of phone-context.
  // The phone context is simply ignored in this case just as if it contains a
  // domain.
  XCTAssertTrue(
      [self.usLocalNumber isEqual:[_aUtil parse:@"tel:2530000;isub=12345;phone-context=1-650"
                                      defaultRegion:@"US"
                                              error:&anError]]);
  XCTAssertTrue(
      [self.usLocalNumber isEqual:[_aUtil parse:@"tel:2530000;isub=12345;phone-context=1234.com"
                                      defaultRegion:@"US"
                                              error:&anError]]);

  NBPhoneNumber *nzNumber = [[NBPhoneNumber alloc] init];
  [nzNumber setCountryCode:@64];
  [nzNumber setNationalNumber:@64123456];
  XCTAssertTrue([nzNumber isEqual:[_aUtil parse:@"64(0)64123456"
                                      defaultRegion:@"NZ"
                                              error:&anError]]);
  // Check that using a '/' is fine in a phone number.
  XCTAssertTrue([self.deNumber isEqual:[_aUtil parse:@"301/23456"
                                           defaultRegion:@"DE"
                                                   error:&anError]]);

  NBPhoneNumber *usNumber = [[NBPhoneNumber alloc] init];
  // Check it doesn't use the '1' as a country calling code when parsing if the
  // phone number was already possible.
  [usNumber setCountryCode:@1];
  [usNumber setNationalNumber:@1234567890];
  XCTAssertTrue([usNumber isEqual:[_aUtil parse:@"123-456-7890"
                                      defaultRegion:@"US"
                                              error:&anError]]);

  // Test star numbers. Although this is not strictly valid, we would like to
  // make sure we can parse the output we produce when formatting the number.
  NBPhoneNumber *jpStarNumber = [[NBPhoneNumber alloc] init];
  jpStarNumber.countryCode = @81;
  jpStarNumber.nationalNumber = @2345;
  XCTAssertTrue([jpStarNumber isEqual:[_aUtil parse:@"+81 *2345"
                                          defaultRegion:@"JP"
                                                  error:&anError]]);

  NBPhoneNumber *shortNumber = [[NBPhoneNumber alloc] init];
  [shortNumber setCountryCode:@64];
  [shortNumber setNationalNumber:@12];
  XCTAssertTrue([shortNumber isEqual:[_aUtil parse:@"12" defaultRegion:@"NZ" error:&anError]]);
}

- (void)testParseNumberWithAlphaCharacters {
  NSError *anError;
  // Test case with alpha characters.
  NBPhoneNumber *tollfreeNumber = [[NBPhoneNumber alloc] init];
  [tollfreeNumber setCountryCode:@64];
  [tollfreeNumber setNationalNumber:@800332005];
  XCTAssertTrue([tollfreeNumber isEqual:[_aUtil parse:@"0800 DDA 005"
                                            defaultRegion:@"NZ"
                                                    error:&anError]]);

  NBPhoneNumber *premiumNumber = [[NBPhoneNumber alloc] init];
  [premiumNumber setCountryCode:@64];
  [premiumNumber setNationalNumber:@9003326005];
  XCTAssertTrue([premiumNumber isEqual:[_aUtil parse:@"0900 DDA 6005"
                                           defaultRegion:@"NZ"
                                                   error:&anError]]);
  // Not enough alpha characters for them to be considered intentional, so they
  // are stripped.
  XCTAssertTrue([premiumNumber isEqual:[_aUtil parse:@"0900 332 6005a"
                                           defaultRegion:@"NZ"
                                                   error:&anError]]);
  XCTAssertTrue([premiumNumber isEqual:[_aUtil parse:@"0900 332 600a5"
                                           defaultRegion:@"NZ"
                                                   error:&anError]]);
  XCTAssertTrue([premiumNumber isEqual:[_aUtil parse:@"0900 332 600A5"
                                           defaultRegion:@"NZ"
                                                   error:&anError]]);
  XCTAssertTrue([premiumNumber isEqual:[_aUtil parse:@"0900 a332 600A5"
                                           defaultRegion:@"NZ"
                                                   error:&anError]]);
}

- (void)testParseMaliciousInput {
  // Lots of leading + signs before the possible number.

  NSString *maliciousNumber = @"";
  for (int i = 0; i < 6000; i++) {
    maliciousNumber = [maliciousNumber stringByAppendingString:@"+"];
  }

  maliciousNumber = [maliciousNumber stringByAppendingString:@"12222-33-244 extensioB 343+"];
  {
    NSError *anError = nil;
    [_aUtil parse:maliciousNumber defaultRegion:@"US" error:&anError];
    if (anError == nil) {
      XCTFail(@"This should not parse without throwing an exception %@", maliciousNumber);
    } else {
      XCTAssertEqualObjects(@"TOO_LONG", anError.domain, @"Wrong error type stored in exception.");
    }
  }

  NSString *maliciousNumberWithAlmostExt = @"";
  for (int i = 0; i < 350; i++) {
    maliciousNumberWithAlmostExt = [maliciousNumberWithAlmostExt stringByAppendingString:@"200"];
  }

  [maliciousNumberWithAlmostExt stringByAppendingString:@" extensiOB 345"];

  {
    NSError *anError = nil;
    [_aUtil parse:maliciousNumberWithAlmostExt defaultRegion:@"US" error:&anError];
    if (anError == nil) {
      XCTFail(@"This should not parse without throwing an exception %@",
              maliciousNumberWithAlmostExt);
    } else {
      XCTAssertEqualObjects(@"TOO_LONG", anError.domain, @"Wrong error type stored in exception.");
    }
  }
}

- (void)testParseWithInternationalPrefixes {
  NSError *anError = nil;
  XCTAssertTrue([self.usNumber isEqual:[_aUtil parse:@"+1 (650) 253-0000"
                                           defaultRegion:@"NZ"
                                                   error:&anError]]);
  XCTAssertTrue([self.internationalTollFreeNumber isEqual:[_aUtil parse:@"011 800 1234 5678"
                                                              defaultRegion:@"US"
                                                                      error:&anError]]);
  XCTAssertTrue([self.usNumber isEqual:[_aUtil parse:@"1-650-253-0000"
                                           defaultRegion:@"US"
                                                   error:&anError]]);
  // Calling the US number from Singapore by using different service providers
  // 1st test: calling using SingTel IDD service (IDD is 001)
  XCTAssertTrue([self.usNumber isEqual:[_aUtil parse:@"0011-650-253-0000"
                                           defaultRegion:@"SG"
                                                   error:&anError]]);
  // 2nd test: calling using StarHub IDD service (IDD is 008)
  XCTAssertTrue([self.usNumber isEqual:[_aUtil parse:@"0081-650-253-0000"
                                           defaultRegion:@"SG"
                                                   error:&anError]]);
  // 3rd test: calling using SingTel V019 service (IDD is 019)
  XCTAssertTrue([self.usNumber isEqual:[_aUtil parse:@"0191-650-253-0000"
                                           defaultRegion:@"SG"
                                                   error:&anError]]);
  // Calling the US number from Poland
  XCTAssertTrue([self.usNumber isEqual:[_aUtil parse:@"0~01-650-253-0000"
                                           defaultRegion:@"PL"
                                                   error:&anError]]);
  // Using '++' at the start.
  XCTAssertTrue([self.usNumber isEqual:[_aUtil parse:@"++1 (650) 253-0000"
                                           defaultRegion:@"PL"
                                                   error:&anError]]);
}

- (void)testParseNonAscii {
  NSError *anError = nil;
  // Using a full-width plus sign.
  XCTAssertTrue([self.usNumber isEqual:[_aUtil parse:@"\uFF0B1 (650) 253-0000"
                                           defaultRegion:@"SG"
                                                   error:&anError]]);
  // Using a soft hyphen U+00AD.
  XCTAssertTrue([self.usNumber isEqual:[_aUtil parse:@"1 (650) 253\u00AD-0000"
                                           defaultRegion:@"US"
                                                   error:&anError]]);
  // The whole number, including punctuation, is here represented in full-width
  // form.
  XCTAssertTrue(
      [self.usNumber isEqual:[_aUtil parse:@"\uFF0B\uFF11\u3000\uFF08\uFF16\uFF15\uFF10\uFF09\u3000"
                                           @"\uFF12\uFF15\uFF13\uFF0D\uFF10\uFF10\uFF10\uFF10"
                                 defaultRegion:@"SG"
                                         error:&anError]]);
  // Using U+30FC dash instead.
  XCTAssertTrue(
      [self.usNumber isEqual:[_aUtil parse:@"\uFF0B\uFF11\u3000\uFF08\uFF16\uFF15\uFF10\uFF09\u3000"
                                           @"\uFF12\uFF15\uFF13\u30FC\uFF10\uFF10\uFF10\uFF10"
                                 defaultRegion:@"SG"
                                         error:&anError]]);

  // Using a very strange decimal digit range (Mongolian digits).
  // TODO(user): Support Mongolian digits
  // STAssertTrue(self.usNumber isEqual:
  //     [_aUtil parse:@"\u1811 \u1816\u1815\u1810 " +
  //                     '\u1812\u1815\u1813 \u1810\u1810\u1810\u1810" defaultRegion:@"US"], nil);
}

- (void)testParseWithLeadingZero {
  NSError *anError = nil;
  XCTAssertTrue([self.itNumber isEqual:[_aUtil parse:@"+39 02-36618 300"
                                           defaultRegion:@"NZ"
                                                   error:&anError]]);
  XCTAssertTrue([self.itNumber isEqual:[_aUtil parse:@"02-36618 300"
                                           defaultRegion:@"IT"
                                                   error:&anError]]);
  XCTAssertTrue([self.itMobile isEqual:[_aUtil parse:@"345 678 901"
                                           defaultRegion:@"IT"
                                                   error:&anError]]);
}

- (void)testParseNationalNumberArgentina {
  NSError *anError = nil;
  // Test parsing mobile numbers of Argentina.
  NBPhoneNumber *arNumber = [[NBPhoneNumber alloc] init];
  [arNumber setCountryCode:@54];
  [arNumber setNationalNumber:@93435551212];
  XCTAssertTrue([arNumber isEqual:[_aUtil parse:@"+54 9 343 555 1212"
                                      defaultRegion:@"AR"
                                              error:&anError]]);
  XCTAssertTrue([arNumber isEqual:[_aUtil parse:@"0343 15 555 1212"
                                      defaultRegion:@"AR"
                                              error:&anError]]);

  arNumber = [[NBPhoneNumber alloc] init];
  [arNumber setCountryCode:@54];
  [arNumber setNationalNumber:@93715654320];
  XCTAssertTrue([arNumber isEqual:[_aUtil parse:@"+54 9 3715 65 4320"
                                      defaultRegion:@"AR"
                                              error:&anError]]);
  XCTAssertTrue([arNumber isEqual:[_aUtil parse:@"03715 15 65 4320"
                                      defaultRegion:@"AR"
                                              error:&anError]]);
  XCTAssertTrue([self.arMobile isEqual:[_aUtil parse:@"911 876 54321"
                                           defaultRegion:@"AR"
                                                   error:&anError]]);

  // Test parsing fixed-line numbers of Argentina.
  XCTAssertTrue([self.arNumber isEqual:[_aUtil parse:@"+54 11 8765 4321"
                                           defaultRegion:@"AR"
                                                   error:&anError]]);
  XCTAssertTrue([self.arNumber isEqual:[_aUtil parse:@"011 8765 4321"
                                           defaultRegion:@"AR"
                                                   error:&anError]]);

  arNumber = [[NBPhoneNumber alloc] init];
  [arNumber setCountryCode:@54];
  [arNumber setNationalNumber:@3715654321];
  XCTAssertTrue([arNumber isEqual:[_aUtil parse:@"+54 3715 65 4321"
                                      defaultRegion:@"AR"
                                              error:&anError]]);
  XCTAssertTrue([arNumber isEqual:[_aUtil parse:@"03715 65 4321"
                                      defaultRegion:@"AR"
                                              error:&anError]]);

  arNumber = [[NBPhoneNumber alloc] init];
  [arNumber setCountryCode:@54];
  [arNumber setNationalNumber:@2312340000];
  XCTAssertTrue([arNumber isEqual:[_aUtil parse:@"+54 23 1234 0000"
                                      defaultRegion:@"AR"
                                              error:&anError]]);
  XCTAssertTrue([arNumber isEqual:[_aUtil parse:@"023 1234 0000"
                                      defaultRegion:@"AR"
                                              error:&anError]]);
}

- (void)testParseWithXInNumber {
  NSError *anError = nil;
  // Test that having an 'x' in the phone number at the start is ok and that it
  // just gets removed.
  XCTAssertTrue([self.arNumber isEqual:[_aUtil parse:@"01187654321"
                                           defaultRegion:@"AR"
                                                   error:&anError]]);
  XCTAssertTrue([self.arNumber isEqual:[_aUtil parse:@"(0) 1187654321"
                                           defaultRegion:@"AR"
                                                   error:&anError]]);
  XCTAssertTrue([self.arNumber isEqual:[_aUtil parse:@"0 1187654321"
                                           defaultRegion:@"AR"
                                                   error:&anError]]);
  XCTAssertTrue([self.arNumber isEqual:[_aUtil parse:@"(0xx) 1187654321"
                                           defaultRegion:@"AR"
                                                   error:&anError]]);

  id arFromUs = [[NBPhoneNumber alloc] init];
  [arFromUs setCountryCode:@54];
  [arFromUs setNationalNumber:@81429712];
  // This test is intentionally constructed such that the number of digit after
  // xx is larger than 7, so that the number won't be mistakenly treated as an
  // extension, as we allow extensions up to 7 digits. This assumption is okay
  // for now as all the countries where a carrier selection code is written in
  // the form of xx have a national significant number of length larger than 7.
  XCTAssertTrue([arFromUs isEqual:[_aUtil parse:@"011xx5481429712"
                                      defaultRegion:@"US"
                                              error:&anError]]);
}

- (void)testParseNumbersMexico {
  NSError *anError = nil;
  // Test parsing fixed-line numbers of Mexico.

  id mxNumber = [[NBPhoneNumber alloc] init];
  [mxNumber setCountryCode:@52];
  [mxNumber setNationalNumber:@4499780001];
  XCTAssertTrue([mxNumber isEqual:[_aUtil parse:@"+52 (449)978-0001"
                                      defaultRegion:@"MX"
                                              error:&anError]]);
  XCTAssertTrue([mxNumber isEqual:[_aUtil parse:@"01 (449)978-0001"
                                      defaultRegion:@"MX"
                                              error:&anError]]);
  XCTAssertTrue([mxNumber isEqual:[_aUtil parse:@"(449)978-0001"
                                      defaultRegion:@"MX"
                                              error:&anError]]);

  // Test parsing mobile numbers of Mexico.
  mxNumber = [[NBPhoneNumber alloc] init];
  [mxNumber setCountryCode:@52];
  [mxNumber setNationalNumber:@13312345678];
  XCTAssertTrue([mxNumber isEqual:[_aUtil parse:@"+52 1 33 1234-5678"
                                      defaultRegion:@"MX"
                                              error:&anError]]);
  XCTAssertTrue([mxNumber isEqual:[_aUtil parse:@"044 (33) 1234-5678"
                                      defaultRegion:@"MX"
                                              error:&anError]]);
  XCTAssertTrue([mxNumber isEqual:[_aUtil parse:@"045 33 1234-5678"
                                      defaultRegion:@"MX"
                                              error:&anError]]);
}

- (void)testFailedParseOnInvalidNumbers {
  {
    NSError *anError = nil;
    NSString *sentencePhoneNumber = @"This is not a phone number";
    [_aUtil parse:sentencePhoneNumber defaultRegion:@"NZ" error:&anError];

    if (anError == nil)
      XCTFail(@"This should not parse without throwing an exception %@", sentencePhoneNumber);
    else
      // Expected this exception.
      XCTAssertEqualObjects(@"NOT_A_NUMBER", anError.domain,
                            @"Wrong error type stored in exception.");
  }
  {
    NSError *anError = nil;
    NSString *sentencePhoneNumber = @"1 Still not a number";
    [_aUtil parse:sentencePhoneNumber defaultRegion:@"NZ" error:&anError];

    if (anError == nil)
      XCTFail(@"This should not parse without throwing an exception %@", sentencePhoneNumber);
    else
      // Expected this exception.
      XCTAssertEqualObjects(@"NOT_A_NUMBER", anError.domain,
                            @"Wrong error type stored in exception.");
  }

  {
    NSError *anError = nil;
    NSString *sentencePhoneNumber = @"1 MICROSOFT";
    [_aUtil parse:sentencePhoneNumber defaultRegion:@"NZ" error:&anError];

    if (anError == nil)
      XCTFail(@"This should not parse without throwing an exception %@", sentencePhoneNumber);
    else
      // Expected this exception.
      XCTAssertEqualObjects(@"NOT_A_NUMBER", anError.domain,
                            @"Wrong error type stored in exception.");
  }

  {
    NSError *anError = nil;
    NSString *sentencePhoneNumber = @"12 MICROSOFT";
    [_aUtil parse:sentencePhoneNumber defaultRegion:@"NZ" error:&anError];

    if (anError == nil)
      XCTFail(@"This should not parse without throwing an exception %@", sentencePhoneNumber);
    else
      // Expected this exception.
      XCTAssertEqualObjects(@"NOT_A_NUMBER", anError.domain,
                            @"Wrong error type stored in exception.");
  }

  {
    NSError *anError = nil;
    NSString *tooLongPhoneNumber = @"01495 72553301873 810104";
    [_aUtil parse:tooLongPhoneNumber defaultRegion:@"GB" error:&anError];

    if (anError == nil)
      XCTFail(@"This should not parse without throwing an exception %@", tooLongPhoneNumber);
    else
      // Expected this exception.
      XCTAssertEqualObjects(@"TOO_LONG", anError.domain, @"Wrong error type stored in exception.");
  }

  {
    NSError *anError = nil;
    NSString *plusMinusPhoneNumber = @"+---";
    [_aUtil parse:plusMinusPhoneNumber defaultRegion:@"DE" error:&anError];

    if (anError == nil)
      XCTFail(@"This should not parse without throwing an exception %@", plusMinusPhoneNumber);
    else
      // Expected this exception.
      XCTAssertEqualObjects(@"NOT_A_NUMBER", anError.domain,
                            @"Wrong error type stored in exception.");
  }

  {
    NSError *anError = nil;
    NSString *plusStar = @"+***";
    [_aUtil parse:plusStar defaultRegion:@"DE" error:&anError];
    if (anError == nil)
      XCTFail(@"This should not parse without throwing an exception %@", plusStar);
    else
      // Expected this exception.
      XCTAssertEqualObjects(@"NOT_A_NUMBER", anError.domain,
                            @"Wrong error type stored in exception.");
  }

  {
    NSError *anError = nil;
    NSString *plusStarPhoneNumber = @"+*******91";
    [_aUtil parse:plusStarPhoneNumber defaultRegion:@"DE" error:&anError];
    if (anError == nil)
      XCTFail(@"This should not parse without throwing an exception %@", plusStarPhoneNumber);
    else
      // Expected this exception.
      XCTAssertEqualObjects(@"NOT_A_NUMBER", anError.domain,
                            @"Wrong error type stored in exception.");
  }

  {
    NSError *anError = nil;
    NSString *tooShortPhoneNumber = @"+49 0";
    [_aUtil parse:tooShortPhoneNumber defaultRegion:@"DE" error:&anError];
    if (anError == nil)
      XCTFail(@"This should not parse without throwing an exception %@", tooShortPhoneNumber);
    else
      // Expected this exception.
      XCTAssertEqualObjects(@"TOO_SHORT_NSN", anError.domain,
                            @"Wrong error type stored in exception.");
  }

  {
    NSError *anError = nil;
    NSString *invalidcountryCode = @"+210 3456 56789";
    [_aUtil parse:invalidcountryCode defaultRegion:@"NZ" error:&anError];
    if (anError == nil)
      XCTFail(@"This is not a recognised region code: should fail: %@", invalidcountryCode);
    else
      // Expected this exception.
      XCTAssertEqualObjects(@"INVALID_COUNTRY_CODE", anError.domain,
                            @"Wrong error type stored in exception.");
  }

  {
    NSError *anError = nil;
    NSString *plusAndIddAndInvalidcountryCode = @"+ 00 210 3 331 6005";
    [_aUtil parse:plusAndIddAndInvalidcountryCode defaultRegion:@"NZ" error:&anError];
    if (anError == nil)
      XCTFail(@"This should not parse without throwing an exception.");
    else {
      // Expected this exception. 00 is a correct IDD, but 210 is not a valid
      // country code.
      XCTAssertEqualObjects(@"INVALID_COUNTRY_CODE", anError.domain,
                            @"Wrong error type stored in exception.");
    }
  }

  {
    NSError *anError = nil;
    NSString *someNumber = @"123 456 7890";
    [_aUtil parse:someNumber defaultRegion:NB_UNKNOWN_REGION error:&anError];
    if (anError == nil)
      XCTFail(@"Unknown region code not allowed: should fail.");
    else
      // Expected this exception.
      XCTAssertEqualObjects(@"INVALID_COUNTRY_CODE", anError.domain,
                            @"Wrong error type stored in exception.");
  }

  {
    NSError *anError = nil;
    NSString *someNumber = @"123 456 7890";
    [_aUtil parse:someNumber defaultRegion:@"CS" error:&anError];
    if (anError == nil)
      XCTFail(@"Deprecated region code not allowed: should fail.");
    else
      // Expected this exception.
      XCTAssertEqualObjects(@"INVALID_COUNTRY_CODE", anError.domain,
                            @"Wrong error type stored in exception.");
  }

  {
    NSError *anError = nil;
    NSString *someNumber = @"123 456 7890";
    [_aUtil parse:someNumber defaultRegion:nil error:&anError];
    if (anError == nil)
      XCTFail(@"nil region code not allowed: should fail.");
    else
      // Expected this exception.
      XCTAssertEqualObjects(@"INVALID_COUNTRY_CODE", anError.domain,
                            @"Wrong error type stored in exception.");
  }

  {
    NSError *anError = nil;
    NSString *someNumber = @"0044------";
    [_aUtil parse:someNumber defaultRegion:@"GB" error:&anError];
    if (anError == nil)
      XCTFail(@"No number provided, only region code: should fail");
    else
      // Expected this exception.
      XCTAssertEqualObjects(@"TOO_SHORT_AFTER_IDD", anError.domain,
                            @"Wrong error type stored in exception.");
  }

  {
    NSError *anError = nil;
    NSString *someNumber = @"0044";
    [_aUtil parse:someNumber defaultRegion:@"GB" error:&anError];
    if (anError == nil)
      XCTFail(@"No number provided, only region code: should fail");
    else
      // Expected this exception.
      XCTAssertEqualObjects(@"TOO_SHORT_AFTER_IDD", anError.domain,
                            @"Wrong error type stored in exception.");
  }

  {
    NSError *anError = nil;
    NSString *someNumber = @"011";
    [_aUtil parse:someNumber defaultRegion:@"US" error:&anError];
    if (anError == nil)
      XCTFail(@"Only IDD provided - should fail.");
    else
      // Expected this exception.
      XCTAssertEqualObjects(@"TOO_SHORT_AFTER_IDD", anError.domain,
                            @"Wrong error type stored in exception.");
  }

  {
    NSError *anError = nil;
    NSString *someNumber = @"0119";
    [_aUtil parse:someNumber defaultRegion:@"US" error:&anError];
    if (anError == nil)
      XCTFail(@"Only IDD provided and then 9 - should fail.");
    else
      // Expected this exception.
      XCTAssertEqualObjects(@"TOO_SHORT_AFTER_IDD", anError.domain,
                            @"Wrong error type stored in exception.");
  }

  {
    NSError *anError = nil;
    NSString *emptyNumber = @"";
    // Invalid region.
    [_aUtil parse:emptyNumber defaultRegion:NB_UNKNOWN_REGION error:&anError];
    if (anError == nil)
      XCTFail(@"Empty string - should fail.");
    else
      // Expected this exception.
      XCTAssertEqualObjects(@"NOT_A_NUMBER", anError.domain,
                            @"Wrong error type stored in exception.");
  }

  {
    NSError *anError = nil;
    // Invalid region.
    [_aUtil parse:nil defaultRegion:NB_UNKNOWN_REGION error:&anError];
    if (anError == nil)
      XCTFail(@"nil string - should fail.");
    else
      // Expected this exception.
      XCTAssertEqualObjects(@"NOT_A_NUMBER", anError.domain,
                            @"Wrong error type stored in exception.");
  }

  {
    NSError *anError = nil;
    [_aUtil parse:nil defaultRegion:@"US" error:&anError];
    if (anError == nil)
      XCTFail(@"nil string - should fail.");
    else
      // Expected this exception.
      XCTAssertEqualObjects(@"NOT_A_NUMBER", anError.domain,
                            @"Wrong error type stored in exception.");
  }

  {
    NSError *anError = nil;
    NSString *domainRfcPhoneContext = @"tel:555-1234;phone-context=www.google.com";
    [_aUtil parse:domainRfcPhoneContext defaultRegion:NB_UNKNOWN_REGION error:&anError];
    if (anError == nil)
      XCTFail(@"Unknown region code not allowed: should fail.");
    else
      // Expected this exception.
      XCTAssertEqualObjects(@"INVALID_COUNTRY_CODE", anError.domain,
                            @"Wrong error type stored in exception.");
  }

  {
    NSError *anError = nil;
    // This is invalid because no '+' sign is present as part of phone-context.
    // This should not succeed in being parsed.

    NSString *invalidRfcPhoneContext = @"tel:555-1234;phone-context=1-331";
    [_aUtil parse:invalidRfcPhoneContext defaultRegion:NB_UNKNOWN_REGION error:&anError];
    if (anError == nil)
      XCTFail(@"Unknown region code not allowed: should fail.");
    else
      // Expected this exception.
      XCTAssertEqualObjects(@"INVALID_COUNTRY_CODE", anError.domain,
                            @"Wrong error type stored in exception.");
  }
}

- (void)testParseNumbersWithPlusWithNoRegion {
  NSError *anError;
  // @"ZZ is allowed only if the number starts with a '+' - then the
  // country calling code can be calculated.
  XCTAssertTrue([self.nzNumber isEqual:[_aUtil parse:@"+64 3 331 6005"
                                           defaultRegion:NB_UNKNOWN_REGION
                                                   error:&anError]]);
  // Test with full-width plus.
  XCTAssertTrue([self.nzNumber isEqual:[_aUtil parse:@"\uFF0B64 3 331 6005"
                                           defaultRegion:NB_UNKNOWN_REGION
                                                   error:&anError]]);
  // Test with normal plus but leading characters that need to be stripped.
  XCTAssertTrue([self.nzNumber isEqual:[_aUtil parse:@"Tel: +64 3 331 6005"
                                           defaultRegion:NB_UNKNOWN_REGION
                                                   error:&anError]]);
  XCTAssertTrue([self.nzNumber isEqual:[_aUtil parse:@"+64 3 331 6005"
                                           defaultRegion:nil
                                                   error:&anError]]);
  XCTAssertTrue([self.internationalTollFreeNumber isEqual:[_aUtil parse:@"+800 1234 5678"
                                                              defaultRegion:nil
                                                                      error:&anError]]);
  XCTAssertTrue([self.universalPremiumRateNumber isEqual:[_aUtil parse:@"+979 123 456 789"
                                                             defaultRegion:nil
                                                                     error:&anError]]);

  // Test parsing RFC3966 format with a phone context.
  XCTAssertTrue([self.nzNumber isEqual:[_aUtil parse:@"tel:03-331-6005;phone-context=+64"
                                           defaultRegion:NB_UNKNOWN_REGION
                                                   error:&anError]]);
  XCTAssertTrue([self.nzNumber isEqual:[_aUtil parse:@"  tel:03-331-6005;phone-context=+64"
                                           defaultRegion:NB_UNKNOWN_REGION
                                                   error:&anError]]);
  XCTAssertTrue([self.nzNumber isEqual:[_aUtil parse:@"tel:03-331-6005;isub=12345;phone-context=+64"
                                           defaultRegion:NB_UNKNOWN_REGION
                                                   error:&anError]]);

  // It is important that we set the carrier code to an empty string, since we
  // used ParseAndKeepRawInput and no carrier code was found.

  id nzNumberWithRawInput = self.nzNumber;
  [nzNumberWithRawInput setRawInput:@"+64 3 331 6005"];
  [nzNumberWithRawInput
      setCountryCodeSource:[NSNumber
                               numberWithInteger:NBECountryCodeSourceFROM_NUMBER_WITH_PLUS_SIGN]];
  [nzNumberWithRawInput setPreferredDomesticCarrierCode:@""];
  XCTAssertTrue([nzNumberWithRawInput isEqual:[_aUtil parseAndKeepRawInput:@"+64 3 331 6005"
                                                             defaultRegion:NB_UNKNOWN_REGION
                                                                     error:&anError]]);
  // nil is also allowed for the region code in these cases.
  XCTAssertTrue([nzNumberWithRawInput isEqual:[_aUtil parseAndKeepRawInput:@"+64 3 331 6005"
                                                             defaultRegion:nil
                                                                     error:&anError]]);
}

- (void)testParseExtensions {
  NSError *anError = nil;
  NBPhoneNumber *nzNumber = [[NBPhoneNumber alloc] init];
  [nzNumber setCountryCode:@64];
  [nzNumber setNationalNumber:@33316005];
  [nzNumber setExtension:@"3456"];
  XCTAssertTrue([nzNumber isEqual:[_aUtil parse:@"03 331 6005 ext 3456"
                                      defaultRegion:@"NZ"
                                              error:&anError]]);
  XCTAssertTrue([nzNumber isEqual:[_aUtil parse:@"03-3316005x3456"
                                      defaultRegion:@"NZ"
                                              error:&anError]]);
  XCTAssertTrue([nzNumber isEqual:[_aUtil parse:@"03-3316005 int.3456"
                                      defaultRegion:@"NZ"
                                              error:&anError]]);
  XCTAssertTrue([nzNumber isEqual:[_aUtil parse:@"03 3316005 #3456"
                                      defaultRegion:@"NZ"
                                              error:&anError]]);

  // Test the following do not extract extensions:
  XCTAssertTrue([self.alphaNumbericNumber isEqual:[_aUtil parse:@"1800 six-flags"
                                                      defaultRegion:@"US"
                                                              error:&anError]]);
  XCTAssertTrue([self.alphaNumbericNumber isEqual:[_aUtil parse:@"1800 SIX FLAGS"
                                                      defaultRegion:@"US"
                                                              error:&anError]]);
  XCTAssertTrue([self.alphaNumbericNumber isEqual:[_aUtil parse:@"0~0 1800 7493 5247"
                                                      defaultRegion:@"PL"
                                                              error:&anError]]);
  XCTAssertTrue([self.alphaNumbericNumber isEqual:[_aUtil parse:@"(1800) 7493.5247"
                                                      defaultRegion:@"US"
                                                              error:&anError]]);

  // Check that the last instance of an extension token is matched.

  id extnNumber = self.alphaNumbericNumber;
  [extnNumber setExtension:@"1234"];
  XCTAssertTrue([extnNumber isEqual:[_aUtil parse:@"0~0 1800 7493 5247 ~1234"
                                        defaultRegion:@"PL"
                                                error:&anError]]);

  // Verifying bug-fix where the last digit of a number was previously omitted
  // if it was a 0 when extracting the extension. Also verifying a few different
  // cases of extensions.

  id ukNumber = [[NBPhoneNumber alloc] init];
  [ukNumber setCountryCode:@44];
  [ukNumber setNationalNumber:@2034567890];
  [ukNumber setExtension:@"456"];
  XCTAssertTrue([ukNumber isEqual:[_aUtil parse:@"+44 2034567890x456"
                                      defaultRegion:@"NZ"
                                              error:&anError]]);
  XCTAssertTrue([ukNumber isEqual:[_aUtil parse:@"+44 2034567890x456"
                                      defaultRegion:@"GB"
                                              error:&anError]]);
  XCTAssertTrue([ukNumber isEqual:[_aUtil parse:@"+44 2034567890 x456"
                                      defaultRegion:@"GB"
                                              error:&anError]]);
  XCTAssertTrue([ukNumber isEqual:[_aUtil parse:@"+44 2034567890 X456"
                                      defaultRegion:@"GB"
                                              error:&anError]]);
  XCTAssertTrue([ukNumber isEqual:[_aUtil parse:@"+44 2034567890 X 456"
                                      defaultRegion:@"GB"
                                              error:&anError]]);
  XCTAssertTrue([ukNumber isEqual:[_aUtil parse:@"+44 2034567890 X  456"
                                      defaultRegion:@"GB"
                                              error:&anError]]);
  XCTAssertTrue([ukNumber isEqual:[_aUtil parse:@"+44 2034567890 x 456  "
                                      defaultRegion:@"GB"
                                              error:&anError]]);
  XCTAssertTrue([ukNumber isEqual:[_aUtil parse:@"+44 2034567890  X 456"
                                      defaultRegion:@"GB"
                                              error:&anError]]);
  XCTAssertTrue([ukNumber isEqual:[_aUtil parse:@"+44-2034567890;ext=456"
                                      defaultRegion:@"GB"
                                              error:&anError]]);
  XCTAssertTrue([ukNumber isEqual:[_aUtil parse:@"tel:2034567890;ext=456;phone-context=+44"
                                      defaultRegion:NB_UNKNOWN_REGION
                                              error:&anError]]);
  // Full-width extension, @"extn' only.
  XCTAssertTrue([ukNumber isEqual:[_aUtil parse:@"+442034567890\uFF45\uFF58\uFF54\uFF4E456"
                                      defaultRegion:@"GB"
                                              error:&anError]]);
  // 'xtn' only.
  XCTAssertTrue([ukNumber isEqual:[_aUtil parse:@"+442034567890\uFF58\uFF54\uFF4E456"
                                      defaultRegion:@"GB"
                                              error:&anError]]);
  // 'xt' only.
  XCTAssertTrue([ukNumber isEqual:[_aUtil parse:@"+442034567890\uFF58\uFF54456"
                                      defaultRegion:@"GB"
                                              error:&anError]]);

  id usWithExtension = [[NBPhoneNumber alloc] init];
  [usWithExtension setCountryCode:@1];
  [usWithExtension setNationalNumber:@8009013355];
  [usWithExtension setExtension:@"7246433"];
  XCTAssertTrue([usWithExtension isEqual:[_aUtil parse:@"(800) 901-3355 x 7246433"
                                             defaultRegion:@"US"
                                                     error:&anError]]);
  XCTAssertTrue([usWithExtension isEqual:[_aUtil parse:@"(800) 901-3355 , ext 7246433"
                                             defaultRegion:@"US"
                                                     error:&anError]]);
  XCTAssertTrue([usWithExtension isEqual:[_aUtil parse:@"(800) 901-3355 ,extension 7246433"
                                             defaultRegion:@"US"
                                                     error:&anError]]);
  XCTAssertTrue([usWithExtension isEqual:[_aUtil parse:@"(800) 901-3355 ,extensi\u00F3n 7246433"
                                             defaultRegion:@"US"
                                                     error:&anError]]);

  // Repeat with the small letter o with acute accent created by combining
  // characters.
  XCTAssertTrue([usWithExtension isEqual:[_aUtil parse:@"(800) 901-3355 ,extensio\u0301n 7246433"
                                             defaultRegion:@"US"
                                                     error:&anError]]);
  XCTAssertTrue([usWithExtension isEqual:[_aUtil parse:@"(800) 901-3355 , 7246433"
                                             defaultRegion:@"US"
                                                     error:&anError]]);
  XCTAssertTrue([usWithExtension isEqual:[_aUtil parse:@"(800) 901-3355 ext: 7246433"
                                             defaultRegion:@"US"
                                                     error:&anError]]);

  // Test that if a number has two extensions specified, we ignore the second.
  id usWithTwoExtensionsNumber = [[NBPhoneNumber alloc] init];
  [usWithTwoExtensionsNumber setCountryCode:@1];
  [usWithTwoExtensionsNumber setNationalNumber:@2121231234];
  [usWithTwoExtensionsNumber setExtension:@"508"];
  XCTAssertTrue([usWithTwoExtensionsNumber isEqual:[_aUtil parse:@"(212)123-1234 x508/x1234"
                                                       defaultRegion:@"US"
                                                               error:&anError]]);
  XCTAssertTrue([usWithTwoExtensionsNumber isEqual:[_aUtil parse:@"(212)123-1234 x508/ x1234"
                                                       defaultRegion:@"US"
                                                               error:&anError]]);
  XCTAssertTrue([usWithTwoExtensionsNumber isEqual:[_aUtil parse:@"(212)123-1234 x508\\x1234"
                                                       defaultRegion:@"US"
                                                               error:&anError]]);

  // Test parsing numbers in the form (645) 123-1234-910# works, where the last
  // 3 digits before the # are an extension.
  usWithExtension = [[NBPhoneNumber alloc] init];
  [usWithExtension setCountryCode:@1];
  [usWithExtension setNationalNumber:@6451231234];
  [usWithExtension setExtension:@"910"];
  XCTAssertTrue([usWithExtension isEqual:[_aUtil parse:@"+1 (645) 123 1234-910#"
                                             defaultRegion:@"US"
                                                     error:&anError]]);
  // Retry with the same number in a slightly different format.
  XCTAssertTrue([usWithExtension isEqual:[_aUtil parse:@"+1 (645) 123 1234 ext. 910#"
                                             defaultRegion:@"US"
                                                     error:&anError]]);
}

- (void)testParseAndKeepRaw {
  NSError *anError;
  NBPhoneNumber *alphaNumericNumber = self.alphaNumbericNumber;
  [alphaNumericNumber setRawInput:@"800 six-flags"];
  [alphaNumericNumber
      setCountryCodeSource:[NSNumber numberWithInteger:NBECountryCodeSourceFROM_DEFAULT_COUNTRY]];
  [alphaNumericNumber setPreferredDomesticCarrierCode:@""];
  XCTAssertTrue([alphaNumericNumber isEqual:[_aUtil parseAndKeepRawInput:@"800 six-flags"
                                                           defaultRegion:@"US"
                                                                   error:&anError]]);

  id shorterAlphaNumber = [[NBPhoneNumber alloc] init];
  [shorterAlphaNumber setCountryCode:@1];
  [shorterAlphaNumber setNationalNumber:@8007493524];
  [shorterAlphaNumber setRawInput:@"1800 six-flag"];
  [shorterAlphaNumber
      setCountryCodeSource:
          [NSNumber numberWithInteger:NBECountryCodeSourceFROM_NUMBER_WITHOUT_PLUS_SIGN]];
  [shorterAlphaNumber setPreferredDomesticCarrierCode:@""];
  XCTAssertTrue([shorterAlphaNumber isEqual:[_aUtil parseAndKeepRawInput:@"1800 six-flag"
                                                           defaultRegion:@"US"
                                                                   error:&anError]]);

  [shorterAlphaNumber setRawInput:@"+1800 six-flag"];
  [shorterAlphaNumber
      setCountryCodeSource:[NSNumber
                               numberWithInteger:NBECountryCodeSourceFROM_NUMBER_WITH_PLUS_SIGN]];
  XCTAssertTrue([shorterAlphaNumber isEqual:[_aUtil parseAndKeepRawInput:@"+1800 six-flag"
                                                           defaultRegion:@"NZ"
                                                                   error:&anError]]);

  [alphaNumericNumber setCountryCode:@1];
  [alphaNumericNumber setNationalNumber:@8007493524];
  [alphaNumericNumber setRawInput:@"001800 six-flag"];
  [alphaNumericNumber
      setCountryCodeSource:[NSNumber numberWithInteger:NBECountryCodeSourceFROM_NUMBER_WITH_IDD]];
  XCTAssertTrue([alphaNumericNumber isEqual:[_aUtil parseAndKeepRawInput:@"001800 six-flag"
                                                           defaultRegion:@"NZ"
                                                                   error:&anError]]);

  // Invalid region code supplied.
  {
    [_aUtil parseAndKeepRawInput:@"123 456 7890" defaultRegion:@"CS" error:&anError];
    if (anError == nil)
      XCTFail(@"Deprecated region code not allowed: should fail.");
    else {
      // Expected this exception.
      XCTAssertEqualObjects(@"INVALID_COUNTRY_CODE", anError.domain,
                            @"Wrong error type stored in exception.");
    }
  }

  id koreanNumber = [[NBPhoneNumber alloc] init];
  [koreanNumber setCountryCode:@82];
  [koreanNumber setNationalNumber:@22123456];
  [koreanNumber setRawInput:@"08122123456"];
  [koreanNumber
      setCountryCodeSource:[NSNumber numberWithInteger:NBECountryCodeSourceFROM_DEFAULT_COUNTRY]];
  [koreanNumber setPreferredDomesticCarrierCode:@"81"];
  XCTAssertTrue([koreanNumber isEqual:[_aUtil parseAndKeepRawInput:@"08122123456"
                                                     defaultRegion:@"KR"
                                                             error:&anError]]);
}

- (void)testCountryWithNoNumberDesc {
  // Andorra is a country where we don't have PhoneNumberDesc info in the
  // metadata.
  NBPhoneNumber *adNumber = [[NBPhoneNumber alloc] init];
  [adNumber setCountryCode:@376];
  [adNumber setNationalNumber:@12345];
  XCTAssertEqualObjects(@"+376 12345", [_aUtil format:adNumber
                                           numberFormat:NBEPhoneNumberFormatINTERNATIONAL]);
  XCTAssertEqualObjects(@"+37612345", [_aUtil format:adNumber
                                          numberFormat:NBEPhoneNumberFormatE164]);
  XCTAssertEqualObjects(@"12345", [_aUtil format:adNumber
                                      numberFormat:NBEPhoneNumberFormatNATIONAL]);
  XCTAssertEqual(NBEPhoneNumberTypeUNKNOWN, [_aUtil getNumberType:adNumber]);
  XCTAssertFalse([_aUtil isValidNumber:adNumber]);

  // Test dialing a US number from within Andorra.
  XCTAssertEqualObjects(@"00 1 650 253 0000", [_aUtil formatOutOfCountryCallingNumber:self.usNumber
                                                                    regionCallingFrom:@"AD"]);
}

- (void)testUnknownCountryCallingCode {
  XCTAssertFalse([_aUtil isValidNumber:self.unknownCountryCodeNoRawInput]);
  // It's not very well defined as to what the E164 representation for a number
  // with an invalid country calling code is, but just prefixing the country
  // code and national number is about the best we can do.
  XCTAssertEqualObjects(@"+212345", [_aUtil format:self.unknownCountryCodeNoRawInput
                                        numberFormat:NBEPhoneNumberFormatE164]);
}

- (void)testIsNumberMatchMatches {
  // Test simple matches where formatting is different, or leading zeroes,
  // or country calling code has been specified.

  NSError *anError = nil;

  NBPhoneNumber *num1 = [_aUtil parse:@"+64 3 331 6005" defaultRegion:@"NZ" error:&anError];
  NBPhoneNumber *num2 = [_aUtil parse:@"+64 03 331 6005" defaultRegion:@"NZ" error:&anError];
  XCTAssertEqual(NBEMatchTypeEXACT_MATCH, [_aUtil isNumberMatch:num1 second:num2]);
  XCTAssertEqual(NBEMatchTypeEXACT_MATCH, [_aUtil isNumberMatch:@"+64 3 331 6005"
                                                         second:@"+64 03 331 6005"]);
  XCTAssertEqual(NBEMatchTypeEXACT_MATCH, [_aUtil isNumberMatch:@"+800 1234 5678"
                                                         second:@"+80012345678"]);
  XCTAssertEqual(NBEMatchTypeEXACT_MATCH, [_aUtil isNumberMatch:@"+64 03 331-6005"
                                                         second:@"+64 03331 6005"]);
  XCTAssertEqual(NBEMatchTypeEXACT_MATCH, [_aUtil isNumberMatch:@"+643 331-6005"
                                                         second:@"+64033316005"]);
  XCTAssertEqual(NBEMatchTypeEXACT_MATCH, [_aUtil isNumberMatch:@"+643 331-6005"
                                                         second:@"+6433316005"]);
  XCTAssertEqual(NBEMatchTypeEXACT_MATCH, [_aUtil isNumberMatch:@"+64 3 331-6005"
                                                         second:@"+6433316005"]);
  XCTAssertEqual(NBEMatchTypeEXACT_MATCH, [_aUtil isNumberMatch:@"+64 3 331-6005"
                                                         second:@"tel:+64-3-331-6005;isub=123"]);
  // Test alpha numbers.
  XCTAssertEqual(NBEMatchTypeEXACT_MATCH, [_aUtil isNumberMatch:@"+1800 siX-Flags"
                                                         second:@"+1 800 7493 5247"]);
  // Test numbers with extensions.
  XCTAssertEqual(NBEMatchTypeEXACT_MATCH, [_aUtil isNumberMatch:@"+64 3 331-6005 extn 1234"
                                                         second:@"+6433316005#1234"]);
  // Test proto buffers.
  XCTAssertEqual(NBEMatchTypeEXACT_MATCH, [_aUtil isNumberMatch:self.nzNumber
                                                         second:@"+6403 331 6005"]);

  NBPhoneNumber *nzNumber = self.nzNumber;
  [nzNumber setExtension:@"3456"];
  XCTAssertEqual(NBEMatchTypeEXACT_MATCH, [_aUtil isNumberMatch:nzNumber
                                                         second:@"+643 331 6005 ext 3456"]);
  // Check empty extensions are ignored.
  [nzNumber setExtension:@""];
  XCTAssertEqual(NBEMatchTypeEXACT_MATCH, [_aUtil isNumberMatch:nzNumber second:@"+6403 331 6005"]);
  // Check variant with two proto buffers.
  XCTAssertEqual(NBEMatchTypeEXACT_MATCH, [_aUtil isNumberMatch:nzNumber second:self.nzNumber],
                 @"Numbers did not match");

  // Check raw_input, country_code_source and preferred_domestic_carrier_code
  // are ignored.

  NBPhoneNumber *brNumberOne = [[NBPhoneNumber alloc] init];

  NBPhoneNumber *brNumberTwo = [[NBPhoneNumber alloc] init];
  [brNumberOne setCountryCode:@55];
  [brNumberOne setNationalNumber:@3121286979];
  [brNumberOne
      setCountryCodeSource:[NSNumber
                               numberWithInteger:NBECountryCodeSourceFROM_NUMBER_WITH_PLUS_SIGN]];
  [brNumberOne setPreferredDomesticCarrierCode:@"12"];
  [brNumberOne setRawInput:@"012 3121286979"];
  [brNumberTwo setCountryCode:@55];
  [brNumberTwo setNationalNumber:@3121286979];
  [brNumberTwo
      setCountryCodeSource:[NSNumber numberWithInteger:NBECountryCodeSourceFROM_DEFAULT_COUNTRY]];
  [brNumberTwo setPreferredDomesticCarrierCode:@"14"];
  [brNumberTwo setRawInput:@"143121286979"];
  XCTAssertEqual(NBEMatchTypeEXACT_MATCH, [_aUtil isNumberMatch:brNumberOne second:brNumberTwo]);
}

- (void)testIsNumberMatchNonMatches {
  // Non-matches.
  XCTAssertEqual(NBEMatchTypeNO_MATCH, [_aUtil isNumberMatch:@"03 331 6005" second:@"03 331 6006"]);
  XCTAssertEqual(NBEMatchTypeNO_MATCH, [_aUtil isNumberMatch:@"+800 1234 5678"
                                                      second:@"+1 800 1234 5678"]);
  // Different country calling code, partial number match.
  XCTAssertEqual(NBEMatchTypeNO_MATCH, [_aUtil isNumberMatch:@"+64 3 331-6005"
                                                      second:@"+16433316005"]);
  // Different country calling code, same number.
  XCTAssertEqual(NBEMatchTypeNO_MATCH, [_aUtil isNumberMatch:@"+64 3 331-6005"
                                                      second:@"+6133316005"]);
  // Extension different, all else the same.
  XCTAssertEqual(NBEMatchTypeNO_MATCH, [_aUtil isNumberMatch:@"+64 3 331-6005 extn 1234"
                                                      second:@"0116433316005#1235"]);
  XCTAssertEqual(NBEMatchTypeNO_MATCH, [_aUtil isNumberMatch:@"+64 3 331-6005 extn 1234"
                                                      second:@"tel:+64-3-331-6005;ext=1235"]);
  // NSN matches, but extension is different - not the same number.
  XCTAssertEqual(NBEMatchTypeNO_MATCH, [_aUtil isNumberMatch:@"+64 3 331-6005 ext.1235"
                                                      second:@"3 331 6005#1234"]);

  // Invalid numbers that can't be parsed.
  XCTAssertEqual(NBEMatchTypeNOT_A_NUMBER, [_aUtil isNumberMatch:@"4" second:@"3 331 6043"]);
  XCTAssertEqual(NBEMatchTypeNOT_A_NUMBER, [_aUtil isNumberMatch:@"+43" second:@"+64 3 331 6005"]);
  XCTAssertEqual(NBEMatchTypeNOT_A_NUMBER, [_aUtil isNumberMatch:@"+43" second:@"64 3 331 6005"]);
  XCTAssertEqual(NBEMatchTypeNOT_A_NUMBER, [_aUtil isNumberMatch:@"Dog" second:@"64 3 331 6005"]);
}

- (void)testIsNumberMatchNsnMatches {
  // NSN matches.
  XCTAssertEqual(NBEMatchTypeNSN_MATCH, [_aUtil isNumberMatch:@"+64 3 331-6005"
                                                       second:@"03 331 6005"]);
  XCTAssertEqual(NBEMatchTypeNSN_MATCH,
                 [_aUtil isNumberMatch:@"+64 3 331-6005"
                                second:@"tel:03-331-6005;isub=1234;phone-context=abc.nz"]);
  XCTAssertEqual(NBEMatchTypeNSN_MATCH, [_aUtil isNumberMatch:self.nzNumber second:@"03 331 6005"]);
  // Here the second number possibly starts with the country calling code for
  // New Zealand, although we are unsure.

  NBPhoneNumber *unchangedNzNumber = self.nzNumber;
  XCTAssertEqual(NBEMatchTypeNSN_MATCH, [_aUtil isNumberMatch:unchangedNzNumber
                                                       second:@"(64-3) 331 6005"]);
  // Check the phone number proto was not edited during the method call.
  XCTAssertTrue([self.nzNumber isEqual:unchangedNzNumber]);

  // Here, the 1 might be a national prefix, if we compare it to the US number,
  // so the resultant match is an NSN match.
  XCTAssertEqual(NBEMatchTypeNSN_MATCH, [_aUtil isNumberMatch:self.usNumber
                                                       second:@"1-650-253-0000"]);
  XCTAssertEqual(NBEMatchTypeNSN_MATCH, [_aUtil isNumberMatch:self.usNumber second:@"6502530000"]);
  XCTAssertEqual(NBEMatchTypeNSN_MATCH, [_aUtil isNumberMatch:@"+1 650-253 0000"
                                                       second:@"1 650 253 0000"]);
  XCTAssertEqual(NBEMatchTypeNSN_MATCH, [_aUtil isNumberMatch:@"1 650-253 0000"
                                                       second:@"1 650 253 0000"]);
  XCTAssertEqual(NBEMatchTypeNSN_MATCH, [_aUtil isNumberMatch:@"1 650-253 0000"
                                                       second:@"+1 650 253 0000"]);
  // For this case, the match will be a short NSN match, because we cannot
  // assume that the 1 might be a national prefix, so don't remove it when
  // parsing.

  NBPhoneNumber *randomNumber = [[NBPhoneNumber alloc] init];
  [randomNumber setCountryCode:@41];
  [randomNumber setNationalNumber:@6502530000];
  XCTAssertEqual(NBEMatchTypeSHORT_NSN_MATCH, [_aUtil isNumberMatch:randomNumber
                                                             second:@"1-650-253-0000"]);
}

- (void)testIsNumberMatchShortNsnMatches {
  // Short NSN matches with the country not specified for either one or both
  // numbers.
  XCTAssertEqual(NBEMatchTypeSHORT_NSN_MATCH, [_aUtil isNumberMatch:@"+64 3 331-6005"
                                                             second:@"331 6005"]);
  XCTAssertEqual(NBEMatchTypeSHORT_NSN_MATCH,
                 [_aUtil isNumberMatch:@"+64 3 331-6005"
                                second:@"tel:331-6005;phone-context=abc.nz"]);
  XCTAssertEqual(NBEMatchTypeSHORT_NSN_MATCH,
                 [_aUtil isNumberMatch:@"+64 3 331-6005"
                                second:@"tel:331-6005;isub=1234;phone-context=abc.nz"]);
  XCTAssertEqual(NBEMatchTypeSHORT_NSN_MATCH,
                 [_aUtil isNumberMatch:@"+64 3 331-6005"
                                second:@"tel:331-6005;isub=1234;phone-context=abc.nz;a=%A1"]);
  // We did not know that the '0' was a national prefix since neither number has
  // a country code, so this is considered a SHORT_NSN_MATCH.
  XCTAssertEqual(NBEMatchTypeSHORT_NSN_MATCH, [_aUtil isNumberMatch:@"3 331-6005"
                                                             second:@"03 331 6005"]);
  XCTAssertEqual(NBEMatchTypeSHORT_NSN_MATCH, [_aUtil isNumberMatch:@"3 331-6005"
                                                             second:@"331 6005"]);
  XCTAssertEqual(NBEMatchTypeSHORT_NSN_MATCH,
                 [_aUtil isNumberMatch:@"3 331-6005" second:@"tel:331-6005;phone-context=abc.nz"]);
  XCTAssertEqual(NBEMatchTypeSHORT_NSN_MATCH, [_aUtil isNumberMatch:@"3 331-6005"
                                                             second:@"+64 331 6005"]);
  // Short NSN match with the country specified.
  XCTAssertEqual(NBEMatchTypeSHORT_NSN_MATCH, [_aUtil isNumberMatch:@"03 331-6005"
                                                             second:@"331 6005"]);
  XCTAssertEqual(NBEMatchTypeSHORT_NSN_MATCH, [_aUtil isNumberMatch:@"1 234 345 6789"
                                                             second:@"345 6789"]);
  XCTAssertEqual(NBEMatchTypeSHORT_NSN_MATCH, [_aUtil isNumberMatch:@"+1 (234) 345 6789"
                                                             second:@"345 6789"]);
  // NSN matches, country calling code omitted for one number, extension missing
  // for one.
  XCTAssertEqual(NBEMatchTypeSHORT_NSN_MATCH, [_aUtil isNumberMatch:@"+64 3 331-6005"
                                                             second:@"3 331 6005#1234"]);
  // One has Italian leading zero, one does not.

  NBPhoneNumber *italianNumberOne = [[NBPhoneNumber alloc] init];
  [italianNumberOne setCountryCode:@39];
  [italianNumberOne setNationalNumber:@1234];
  [italianNumberOne setItalianLeadingZero:YES];

  NBPhoneNumber *italianNumberTwo = [[NBPhoneNumber alloc] init];
  [italianNumberTwo setCountryCode:@39];
  [italianNumberTwo setNationalNumber:@1234];
  XCTAssertEqual(NBEMatchTypeSHORT_NSN_MATCH, [_aUtil isNumberMatch:italianNumberOne
                                                             second:italianNumberTwo]);
  // One has an extension, the other has an extension of ''.
  [italianNumberOne setExtension:@"1234"];
  italianNumberOne.italianLeadingZero = NO;
  [italianNumberTwo setExtension:@""];
  XCTAssertEqual(NBEMatchTypeSHORT_NSN_MATCH, [_aUtil isNumberMatch:italianNumberOne
                                                             second:italianNumberTwo]);
}

- (void)testCanBeInternationallyDialled {
  // We have no-international-dialling rules for the US in our test metadata
  // that say that toll-free numbers cannot be dialled internationally.
  XCTAssertFalse([_aUtil canBeInternationallyDialled:self.usTollFreeNumber]);

  // Normal US numbers can be internationally dialled.
  XCTAssertTrue([_aUtil canBeInternationallyDialled:self.usNumber]);

  // Invalid number.
  XCTAssertTrue([_aUtil canBeInternationallyDialled:self.usLocalNumber]);

  // We have no data for NZ - should return true.
  XCTAssertTrue([_aUtil canBeInternationallyDialled:self.nzNumber]);
  XCTAssertTrue([_aUtil canBeInternationallyDialled:self.internationalTollFreeNumber]);
}

- (void)testIsAlphaNumber {
  XCTAssertTrue([_aUtil isAlphaNumber:@"1800 six-flags"]);
  XCTAssertTrue([_aUtil isAlphaNumber:@"1800 six-flags ext. 1234"]);
  XCTAssertTrue([_aUtil isAlphaNumber:@"+800 six-flags"]);
  XCTAssertTrue([_aUtil isAlphaNumber:@"180 six-flags"]);
  XCTAssertFalse([_aUtil isAlphaNumber:@"1800 123-1234"]);
  XCTAssertFalse([_aUtil isAlphaNumber:@"1 six-flags"]);
  XCTAssertFalse([_aUtil isAlphaNumber:@"18 six-flags"]);
  XCTAssertFalse([_aUtil isAlphaNumber:@"1800 123-1234 extension: 1234"]);
  XCTAssertFalse([_aUtil isAlphaNumber:@"+800 1234-1234"]);
}

- (void)testGetCountryMobileToken {
  XCTAssertEqualObjects(
      @"1", [_aUtil getCountryMobileTokenFromCountryCode:[[_aUtil getCountryCodeForRegion:@"MX"]
                                                             integerValue]]);
  XCTAssertEqualObjects(
      @"", [_aUtil getCountryMobileTokenFromCountryCode:[[_aUtil getCountryCodeForRegion:@"SE"]
                                                            integerValue]]);
}

@end
