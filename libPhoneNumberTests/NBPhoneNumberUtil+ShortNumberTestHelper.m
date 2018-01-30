//
//  NBPhoneNumberUtil+ShortNumberTestHelper.m
//  libPhoneNumber
//
//  Created by Paween Itthipalkul on 12/1/17.
//  Copyright © 2017 Google LLC. All rights reserved.
//

#import "NBPhoneNumberUtil+ShortNumberTestHelper.h"

#import "NBMetadataHelper.h"
#import "NBPhoneMetadata.h"
#import "NBPhoneNumberDesc.h"

#if SHORT_NUMBER_SUPPORT

@interface NBPhoneNumberUtil()

@property (nonatomic, strong, readonly) NBMetadataHelper *helper;

@end

@implementation NBPhoneNumberUtil(ShortNumberTestHelper)

- (NSString *)exampleShortNumberForCost:(NBEShortNumberCost)cost regionCode:(NSString *)regionCode {
  NBPhoneMetaData *metadata = [self.helper shortNumberMetadataForRegion:regionCode];
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
  NBPhoneMetaData *metadata = [self.helper shortNumberMetadataForRegion:regionCode];
  return metadata.shortCode.exampleNumber ?: @"";
}

@end

#endif // SHORT_NUMBER_SUPPORT
