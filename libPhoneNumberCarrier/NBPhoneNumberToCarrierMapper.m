//
//  NBPhoneNumberToCarrierMapper.m
//  libPhoneNumberCarrier
//

#import <sqlite3.h>

#import "NBPhoneNumber.h"
#import "NBPhoneNumberToCarrierMapper.h"
#import "NBPhoneNumberUtil.h"

@implementation NBPhoneNumberToCarrierMapper {
 @private
  NBPhoneNumberUtil *_phoneNumberUtil;
  sqlite3 *_database;
  sqlite3_stmt *_selectStatement;
  sqlite3_stmt *_mobilePortableRegionStatement;
}

static NSString *const NBCarrierSelectStatement =
    @"WITH recursive count(x) AS ("
     "SELECT 1 "
     "UNION ALL "
     "SELECT x + 1 FROM count LIMIT length(?)), "
     "tosearch AS ("
     "SELECT substr(?, 1, x) AS prefix FROM count) "
     "SELECT carrier_name, length(prefix) AS prefix_length "
     "FROM carrier_prefixes "
     "WHERE locale = ? AND prefix IN tosearch "
     "ORDER BY prefix_length DESC "
     "LIMIT 1";

static NSString *const NBMobilePortableRegionSelectStatement =
    @"SELECT 1 FROM mobile_portable_regions WHERE region_code = ? LIMIT 1";

+ (instancetype)sharedInstance {
  static dispatch_once_t onceToken;
  static NBPhoneNumberToCarrierMapper *instance;
  dispatch_once(&onceToken, ^{
    instance = [[self alloc] init];
  });
  return instance;
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
  sqlite3_finalize(_mobilePortableRegionStatement);
  sqlite3_close_v2(_database);
}

- (NSString *)nameForNumber:(NBPhoneNumber *)number localeCode:(NSString *)localeCode {
  NBEPhoneNumberType type = [_phoneNumberUtil getNumberType:number];
  if (![self supportsCarrierLookupForType:type]) {
    return @"";
  }
  return [self nameForValidNumber:number localeCode:localeCode];
}

- (NSString *)nameForValidNumber:(NBPhoneNumber *)number localeCode:(NSString *)localeCode {
  NSString *completeNumber = [self completeNumberForNumber:number];
  NSArray<NSString *> *locales = [self lookupLocalesForLocaleCode:localeCode];
  for (NSString *locale in locales) {
    NSString *carrierName = [self carrierNameForPrefix:completeNumber locale:locale];
    if (carrierName.length > 0) {
      return carrierName;
    }
  }
  return @"";
}

- (NSString *)safeDisplayNameForNumber:(NBPhoneNumber *)number localeCode:(NSString *)localeCode {
  NSString *regionCode = [_phoneNumberUtil getRegionCodeForNumber:number];
  if ([self isMobileNumberPortableRegion:regionCode]) {
    return @"";
  }
  return [self nameForNumber:number localeCode:localeCode];
}

- (BOOL)supportsCarrierLookupForType:(NBEPhoneNumberType)type {
  return type == NBEPhoneNumberTypeMOBILE ||
         type == NBEPhoneNumberTypeFIXED_LINE_OR_MOBILE ||
         type == NBEPhoneNumberTypePAGER;
}

- (NSArray<NSString *> *)lookupLocalesForLocaleCode:(NSString *)localeCode {
  NSString *normalized = [localeCode stringByReplacingOccurrencesOfString:@"-" withString:@"_"];
  NSString *language = [[normalized componentsSeparatedByString:@"_"] firstObject] ?: @"";
  NSMutableArray<NSString *> *locales = [NSMutableArray array];

  if (normalized.length > 0) {
    [locales addObject:normalized];
  }
  if (language.length > 0 && ![locales containsObject:language]) {
    [locales addObject:language];
  }
  if (![self shouldSuppressEnglishFallbackForLanguage:language] &&
      ![locales containsObject:@"en"]) {
    [locales addObject:@"en"];
  }
  return locales;
}

