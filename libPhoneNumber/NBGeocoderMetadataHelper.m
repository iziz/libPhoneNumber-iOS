//
//  NBGeocoderMetadataHelper.m
//  libPhoneNumberiOS
//
//  Created by Rastaar Haghi on 6/12/20.
//  Copyright © 2020 Google LLC. All rights reserved.
//

#import "NBGeocoderMetadataHelper.h"
#import "NBPhoneNumber.h"

@implementation NBGeocoderMetadataHelper {
 @private
  NSString *_databasePath;
  sqlite3 *_database;
  sqlite3_stmt *_selectStatement;
  NSString *_language;
  NSNumber *_countryCode;
}

NSString *const preparedStatement = @"WITH recursive count(x)"
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
                                    @"LIMIT    1";

- (instancetype)initWithCountryCode:(NSNumber *)countryCode withLanguage:(NSString *)languageCode {
  self = [super init];
  if (self != nil) {
    _countryCode = countryCode;
    _language = languageCode;

    NSBundle *bundle = [NSBundle bundleForClass:self.classForCoder];
    NSURL *bundleURL = [[bundle resourceURL] URLByAppendingPathComponent:@"Resources.bundle"];
    NSString *databasePath = [NSString stringWithFormat:@"%@%@.db", bundleURL, _language];
    _databasePath = databasePath;

    sqlite3_open([databasePath UTF8String], &_database);

    sqlite3_prepare_v2(_database,
                       [[NSString stringWithFormat:preparedStatement, countryCode] UTF8String], -1,
                       &_selectStatement, NULL);
  }
  return self;
}

- (void)dealloc {
  sqlite3_finalize(_selectStatement);
  sqlite3_close_v2(_database);
}

- (int)createSelectStatement:(NBPhoneNumber *)phoneNumber {
  int sqliteResultCode;
  @autoreleasepool {
    sqlite3_reset(_selectStatement);
    sqliteResultCode = sqlite3_clear_bindings(_selectStatement);
    if (sqliteResultCode == SQLITE_OK) {
      const char *completePhoneNumber =
          [[NSString stringWithFormat:@"%@%@", phoneNumber.countryCode, phoneNumber.nationalNumber]
              UTF8String];
      sqlite3_bind_text(_selectStatement, 1, completePhoneNumber, -1, SQLITE_TRANSIENT);
      sqlite3_bind_text(_selectStatement, 2, completePhoneNumber, -1, SQLITE_TRANSIENT);
    } else {
      NSLog(@"The SQLite3 resulting code was: %d", sqliteResultCode);
    }
  }
  return sqliteResultCode;
}

- (NSString *)searchPhoneNumber:(NBPhoneNumber *)phoneNumber {
  if (![phoneNumber.countryCode isEqualToNumber:_countryCode]) {
    _countryCode = phoneNumber.countryCode;
    sqlite3_prepare_v2(_database,
                       [[NSString stringWithFormat:preparedStatement, _countryCode] UTF8String], -1,
                       &_selectStatement, NULL);
  }

  int sqlCommandResults = [self createSelectStatement:phoneNumber];

  if (sqlCommandResults != SQLITE_OK) {
    NSLog(@"Error with preparing statement. SQLite3 error code was: %d", sqlCommandResults);
    return @"";
  }
  int step = sqlite3_step(_selectStatement);
  if (step == SQLITE_ROW) {
    return @((const char *)sqlite3_column_text(_selectStatement, 1));
  } else {
    return nil;
  }
}

@end
