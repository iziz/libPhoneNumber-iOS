//
//  NBPhoneNumberUtil+Category.h
//  libPhoneNumber
//
//  Created by Paween Itthipalkul on 12/1/17.
//  Copyright © 2017 Google LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "NBPhoneNumberUtil.h"

@class NBMetadataHelper, NBRegExMatcher;

/**
 This interface exposes properties used in NBPhoneNumberUtil categories.
 */
@interface NBPhoneNumberUtil()

@property (nonatomic, strong, readonly) NBMetadataHelper *helper;
@property (nonatomic, strong, readonly) NBRegExMatcher *matcher;

@end
