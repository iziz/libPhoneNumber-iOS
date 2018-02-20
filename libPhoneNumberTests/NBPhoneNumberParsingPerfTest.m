//
//  NBPhoneNumberParsingPerfTest.m
//  libPhoneNumberiOSTests
//
//  Created by Paween Itthipalkul on 2/1/18.
//  Copyright © 2018 Google LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import "NBMetadataHelper.h"
#import "NBPhoneMetaData.h"

#import "NBNumberFormat.h"
#import "NBPhoneNumber.h"
#import "NBPhoneNumberDesc.h"
#import "NBPhoneNumberUtil.h"

@interface NBExampleNumber: NSObject

@property (nonatomic, strong) NSString *phoneNumber;
@property (nonatomic, strong) NSString *baseRegionCode;

- (instancetype)initWithPhoneNumber:(NSString *)phoneNumber
                     baseRegionCode:(NSString *)baseRegionCode;

@end

@implementation NBExampleNumber
- (instancetype)initWithPhoneNumber:(NSString *)phoneNumber
                     baseRegionCode:(NSString *)baseRegionCode {
  self = [super init];
  if (self != nil) {
    _phoneNumber = phoneNumber;
    _baseRegionCode = baseRegionCode;
  }

  return self;
}
@end


@interface NBPhoneNumberParsingPerfTest: XCTestCase
@end

@implementation NBPhoneNumberParsingPerfTest

#if PERF_TEST

- (void)testParsing {
  NSArray *regionCodes = [[NBMetadataHelper CCode2CNMap] allKeys];

  NSMutableArray<NBExampleNumber *> *exampleNumbers = [[NSMutableArray alloc] init];

  NBPhoneNumberUtil *util = [NBPhoneNumberUtil sharedInstance];

  for (NSString *regionCode in regionCodes) {
    NBPhoneNumber *phoneNumber = [util getExampleNumber:regionCode error:nil];
    if (phoneNumber != nil) {
      NSString *e164 = [util format:phoneNumber numberFormat:NBEPhoneNumberFormatE164 error:nil];
      NBExampleNumber *e164Sample = [[NBExampleNumber alloc] initWithPhoneNumber:e164
                                                                  baseRegionCode:regionCode];
      [exampleNumbers addObject:e164Sample];

      NSString *national = [util format:phoneNumber
                           numberFormat:NBEPhoneNumberFormatNATIONAL
                                  error:nil];
      NBExampleNumber *nationalSample = [[NBExampleNumber alloc] initWithPhoneNumber:national
                                                                      baseRegionCode:regionCode];
      [exampleNumbers addObject:nationalSample];

      // intl format sample.
      NSString *intl = [util format:phoneNumber
                       numberFormat:NBEPhoneNumberFormatINTERNATIONAL
                              error:nil];
      NBExampleNumber * intlSample = [[NBExampleNumber alloc] initWithPhoneNumber:intl
                                                                   baseRegionCode:regionCode];
      [exampleNumbers addObject:intlSample];
    }
  }

  for (int i = 0; i < 5; i++) {
    [exampleNumbers addObjectsFromArray:exampleNumbers];
  }

  [self measureBlock:^{
    for (NBExampleNumber *example in exampleNumbers) {
      [util parseAndKeepRawInput:example.phoneNumber
                   defaultRegion:example.baseRegionCode
                           error:nil];
    }
  }];
}

#endif // PERF_TEST

@end
