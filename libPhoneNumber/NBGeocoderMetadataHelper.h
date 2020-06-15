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
@property (strong, nonatomic) NSString *databasePath;
@property (nonatomic) sqlite3 *DB;
@property (nonatomic) sqlite3_stmt *selectStatement;
@property (nonatomic) sqlite3_stmt *insertStatement;
@property (nonatomic) NSString *regionDescription;
@property (nonatomic) NSNumber *countryCode;
@property (nonatomic) NSString *language;

-(instancetype) initWithCountryCode: (NSNumber*) countryCode withLanguage: (NSString*) language;
-(void) createTable: (NSString*) countryCode;
-(int) createInsertStatement: (NSString*) phoneNumber withDescription: (NSString*) description withCountryCode: (NSString*) countryCode;
-(int) createSelectStatement: (NBPhoneNumber*) number;
-(void) addEntryToDB: (NSString*) phoneNumber withDescription: (NSString*) description withShouldCreateTable: (BOOL) createIndex withCountryCode: (NSString*) countryCode;

-(NSString*) searchPhoneNumberInDatabase:(NBPhoneNumber*) number withLanguage: (NSString*) language;
@end

NS_ASSUME_NONNULL_END
