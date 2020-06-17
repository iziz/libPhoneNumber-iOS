//
//  NBPhoneNumberOfflineGeocoder.h
//  libPhoneNumberiOS
//
//  Created by Rastaar Haghi on 6/12/20.
//  Copyright © 2020 ohtalk.me. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NBGeocoderMetadataHelper.h"
#import "NBPhoneNumber.h"
#import "NBPhoneNumberDefines.h"
#import "NBPhoneNumberUtil.h"
NS_ASSUME_NONNULL_BEGIN

@interface NBPhoneNumberOfflineGeocoder : NSObject

- (instancetype)init;

- (NSString *)descriptionForValidNumber:(NBPhoneNumber *)phoneNumber
                       withLanguageCode:(NSString *)language;
- (NSString *)descriptionForValidNumber:(NBPhoneNumber *)phoneNumber
                       withLanguageCode:(NSString *)language
                         withUserRegion:(NSString *)userRegion;
- (NSString *)descriptionForNumber:(NBPhoneNumber *)phoneNumber
                  withLanguageCode:(NSString *)languageCode;
- (NSString *)descriptionForNumber:(NBPhoneNumber *)phoneNumber
                  withLanguageCode:(NSString *)languageCode
                    withUserRegion:(NSString *)userRegion;
@end

@interface NBPhoneNumberOfflineGeocoder ()

- (NSString *)descriptionForNumber:(NBPhoneNumber *)phoneNumber;
- (NSString *)descriptionForNumber:(NBPhoneNumber *)phoneNumber
                    withUserRegion:(NSString *)userRegion;

@end

NS_ASSUME_NONNULL_END
