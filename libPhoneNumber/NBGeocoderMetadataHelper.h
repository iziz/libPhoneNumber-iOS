//
//  NBGeocoderMetadataHelper.h
//  libPhoneNumberiOS
//
//  Created by Rastaar Haghi on 6/12/20.
//  Copyright © 2020 Google LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>

@class NBPhoneNumber;

NS_ASSUME_NONNULL_BEGIN

@interface NBGeocoderMetadataHelper : NSObject

- (instancetype)initWithCountryCode:(NSNumber *)countryCode withLanguage:(NSString *)language;
- (int)createSelectStatement:(NBPhoneNumber *)number;
- (NSString *)searchPhoneNumber:(NBPhoneNumber *)number;

@end

NS_ASSUME_NONNULL_END
