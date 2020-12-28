//
//  NBPhoneNumberUtil+ShortNumberTest.h
//  libPhoneNumber
//
//  Created by Paween Itthipalkul on 12/1/17.
//  Copyright © 2017 Google LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NBPhoneNumberUtil+ShortNumber.h"
#import "NBPhoneNumberUtil.h"

#if SHORT_NUMBER_SUPPORT

NS_ASSUME_NONNULL_BEGIN

/**
 Includes methods used only for testing NBPhoneNumberUtil+ShortNumber.
 */
@interface NBPhoneNumberUtil (ShortNumberTest)

- (NSString *)exampleShortNumberForCost:(NBEShortNumberCost)cost regionCode:(NSString *)regionCode;
- (NSString *)exampleShortNumberWithRegionCode:(NSString *)regionCode;

@end

NS_ASSUME_NONNULL_END

#endif  // SHORT_NUMBER_SUPPORT
