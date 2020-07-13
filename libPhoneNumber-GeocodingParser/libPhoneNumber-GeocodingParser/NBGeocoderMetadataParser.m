//
//  NBGeocoderMetadataParser.m
//  libPhoneNumber-GeocodingParser
//
//  Created by Rastaar Haghi on 7/1/20.
//  Copyright © 2020 Google LLC. All rights reserved.
//

#import "NBGeocoderMetadataParser.h"

@implementation NBGeocoderMetadataParser {
  NSURL *_destinationPath;
}

- (instancetype)initWithDestinationPath:(NSURL *)destinationPath {
  self = [super init];
  if (self != nil) {
    _destinationPath = destinationPath;
  }
  return self;
}

- (void)convertFileToSQLiteDatabase:(NSString *)completeTextFilePath
                       withFileName:(NSString *)textFileName
                       withLanguage:(NSString *)languageCode {
  NSString *fileContentString = [[NSString alloc] initWithContentsOfFile:completeTextFilePath
                                                                encoding:NSUTF8StringEncoding
                                                                   error:nil];
  NSArray<NSString *> *countryCodes = [textFileName componentsSeparatedByString:@"."];

  NSString *countryCode = countryCodes[0];
  NSLog(@"Creating a SQL table for the country code: %@, in the language: %@", countryCode,
        languageCode);
  NBSQLiteDatabaseConnection *databaseConnection =
      [[NBSQLiteDatabaseConnection alloc] initWithCountryCode:countryCode
                                                 withLanguage:languageCode
                                          withDestinationPath:_destinationPath];

  // Split into phone number prefix and region description.
  NSCharacterSet *separator = [NSCharacterSet newlineCharacterSet];
  NSArray *components = [fileContentString componentsSeparatedByCharactersInSet:separator];
  NSArray<NSString *> *keyValuePair;

  NSString *key, *value;
  BOOL indexNeededFlag = YES;
  for (NSString *str in components) {
    @autoreleasepool {
      // Skip entry if invalid, malformatted, or comment.
      if (([str length] > 0) && ([str characterAtIndex:0] == '#')) {
        continue;
      }
      keyValuePair = [str componentsSeparatedByString:@"|"];
      if ([keyValuePair count] != 2) {
        continue;
      }
      key = [keyValuePair[0]
          stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
      value = [keyValuePair[1]
          stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
      [databaseConnection addEntryToDB:key withDescription:value withCountryCode:countryCode];
      indexNeededFlag = NO;
    }
  }
}

@end
