//
//  NBShortNumberTestHelper.m
//  libPhoneNumberShortNumber
//
//  Created by Paween Itthipalkul on 12/1/17.
//  Copyright © 2017 Google LLC. All rights reserved.
//
#import "NBShortNumberTestHelper.h"
#import "NBPhoneMetaData.h"
#import "NBPhoneNumberDesc.h"
#import "NBShortNumberMetadataHelper.h"
#import "NBShortNumberUtil.h"

@implementation NBShortNumberTestHelper {
  NBShortNumberMetadataHelper *_helper;
}

- (instancetype)init {
  self = [super init];
  if (self != nil) {
    _helper = [[NBShortNumberMetadataHelper alloc] init];
  }
  return self;
}

- (NSString *)exampleShortNumberForCost:(NBEShortNumberCost)cost regionCode:(NSString *)regionCode {
  NBPhoneMetaData *metadata = [_helper shortNumberMetadataForRegion:regionCode];
  if (metadata == nil) {
    return @"";
  }

  NBPhoneNumberDesc *desc = nil;
  switch (cost) {
    case NBEShortNumberCostTollFree:
      desc = metadata.tollFree;
      break;
    case NBEShortNumberCostPremiumRate:
      desc = metadata.premiumRate;
      break;
    case NBEShortNumberCostStandardRate:
      desc = metadata.standardRate;
      break;
    case NBEShortNumberCostUnknown:
      // UNKNOWN_COST numbers are computed by the process of elimination from the other cost
      // categories.
      break;
  }

  return desc.exampleNumber ?: @"";
}

- (NSString *)exampleShortNumberWithRegionCode:(NSString *)regionCode {
  NBPhoneMetaData *metadata = [_helper shortNumberMetadataForRegion:regionCode];
  return metadata.shortCode.exampleNumber ?: @"";
}

@end
