//
//  NBMetadataHelper.h
//  libPhoneNumber
//
//  Created by tabby on 2015. 2. 8..
//  Copyright (c) 2015년 ohtalk.me. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NBPhoneNumberDefines.h"

@class NBPhoneMetaData;

@interface NBMetadataHelper : NSObject

// Preserve the existing Swift parameter import and implementation-only annotations.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnullability-completeness"
+ (BOOL)hasValue:(NSString *)string;
#pragma clang diagnostic pop

- (instancetype _Null_unspecified)initWithZippedData:(NSData * _Null_unspecified)data expandedLength:(NSUInteger)expandedLength;

- (instancetype _Nonnull)init;

- (NSArray * _Nullable)regionCodeFromCountryCode:(NSNumber * _Null_unspecified)countryCodeNumber;
- (NSString * _Nullable)countryCodeFromRegionCode:(NSString * _Null_unspecified)regionCode;

// These parameter contracts remain unaudited.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnullability-completeness"
- (NBPhoneMetaData * _Nullable)getMetadataForNonGeographicalRegion:(NSNumber *)countryCallingCode;
- (NBPhoneMetaData * _Nullable)getMetadataForRegion:(NSString *)regionCode;
#pragma clang diagnostic pop

- (NSDictionary * _Nonnull)countryCodeToCountryNumberDictionary;
- (NSDictionary * _Null_unspecified)countryCodeToRegionCodeDictionary;
- (NSArray * _Nonnull)getAllMetadata;

@end
