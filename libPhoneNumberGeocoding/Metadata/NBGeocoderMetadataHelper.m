//
//  NBGeocoderMetadataHelper.m
//  libPhoneNumberiOS
//
//  Created by Rastaar Haghi on 6/12/20.
//  Copyright © 2020 Google LLC. All rights reserved.
//

#import <sqlite3.h>

#import "NBGeocoderMetadataHelper.h"
#import "NBPhoneNumber.h"

@implementation NBGeocoderMetadataHelper {
 @private
  sqlite3 *_database;
  sqlite3_stmt *_selectStatement;
  NSString *_language;
  NSNumber *_countryCode;
  const char *_completePhoneNumber;
}

static NSString *const preparedStatement = @"WITH recursive count(x)"
                                           @"AS"
                                           @"( "
                                           @"SELECT 1 "
                                           @"UNION ALL "
                                           @"SELECT x+1 "
                                           @"FROM   count "
                                           @"LIMIT  length(?)), tosearch "
                                           @"AS "
                                           @"( "
                                           @"SELECT substr(?, 1, x) AS indata "
                                           @"FROM   count) "
                                           @"SELECT   nationalnumber, "
                                           @"description, "
                                           @"length(nationalnumber) AS nationalnumberlength "
                                           @"FROM     geocodingpairs%@ "
                                           @"WHERE    nationalnumber IN tosearch "
                                           @"ORDER BY nationalnumberlength DESC "
                                           @"LIMIT    2";

- (instancetype)initWithCountryCode:(NSNumber *)countryCode
                       withLanguage:(NSString *)languageCode
                         withBundle:(NSBundle *)bundle {
  self = [super init];
  if (self != nil) {
    _countryCode = countryCode;
    _language = languageCode;

    NSURL *bundleURL = [bundle resourceURL];
    NSString *shortLanguageCode = [[languageCode componentsSeparatedByString:@"-"] firstObject];
    NSString *databasePath = [NSString stringWithFormat:@"%@%@.db", bundleURL, shortLanguageCode];
    if (databasePath == nil) {
      @throw [NSException exceptionWithName:NSInvalidArgumentException
                                     reason:@"Geocoding Database URL not found"
                                   userInfo:nil];
    }
    sqlite3_open([databasePath UTF8String], &_database);

    sqlite3_prepare_v2(_database,
                       [[NSString stringWithFormat:preparedStatement, countryCode] UTF8String], -1,
                       &_selectStatement, NULL);
  }
  return self;
}

- (instancetype)initWithCountryCode:(NSNumber *)countryCode withLanguage:(NSString *)languageCode {
  NSBundle *bundle = [NSBundle bundleForClass:self.classForCoder];
  NSURL *resourceURL =
      [[bundle resourceURL] URLByAppendingPathComponent:@"GeocodingMetadata.bundle"];
  NSBundle *databaseBundle = [NSBundle bundleWithURL:resourceURL];
  return [self initWithCountryCode:countryCode withLanguage:languageCode withBundle:databaseBundle];
}

- (NSString *)searchPhoneNumber:(NBPhoneNumber *)phoneNumber {
  @synchronized(self) {
    if (![phoneNumber.countryCode isEqualToNumber:_countryCode]) {
      _countryCode = phoneNumber.countryCode;
      sqlite3_finalize(_selectStatement);
      sqlite3_prepare_v2(_database,
                         [[NSString stringWithFormat:preparedStatement, _countryCode] UTF8String],
                         -1, &_selectStatement, NULL);
    }

    int sqlCommandResults = [self createSelectStatement:phoneNumber];

    if (sqlCommandResults != SQLITE_OK) {
      NSLog(@"Error with preparing statement. SQLite3 error code was: %d", sqlCommandResults);
      return nil;
    }
    int step = sqlite3_step(_selectStatement);
    if (step == SQLITE_ROW) {
      return @((const char *)sqlite3_column_text(_selectStatement, 1));
    } else {
      return nil;
    }
  }
}

- (void)dealloc {
  sqlite3_finalize(_selectStatement);
  sqlite3_close_v2(_database);
}

- (int)resetSelectStatement {
  sqlite3_reset(_selectStatement);
  return sqlite3_clear_bindings(_selectStatement);
}

- (const char *)createCompletePhoneNumber:(NBPhoneNumber *)phoneNumber {
  if ([phoneNumber italianLeadingZero]) {
    return [[NSString
        stringWithFormat:@"%@0%@", phoneNumber.countryCode, phoneNumber.nationalNumber] UTF8String];
  } else {
    return [[NSString stringWithFormat:@"%@%@", phoneNumber.countryCode, phoneNumber.nationalNumber]
        UTF8String];
  }
}

- (void)bindPhoneNumberToSelectStatement {
  sqlite3_bind_text(_selectStatement, 1, _completePhoneNumber, -1, SQLITE_TRANSIENT);
  sqlite3_bind_text(_selectStatement, 2, _completePhoneNumber, -1, SQLITE_TRANSIENT);
}

- (int)createSelectStatement:(NBPhoneNumber *)phoneNumber {
  int sqliteResultCode;
  @autoreleasepool {
    sqliteResultCode = [self resetSelectStatement];
    if (sqliteResultCode == SQLITE_OK) {
      _completePhoneNumber = [self createCompletePhoneNumber:phoneNumber];
      [self bindPhoneNumberToSelectStatement];
    } else {
      NSLog(@"SQLite3 error occurred when resetting and clearing bindings in select statement: %s",
            sqlite3_errstr(sqliteResultCode));
    }
  }
  return sqliteResultCode;
}

@end
