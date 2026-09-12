//
//  NBGeocoderMetaDataHelper.m
//  libPhoneNumberiOS
//
//  Created by Rastaar Haghi on 6/12/20.
//  Copyright © 2020 Google LLC. All rights reserved.
//

#import <sqlite3.h>

#import "NBGeocoderMetaDataHelper.h"
#import "NBPhoneNumber.h"

@implementation NBGeocoderMetaDataHelper {
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

    if (bundle == nil) {
      return self;
    }

    NSString *shortLanguageCode = [[languageCode componentsSeparatedByString:@"-"] firstObject];
    NSURL *databaseURL = [[bundle resourceURL]
        URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.db", shortLanguageCode]];
    NSString *databasePath = [databaseURL path];
    if (databasePath == nil) {
      return self;
    }
    if (sqlite3_open([databasePath UTF8String], &_database) != SQLITE_OK) {
      sqlite3_close_v2(_database);
      _database = NULL;
      return self;
    }

    sqlite3_prepare_v2(_database,
                       [[NSString stringWithFormat:preparedStatement, countryCode] UTF8String], -1,
                       &_selectStatement, NULL);
  }
  return self;
}

- (instancetype)initWithCountryCode:(NSNumber *)countryCode withLanguage:(NSString *)languageCode {
  return [self initWithCountryCode:countryCode
                      withLanguage:languageCode
                        withBundle:[NBGeocoderMetaDataHelper defaultMetadataBundle]];
}

// Locates GeocodingMetaData.bundle wherever the integration put it.
//
// Appending the payload to -[NSBundle bundleForClass:].resourceURL only works
// for CocoaPods and manual integration, where the databases land next to the
// consuming binary. SwiftPM nests them one level deeper, inside a generated
// wrapper bundle, and emits that wrapper flat up to Xcode 26 but
// macOS-structured (Contents/Resources) from Xcode 27. Without this search the
// databases are simply not found and every lookup falls back to the country
// name, with no error and no crash.
+ (NSBundle * _Nullable)defaultMetadataBundle {
  static NSBundle *cachedBundle = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    NSMutableArray<NSBundle *> *searchBundles = [NSMutableArray arrayWithArray:NSBundle.allBundles];
    [searchBundles addObjectsFromArray:NSBundle.allFrameworks];
    [searchBundles addObject:[NSBundle bundleForClass:self]];
    [searchBundles addObject:[NSBundle mainBundle]];

    for (NSBundle *bundle in searchBundles) {
      NSMutableArray<NSURL *> *baseURLs = [NSMutableArray array];
      if (bundle.resourceURL != nil) {
        [baseURLs addObject:bundle.resourceURL];
      }
      if (bundle.bundleURL != nil) {
        [baseURLs addObject:bundle.bundleURL];
      }

      NSURL *parentURL = bundle.bundleURL;
      for (NSUInteger index = 0; index < 5 && parentURL != nil; index++) {
        parentURL = [parentURL URLByDeletingLastPathComponent];
        if (parentURL != nil) {
          [baseURLs addObject:parentURL];
        }
      }

      for (NSURL *baseURL in baseURLs) {
        NSURL *resourcesURL = [baseURL URLByAppendingPathComponent:@"Contents/Resources"];
        NSURL *wrapperURL = [baseURL
            URLByAppendingPathComponent:@"libPhoneNumber_libPhoneNumberGeocodingMetaData.bundle"];
        NSURL *wrapperResourcesURL =
            [wrapperURL URLByAppendingPathComponent:@"Contents/Resources"];
        NSArray<NSURL *> *candidateURLs = @[
          [baseURL URLByAppendingPathComponent:@"GeocodingMetaData.bundle"],
          [resourcesURL URLByAppendingPathComponent:@"GeocodingMetaData.bundle"],
          [wrapperURL URLByAppendingPathComponent:@"GeocodingMetaData.bundle"],
          [wrapperResourcesURL URLByAppendingPathComponent:@"GeocodingMetaData.bundle"],
        ];

        for (NSURL *candidateURL in candidateURLs) {
          // en.db ships in every build of the payload, so it identifies a
          // populated bundle rather than an empty directory of the right name.
          NSURL *databaseURL = [candidateURL URLByAppendingPathComponent:@"en.db"];
          if ([[NSFileManager defaultManager] fileExistsAtPath:databaseURL.path]) {
            cachedBundle = [NSBundle bundleWithURL:candidateURL];
            return;
          }
        }
      }
    }
  });

  return cachedBundle;
}

- (NSString * _Nullable)searchPhoneNumber:(NBPhoneNumber *)phoneNumber {
  @synchronized(self) {
    if (_database == NULL) {
      return nil;
    }

    // Each database holds one table per country calling code, and only the
    // English database covers every country. Preparing a statement for a
    // country this database does not carry fails, which is an ordinary "no
    // data for this number" answer -- not a broken helper. Leaving the failed
    // statement in place used to disable the helper permanently, so a single
    // lookup for an uncovered country downgraded every later lookup in that
    // language to a country name.
    if (_selectStatement == NULL || ![phoneNumber.countryCode isEqualToNumber:_countryCode]) {
      _countryCode = phoneNumber.countryCode;

      if (_selectStatement != NULL) {
        sqlite3_finalize(_selectStatement);
        _selectStatement = NULL;
      }

      sqlite3_stmt *statement = NULL;
      int prepareResult = sqlite3_prepare_v2(
          _database, [[NSString stringWithFormat:preparedStatement, _countryCode] UTF8String], -1,
          &statement, NULL);
      if (prepareResult != SQLITE_OK || statement == NULL) {
        if (statement != NULL) {
          sqlite3_finalize(statement);
        }
        return nil;
      }

      _selectStatement = statement;
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