- (BOOL)shouldSuppressEnglishFallbackForLanguage:(NSString *)language {
  return [language isEqualToString:@"zh"] ||
         [language isEqualToString:@"ja"] ||
         [language isEqualToString:@"ko"];
}

- (void)openDatabaseInBundle:(NSBundle *)bundle {
  NSURL *databaseURL = [[bundle resourceURL] URLByAppendingPathComponent:@"carriers.db"];
  NSString *databasePath = [databaseURL path];
  if (databasePath == nil) {
    return;
  }

  if (sqlite3_open([databasePath UTF8String], &_database) != SQLITE_OK) {
    sqlite3_close_v2(_database);
    _database = NULL;
    return;
  }

  sqlite3_prepare_v2(_database, [NBCarrierSelectStatement UTF8String], -1,
                     &_selectStatement, NULL);
  sqlite3_prepare_v2(_database, [NBMobilePortableRegionSelectStatement UTF8String], -1,
                     &_mobilePortableRegionStatement, NULL);
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
        [baseURL URLByAppendingPathComponent:@"CarrierMetaData.bundle"],
        [[baseURL URLByAppendingPathComponent:@"libPhoneNumber_libPhoneNumberCarrierMetaData.bundle"]
            URLByAppendingPathComponent:@"CarrierMetaData.bundle"],
      ];

      for (NSURL *candidateURL in candidateURLs) {
        NSURL *databaseURL = [candidateURL URLByAppendingPathComponent:@"carriers.db"];
        if ([[NSFileManager defaultManager] fileExistsAtPath:databaseURL.path]) {
          return [NSBundle bundleWithURL:candidateURL];
        }
      }
    }
  }

  return nil;
}

- (NSString *)carrierNameForPrefix:(NSString *)prefix locale:(NSString *)locale {
  @synchronized(self) {
    if (_database == NULL || _selectStatement == NULL || prefix.length == 0 || locale.length == 0) {
      return @"";
    }

    if (sqlite3_reset(_selectStatement) != SQLITE_OK ||
        sqlite3_clear_bindings(_selectStatement) != SQLITE_OK) {
      return @"";
    }

    const char *prefixText = [prefix UTF8String];
    sqlite3_bind_text(_selectStatement, 1, prefixText, -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(_selectStatement, 2, prefixText, -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(_selectStatement, 3, [locale UTF8String], -1, SQLITE_TRANSIENT);

    if (sqlite3_step(_selectStatement) != SQLITE_ROW) {
      return @"";
    }

    const unsigned char *rawCarrierName = sqlite3_column_text(_selectStatement, 0);
    if (rawCarrierName == NULL) {
      return @"";
    }
    return [NSString stringWithUTF8String:(const char *)rawCarrierName] ?: @"";
  }
}

- (BOOL)isMobileNumberPortableRegion:(NSString *)regionCode {
  @synchronized(self) {
    if (_database == NULL || _mobilePortableRegionStatement == NULL || regionCode.length == 0) {
      return NO;
    }

    if (sqlite3_reset(_mobilePortableRegionStatement) != SQLITE_OK ||
        sqlite3_clear_bindings(_mobilePortableRegionStatement) != SQLITE_OK) {
      return NO;
    }

    sqlite3_bind_text(_mobilePortableRegionStatement, 1, [regionCode UTF8String], -1,
                      SQLITE_TRANSIENT);
    return sqlite3_step(_mobilePortableRegionStatement) == SQLITE_ROW;
  }
}

- (NSString *)completeNumberForNumber:(NBPhoneNumber *)number {
  NSString *nationalSignificantNumber = [_phoneNumberUtil getNationalSignificantNumber:number];
  return [NSString stringWithFormat:@"%@%@", number.countryCode, nationalSignificantNumber];
}

@end
