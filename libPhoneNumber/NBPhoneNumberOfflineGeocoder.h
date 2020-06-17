//
//  NBPhoneNumberOfflineGeocoder.h
//  libPhoneNumberiOS
//
//  Created by Rastaar Haghi on 6/12/20.
//  Copyright © 2020 ohtalk.me. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NBPhoneNumber.h"
#import "NBGeocoderMetadataHelper.h"
#import "NBPhoneNumberUtil.h"
#import "NBPhoneNumberDefines.h"
NS_ASSUME_NONNULL_BEGIN

@interface NBPhoneNumberOfflineGeocoder : NSObject

@property (nonatomic) NBPhoneNumberUtil *phoneUtil;
@property (nonatomic) NBGeocoderMetadataHelper *geocoderHelper;
-(instancetype) init;
-(NSString*) countryNameForNumber: (NBPhoneNumber*) phoneNumber withLanguage: (NSLocale*) language;
-(NSString*) regionDisplayName:(NSString *) regionCode withLanguage: (NSLocale *) language;
-(NSString*) descriptionForValidNumber: (NBPhoneNumber*) phoneNumber withLanguage: (NSLocale*) language;
-(NSString*) descriptionForValidNumber:(NBPhoneNumber *)phoneNumber withLanguage: (NSLocale*) language withUserRegion: (NSString*) userRegion;
-(NSString*) descriptionForNumber: (NBPhoneNumber*) phoneNumber withLocale: (NSLocale*) locale;
-(NSString*) descriptionForNumber: (NBPhoneNumber*) phoneNumber withLanguageCode: (NSLocale*) languageCode withUserRegion: (NSString*) userRegion;
@end

NS_ASSUME_NONNULL_END
