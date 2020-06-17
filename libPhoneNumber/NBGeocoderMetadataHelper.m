//
//  NBGeocoderMetadataHelper.m
//  libPhoneNumberiOS
//
//  Created by Rastaar Haghi on 6/12/20.
//  Copyright © 2020 ohtalk.me. All rights reserved.
//

#import "NBGeocoderMetadataHelper.h"


@implementation NBGeocoderMetadataHelper {
    @private
    NSString *databasePath;
    sqlite3 *DB;
    sqlite3_stmt *selectStatement;
}

-(instancetype) initWithCountryCode:(NSNumber *)countryCode withLanguage: (NSString*) language {
    self = [super init];
        
    self.countryCode = countryCode;
    self.language = language;
    // grab bundle of current pod instance
    NSBundle *bundle = [NSBundle bundleForClass: self.classForCoder];
    NSURL *bundleURL = [[bundle resourceURL] URLByAppendingPathComponent:@"Resources.bundle"];
    // create string for database directory
    NSString* databasePath = [NSString stringWithFormat:@"%@%@.db", bundleURL, self.language];
    self->databasePath = databasePath;
    
    // open the database position
    sqlite3_open([databasePath UTF8String], & self->DB);
    
    // set up prepared statements for inserting entry and searching for entry
    sqlite3_prepare_v2(self->DB, [[NSString stringWithFormat:@"WITH RECURSIVE cnt(x) AS ( SELECT 1 UNION ALL SELECT x+1 FROM cnt LIMIT length(?)), toSearch as (SELECT substr(?, 1, x) as indata FROM cnt) select nationalnumber, description, length(nationalnumber) as natLength from geocodingPairs%@ where NATIONALNUMBER in toSearch order by natLength desc limit 1", countryCode] UTF8String], -1, &self->selectStatement, NULL);
    return self;
}

- (void)dealloc {
    sqlite3_finalize(self->selectStatement);
    sqlite3_close_v2(self->DB);
}

// returns a select statement for finding description given a phone number
-(int) createSelectStatement: (NBPhoneNumber*) phoneNumber {
    int sqliteResultCode;
    @autoreleasepool {
      sqliteResultCode = sqlite3_reset(self->selectStatement);
        if(sqliteResultCode == SQLITE_OK) {
            const char* completePhoneNumber = [[NSString stringWithFormat:@"%@%@", phoneNumber.countryCode, phoneNumber.nationalNumber] UTF8String];
            sqlite3_bind_text(self->selectStatement, 1, completePhoneNumber, -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(self->selectStatement, 2, completePhoneNumber, -1, SQLITE_TRANSIENT);
        } else {
            NSLog(@"The prepare statement result code was: %d", sqliteResultCode);
        }
    }
    return sqliteResultCode;
}

// returns YES if result found, NO if no results found
-(NSString*) searchPhoneNumberInDatabase:(NBPhoneNumber*) phoneNumber {
//    NSLog(@"in SearchPhoneNumberInDatabase for: %@, %@", number, language);
    @autoreleasepool {
        if(![phoneNumber.countryCode isEqualToNumber:self.countryCode]) {
            self.countryCode = phoneNumber.countryCode;
            sqlite3_prepare_v2(self->DB, [[NSString stringWithFormat:@"WITH RECURSIVE cnt(x) AS ( SELECT 1 UNION ALL SELECT x+1 FROM cnt LIMIT length(?)), toSearch as (SELECT substr(?, 1, x) as indata FROM cnt) select nationalnumber, description, length(nationalnumber) as natLength from geocodingPairs%@ where NATIONALNUMBER in toSearch order by natLength desc limit 1", [self.countryCode stringValue]] UTF8String], -1, &self->selectStatement, NULL);
            NSLog(@"CHANGED COUNTRY CODE FOR SEARCHING");
        }
        
        int sql_command_results;
        // if database hasn't been set, try opening and storing location
        if(self->DB == NULL) {
            sql_command_results = sqlite3_open_v2([self->databasePath UTF8String], &self->DB, SQLITE_OPEN_READONLY , NULL);
            if (sql_command_results != SQLITE_OK) {
                NSLog(@"Failed to open db connection");
            } else {
                NSLog(@"Opened DB");
            }
        }
        sql_command_results = [self createSelectStatement:phoneNumber];
        if(sql_command_results != SQLITE_OK) {
          NSLog(@"Error with preparing statement");
          return @"";
        }
       // only get the first row found
        NSLog(@"%s", sqlite3_expanded_sql(self->selectStatement));
        int step = sqlite3_step(self->selectStatement);
        if(step == SQLITE_ROW) {
            NSString *description = @((const char *)sqlite3_column_text(self->selectStatement, 1));
            self.regionDescription = description;
            return description;
       }
    }
    return @"";
}


@end
