//
//  NBGeocoderMetadataHelper.h
//  libPhoneNumberiOS
//
//  Created by Rastaar Haghi on 6/12/20.
//  Copyright © 2020 ohtalk.me. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>
#import "NBPhoneNumber.h"

NS_ASSUME_NONNULL_BEGIN

@interface NBGeocoderMetadataHelper : NSObject 

@property (nonatomic, copy) NSString *regionDescription;
@property (nonatomic, copy) NSNumber *countryCode;
@property (nonatomic, copy) NSString *language;

-(instancetype) initWithCountryCode: (NSNumber*) countryCode withLanguage: (NSString*) language;
-(int) createSelectStatement: (NBPhoneNumber*) number;
-(NSString*) searchPhoneNumberInDatabase:(NBPhoneNumber*) number withLanguage: (NSLocale*) language ;

@end

NS_ASSUME_NONNULL_END
