//
//  NBShortNumberMetadataHelper.h
//  libPhoneNumberShortNumber
//
//  Created by Rastaar Haghi on 7/15/20.
//  Copyright © 2020 Google. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NBPhoneMetaData;
@class NBMetadataHelper;

NS_ASSUME_NONNULL_BEGIN

@interface NBShortNumberMetadataHelper : NSObject

- (instancetype)initWithZippedData:(NSData *)data
                    expandedLength:(NSUInteger)expandedLength
                    metadataHelper:(NBMetadataHelper *)helper;

/**
 * Returns the short number metadata for the given region code or {@code nil} if the region
 * code is invalid or unknown.
 *
 * @param regionCode regionCode
 * @return {i18n.phonenumbers.PhoneMetadata}
 */
- (NBPhoneMetaData * _Nullable)shortNumberMetadataForRegion:(NSString * _Nonnull)regionCode;

/**
 * Returns the region codes that have short-number metadata.
 */
- (NSArray<NSString *> * _Nonnull)getSupportedRegions;

@end

NS_ASSUME_NONNULL_END
