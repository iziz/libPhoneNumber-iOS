//
//  NBSQLiteDatabaseConnection.m
//  libPhoneNumber-GeocodingParser
//
//  Created by Rastaar Haghi on 7/1/20.
//  Copyright © 2020 Google LLC. All rights reserved.
//

#import "NBSQLiteDatabaseConnection.h"

@implementation NBSQLiteDatabaseConnection {
 @private
  NSURL *_databasePath;
  sqlite3 *_DB;
  sqlite3_stmt *_insertStatement;
  int _sqliteDatabaseCode;
}

static NSString *const insertPreparedStatement = @"INSERT INTO geocodingPairs%@"
                                                 @"(NATIONALNUMBER, DESCRIPTION)"
                                                 @"VALUES "
                                                 @"(?, ?)";

static NSString *const createTablePreparedStatement =
    @"CREATE TABLE IF NOT EXISTS geocodingPairs%@ (ID INTEGER PRIMARY KEY "
    @"AUTOINCREMENT, "
    @"NATIONALNUMBER TEXT, DESCRIPTION TEXT)";
static NSString *const createIndexStatement = @"CREATE INDEX IF NOT EXISTS nationalNumberIndex ON "
                                              @"geocodingPairs%@(NATIONALNUMBER)";

- (instancetype)initWithCountryCode:(NSString *)countryCode
                       withLanguage:(NSString *)language
                withDestinationPath:(NSURL *)destinationPath {
  self = [super init];
  if (self != nil) {
    NSString *databasePath = [[NSString alloc]
        initWithString:[NSString stringWithFormat:@"%@/%@.db", destinationPath.path, language]];
    _sqliteDatabaseCode = sqlite3_open([databasePath UTF8String], &_DB);

    if (_sqliteDatabaseCode == SQLITE_OK) {
      [self createTable:countryCode];
      const char *formattedPreparedStatement =
          [[NSString stringWithFormat:insertPreparedStatement, countryCode] UTF8String];
      sqlite3_prepare_v2(_DB, formattedPreparedStatement, -1, &_insertStatement, NULL);
    } else {
      NSLog(@"Cannot open database at desired location: %@. \n"
            @"SQLite3 Error Message: %s",
            destinationPath, sqlite3_errstr(_sqliteDatabaseCode));
    }
  }
  return self;
}

- (void)addEntryToDB:(NSString *)phoneNumber
     withDescription:(NSString *)description
     withCountryCode:(NSString *)countryCode {
  if (_sqliteDatabaseCode != SQLITE_OK) {
    NSLog(@"Cannot open database. Failed to add entry. \n"
          @"SQLite3 Error Message: %s",
          sqlite3_errstr(_sqliteDatabaseCode));
    return;
  }
  int commandResults = [self createInsertStatement:phoneNumber withDescription:description];
  if (commandResults != SQLITE_OK) {
    NSLog(@"Error when creating insert statement: %s", sqlite3_errstr(commandResults));
  }
  sqlite3_step(_insertStatement);
}

- (void)dealloc {
  sqlite3_finalize(_insertStatement);
  sqlite3_close_v2(_DB);
}

- (void)createTable:(NSString *)countryCode {
  NSString *createTable = [NSString stringWithFormat:createTablePreparedStatement, countryCode];

  const char *sqliteCreateTableStatement = [createTable UTF8String];
  char *sqliteErrorMessage;
  if (sqlite3_exec(_DB, sqliteCreateTableStatement, NULL, NULL, &sqliteErrorMessage) != SQLITE_OK) {
    NSLog(@"Error creating table, %s", sqliteErrorMessage);
    return;
  }

  NSString *createIndexQuery = [NSString stringWithFormat:createIndexStatement, countryCode];
  const char *sqlCreateIndexStatement = [createIndexQuery UTF8String];
  if (sqlite3_exec(_DB, sqlCreateIndexStatement, NULL, NULL, &sqliteErrorMessage) != SQLITE_OK) {
    NSLog(@"Error occurred when applying index to nationalnumber column: %s", sqliteErrorMessage);
    return;
  }
}

- (int)resetInsertStatement {
  // If an error occurs during statement reset, return error code.
  // Otherwise, return outcome of clearing bindings on the statement.
  int sqlResultCode = sqlite3_reset(_insertStatement);
  if (sqlResultCode != SQLITE_OK) {
    return sqlResultCode;
  } else {
    return sqlite3_clear_bindings(_insertStatement);
  }
}

- (int)createInsertStatement:(NSString *)phoneNumber withDescription:(NSString *)description {
  int sqliteResultCode = [self resetInsertStatement];
  if (sqliteResultCode != SQLITE_OK) {
    NSLog(@"SQLite3 error occurred when resetting and clearing bindings in "
          @"insert statement: %s",
          sqlite3_errstr(sqliteResultCode));
    return sqliteResultCode;
  } else {
    sqlite3_bind_text(_insertStatement, 1, [phoneNumber UTF8String], -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(_insertStatement, 2, [description UTF8String], -1, SQLITE_TRANSIENT);
  }
  return sqliteResultCode;
}

@end
