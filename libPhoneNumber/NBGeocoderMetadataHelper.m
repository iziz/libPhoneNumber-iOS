//
//  NBGeocoderMetadataHelper.m
//  libPhoneNumberiOS
//
//  Created by Rastaar Haghi on 6/12/20.
//  Copyright © 2020 ohtalk.me. All rights reserved.
//

#import "NBGeocoderMetadataHelper.h"

@implementation NBGeocoderMetadataHelper

-(instancetype) initWithCountryCode:(NSNumber *)countryCode withLanguage: (NSString*) language {
    self = [super init];
    self.countryCode = countryCode;
    self.language = language;
    // grab bundle of current pod instance
    NSBundle *bundle = [NSBundle bundleForClass: self.classForCoder];
    NSURL *bundleURL = [[bundle resourceURL] URLByAppendingPathComponent:@"Resources.bundle"];
    // create string for database directory
    NSString* databasePath = [NSString stringWithFormat:@"%@%@.db", bundleURL, self.language];
    self.databasePath = databasePath;
    
    // open the database position
    sqlite3_open([databasePath UTF8String], & _DB);
    
    // set up prepared statements for inserting entry and searching for entry
    sqlite3_prepare_v2(self.DB, [[NSString stringWithFormat:@"WITH RECURSIVE cnt(x) AS ( SELECT 1 UNION ALL SELECT x+1 FROM cnt LIMIT length(?)), toSearch as (SELECT substr(?, 1, x) as indata FROM cnt) select nationalnumber, description, length(nationalnumber) as natLength from geocodingPairs%@ where NATIONALNUMBER in toSearch order by natLength desc limit 1", countryCode] UTF8String], -1, &_selectStatement, NULL);
    sqlite3_prepare_v2(self.DB, [[NSString stringWithFormat:@"INSERT INTO geocodingPairs%@ (NATIONALNUMBER, DESCRIPTION) VALUES (?, ?)", countryCode] UTF8String], -1, &_insertStatement, NULL);
    return self;
}

- (void)dealloc {
    sqlite3_finalize(self.selectStatement);
    sqlite3_finalize(self.insertStatement);
    sqlite3_close_v2(self.DB);
}

-(void) createTable: (NSString*) countryCode {
    
    NSString *createTable = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS geocodingPairs%@ (ID INTEGER PRIMARY KEY AUTOINCREMENT, NATIONALNUMBER TEXT, DESCRIPTION TEXT)", countryCode];
    // create table
    const char *sqliteCreateTableStatement = [createTable UTF8String];
    char *sqliteErrorMessage;
    if(sqlite3_exec(_DB, sqliteCreateTableStatement, NULL, NULL, &sqliteErrorMessage) != SQLITE_OK) {
        NSLog(@"Error creating table, %s", sqliteErrorMessage);
    } else {
         NSLog(@"Successfully applied create table if not exists command");
    }
    
    NSString *createIndex = [NSString stringWithFormat:@"CREATE INDEX IF NOT EXISTS nationalNumberIndex on geocodingPairs%@(NATIONALNUMBER)", countryCode];
    // create the index on column nationalNumberIndex
    const char *sqliteCreateIndexStatement = [createIndex UTF8String];
    if(sqlite3_exec(_DB, sqliteCreateIndexStatement, NULL, NULL, &sqliteErrorMessage) == SQLITE_OK) {
        NSLog(@"Successfully applied index command: %@", createIndex);
    } else {
        NSLog(@"Error applying index command, %s", sqliteErrorMessage);
    }
}

