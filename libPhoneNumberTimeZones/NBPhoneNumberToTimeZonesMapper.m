//
//  NBPhoneNumberToTimeZonesMapper.m
//  libPhoneNumberTimeZones
//

#import <sqlite3.h>

#import "NBPhoneNumber.h"
#import "NBPhoneNumberToTimeZonesMapper.h"
#import "NBPhoneNumberUtil.h"

static NSString *const NBUnknownTimeZone = @"Etc/Unknown";

@implementation NBPhoneNumberToTimeZonesMapper {
 @private
  NBPhoneNumberUtil *_phoneNumberUtil;
  sqlite3 *_database;
  sqlite3_stmt *_selectStatement;
  sqlite3_stmt *_countryLevelSelectStatement;
}

static NSString *const NBTimeZoneSelectStatement =
    @"WITH recursive count(x) AS ("
     "SELECT 1 "
     "UNION ALL "
     "SELECT x + 1 FROM count LIMIT length(?)), "
     "tosearch AS ("
     "SELECT substr(?, 1, x) AS prefix FROM count) "
     "SELECT time_zones, length(prefix) AS prefix_length "
     "FROM timezone_prefixes "
     "WHERE prefix IN tosearch "
     "ORDER BY prefix_length DESC "
     "LIMIT 1";

static NSString *const NBCountryLevelTimeZoneSelectStatement =
    @"SELECT time_zones FROM timezone_prefixes WHERE prefix = ? LIMIT 1";

+ (instancetype)sharedInstance {
  static dispatch_once_t onceToken;
  static NBPhoneNumberToTimeZonesMapper *instance;
  dispatch_once(&onceToken, ^{
    instance = [[self alloc] init];
  });
  return instance;
}

+ (NSString *)unknownTimeZone {
  return NBUnknownTimeZone;
}

- (instancetype)init {
  return [self initWithPhoneNumberUtil:NBPhoneNumberUtil.sharedInstance
                                bundle:[self.class defaultMetadataBundle]];
}

- (instancetype)initWithPhoneNumberUtil:(NBPhoneNumberUtil *)phoneNumberUtil
                                 bundle:(NSBundle *)bundle {
  self = [super init];
  if (self != nil) {
    _phoneNumberUtil = phoneNumberUtil;
    [self openDatabaseInBundle:bundle];
  }
  return self;
}

- (void)dealloc {
  sqlite3_finalize(_selectStatement);
  sqlite3_finalize(_countryLevelSelectStatement);
  sqlite3_close_v2(_database);
}

- (NSArray<NSString *> *)timeZonesForNumber:(NBPhoneNumber *)number {
  NBEPhoneNumberType numberType = [_phoneNumberUtil getNumberType:number];
  if (numberType == NBEPhoneNumberTypeUNKNOWN) {
    return [self unknownTimeZoneList];
  }

  if (![_phoneNumberUtil isNumberGeographical:number]) {
    return [self countryLevelTimeZonesForNumber:number];
  }

  return [self timeZonesForGeographicalNumber:number];
}

- (NSArray<NSString *> *)timeZonesForGeographicalNumber:(NBPhoneNumber *)number {
  NSString *completeNumber = [self completeNumberForNumber:number];
  NSArray<NSString *> *timeZones = [self timeZonesForPrefix:completeNumber
                                                  statement:_selectStatement];
  return timeZones.count > 0 ? timeZones : [self unknownTimeZoneList];
}

- (NSArray<NSString *> *)countryLevelTimeZonesForNumber:(NBPhoneNumber *)number {
  NSString *countryCode = [number.countryCode stringValue];
  NSArray<NSString *> *timeZones = [self timeZonesForPrefix:countryCode
                                                  statement:_countryLevelSelectStatement];
  return timeZones.count > 0 ? timeZones : [self unknownTimeZoneList];
}

- (NSArray<NSString *> *)unknownTimeZoneList {
  return @[ NBUnknownTimeZone ];
}

- (void)openDatabaseInBundle:(NSBundle *)bundle {
  NSURL *databaseURL = [[bundle resourceURL] URLByAppendingPathComponent:@"timezones.db"];
  NSString *databasePath = [databaseURL path];
  if (databasePath == nil) {
    return;
  }

  if (sqlite3_open([databasePath UTF8String], &_database) != SQLITE_OK) {
    sqlite3_close_v2(_database);
    _database = NULL;
    return;
  }

  sqlite3_prepare_v2(_database, [NBTimeZoneSelectStatement UTF8String], -1,
                     &_selectStatement, NULL);
  sqlite3_prepare_v2(_database, [NBCountryLevelTimeZoneSelectStatement UTF8String], -1,
                     &_countryLevelSelectStatement, NULL);
}

+ (NSBundle *)defaultMetadataBundle {
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
      NSArray<NSURL *> *candidateURLs = @[
        [baseURL URLByAppendingPathComponent:@"TimeZonesMetaData.bundle"],
        [[baseURL URLByAppendingPathComponent:@"libPhoneNumber_libPhoneNumberTimeZonesMetaData.bundle"]
            URLByAppendingPathComponent:@"TimeZonesMetaData.bundle"],
      ];

      for (NSURL *candidateURL in candidateURLs) {
        NSURL *databaseURL = [candidateURL URLByAppendingPathComponent:@"timezones.db"];
        if ([[NSFileManager defaultManager] fileExistsAtPath:databaseURL.path]) {
          return [NSBundle bundleWithURL:candidateURL];
        }
      }
    }
  }

  return nil;
}

- (NSArray<NSString *> *)timeZonesForPrefix:(NSString *)prefix statement:(sqlite3_stmt *)statement {
  @synchronized(self) {
    if (_database == NULL || statement == NULL || prefix.length == 0) {
      return @[];
    }

    int resetResult = sqlite3_reset(statement);
    if (resetResult != SQLITE_OK) {
      return @[];
    }

    int clearResult = sqlite3_clear_bindings(statement);
    if (clearResult != SQLITE_OK) {
      return @[];
    }

    const char *prefixText = [prefix UTF8String];
    sqlite3_bind_text(statement, 1, prefixText, -1, SQLITE_TRANSIENT);
    if (statement == _selectStatement) {
      sqlite3_bind_text(statement, 2, prefixText, -1, SQLITE_TRANSIENT);
    }

    int step = sqlite3_step(statement);
    if (step != SQLITE_ROW) {
      return @[];
    }

    const unsigned char *rawTimeZones = sqlite3_column_text(statement, 0);
    if (rawTimeZones == NULL) {
      return @[];
    }

    NSString *timeZones = [NSString stringWithUTF8String:(const char *)rawTimeZones];
    if (timeZones.length == 0) {
      return @[];
    }

    return [timeZones componentsSeparatedByString:@"&"];
  }
}

- (NSString *)completeNumberForNumber:(NBPhoneNumber *)number {
  NSString *nationalSignificantNumber = [_phoneNumberUtil getNationalSignificantNumber:number];
  return [NSString stringWithFormat:@"%@%@", number.countryCode, nationalSignificantNumber];
}

@end
