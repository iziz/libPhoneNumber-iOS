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

NS_ASSUME_NONNULL_BEGIN

@interface NBPhoneNumberOfflineGeocoder : NSObject

@property (nonatomic) NSString *language;
@property (nonatomic) NBGeocoderMetadataHelper *geocoderHelper;
@property (nonatomic) NSArray<NSString*>* supportedLanguages;
-(instancetype) init;
-(NSString*) getCountryNameForNumber: (NBPhoneNumber*) number withLanguage: (NSString*) language;
-(NSString*) getDescriptionForNumber: (NBPhoneNumber*) number withLanguage: (NSString*) language;


@end

NS_ASSUME_NONNULL_END