// create an insert SQL statement with phone number and description attributes
-(int) createInsertStatement: (NSString*) phoneNumber withDescription: (NSString*) description withCountryCode: (NSString*) countryCode {
    int sqliteResultCode;
    NSLog(@"phone number: %@, description: %@, country code: %@", phoneNumber, description, countryCode);
    @autoreleasepool {
      sqliteResultCode = sqlite3_reset(_insertStatement);
        if(sqliteResultCode == SQLITE_OK) {
            sqlite3_bind_text(self.insertStatement, 1, [phoneNumber UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(self.insertStatement, 2, [description UTF8String], -1, SQLITE_TRANSIENT);
        } else {
            NSLog(@"The prepare statement result code was: %d", sqliteResultCode);
        }
    }
    NSLog(@"%s", sqlite3_expanded_sql(self.insertStatement));
    return sqliteResultCode;
}

// returns a select statement for finding description given a phone number
-(int) createSelectStatement: (NBPhoneNumber*) number {
    int sqliteResultCode;
    @autoreleasepool {
      sqliteResultCode = sqlite3_reset(_selectStatement);
        if(sqliteResultCode == SQLITE_OK) {
            const char* completePhoneNumber = [[NSString stringWithFormat:@"%@%@", number.countryCode, number.nationalNumber] UTF8String];
            sqlite3_bind_text(self.selectStatement, 1, completePhoneNumber, -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(self.selectStatement, 2, completePhoneNumber, -1, SQLITE_TRANSIENT);
        } else {
            NSLog(@"The prepare statement result code was: %d", sqliteResultCode);
        }
    }
    return sqliteResultCode;
}

// creating an index, full text search
-(void) addEntryToDB: (NSString*) phoneNumber withDescription: (NSString*) description withShouldCreateTable: (BOOL) shouldCreateTable withCountryCode: (NSString*) countryCode {
    @autoreleasepool {
        int sql_command_results = [self createInsertStatement:phoneNumber withDescription:description withCountryCode: countryCode];
        if(sql_command_results != SQLITE_OK) {
          NSLog(@"Error with preparing statement");
        }
       // only get the first row found
       if(sqlite3_step(self.insertStatement) == SQLITE_OK) {
           NSLog(@"ENTERED IN VALUE: %@", description);
       }
    }
}

// returns YES if result found, NO if no results found
-(NSString*) searchPhoneNumberInDatabase:(NBPhoneNumber*) number withLanguage: (NSString*) language {
//    NSLog(@"in SearchPhoneNumberInDatabase for: %@, %@", number, language);
    @autoreleasepool {
        if(![number.countryCode isEqualToNumber:self.countryCode]) {
            self.countryCode = number.countryCode;
            sqlite3_prepare_v2(self.DB, [[NSString stringWithFormat:@"WITH RECURSIVE cnt(x) AS ( SELECT 1 UNION ALL SELECT x+1 FROM cnt LIMIT length(?)), toSearch as (SELECT substr(?, 1, x) as indata FROM cnt) select nationalnumber, description, length(nationalnumber) as natLength from geocodingPairs%@ where NATIONALNUMBER in toSearch order by natLength desc limit 1", [self.countryCode stringValue]] UTF8String], -1, &_selectStatement, NULL);
            NSLog(@"CHANGED COUNTRY CODE FOR SEARCHING");
        }
        
        // if device language was altered since last call.
        if(![self.language isEqualToString:language]) {
            NSLog(@"LANGUAGE WAS CHANGED");
            self.language = language;
            
            // grab bundle of current pod instance
            NSBundle *bundle = [NSBundle bundleForClass: self.classForCoder];
            NSURL *bundleURL = [[bundle resourceURL] URLByAppendingPathComponent:@"Resources.bundle"];
            // create string for database directory
            NSString* databasePath = [NSString stringWithFormat:@"%@%@.db", bundleURL, language];
            self.databasePath = databasePath;
            NSLog(@"%@", databasePath);
             // open the database position
             if(sqlite3_open([databasePath UTF8String], & _DB) == SQLITE_OK) {
                 NSLog(@"Opened SQLite file successfully");
             } else {
                 NSLog(@"Was unable to open SQLite file properly");
             }
        }
        
        int sql_command_results;
        // if database hasn't been set, try opening and storing location
        if(self.DB == NULL) {
            sql_command_results = sqlite3_open_v2([self.databasePath UTF8String], &_DB, SQLITE_OPEN_READONLY , NULL);
            if (sql_command_results != SQLITE_OK) {
                NSLog(@"Failed to open db connection");
            } else {
                NSLog(@"Opened DB");
            }
        }
        sql_command_results = [self createSelectStatement:number];
        if(sql_command_results != SQLITE_OK) {
          NSLog(@"Error with preparing statement");
          return NULL;
        }
       // only get the first row found
        int step = sqlite3_step(self.selectStatement);
        if(step == SQLITE_ROW) {
            NSString *description = @((const char *)sqlite3_column_text(_selectStatement, 1));
            self.regionDescription = description;
            return description;
       }
    }
    return NULL;
}


@end
