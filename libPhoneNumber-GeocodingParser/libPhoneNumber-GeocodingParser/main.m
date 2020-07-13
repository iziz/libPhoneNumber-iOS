//
//  main.m
//  libPhoneNumber-GeocodingParser
//
//  Created by Rastaar Haghi on 7/1/20.
//  Copyright © 2020 Google LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NBGeocoderMetadataParser.h"

int main(int argc, const char *argv[]) {
  @autoreleasepool {
    if (argc != 3) {
      NSLog(@"The libPhoneNumber-iOS Geocoder Parser requires two input arguments to properly "
            @"function.");
      NSLog(@"1. The complete folder path where the libPhoneNumber geocoding resource folder "
            @"(found at: https://github.com/google/libphonenumber/tree/master/resources/geocoding) "
            @"is stored on disk.");
      NSLog(@"2. The complete directory path to the desired location to store the corresponding "
            @"SQLite databases created.");
      NSLog(@"Example arguments: Users/JohnDoe/Documents/geocoding   Users/JohnDoe/Desktop");
    } else {
      NSString *geocodingMetadataDirectory = [NSString stringWithUTF8String:argv[1]];
      NSString *databaseDesiredLocation = [NSString stringWithUTF8String:argv[2]];

      NBGeocoderMetadataParser *metadataParser = [[NBGeocoderMetadataParser alloc]
          initWithDesiredDatabaseLocation:databaseDesiredLocation];

      NSArray *languages =
          [[NSFileManager defaultManager] contentsOfDirectoryAtPath:geocodingMetadataDirectory
                                                              error:NULL];
      NSArray *textFilesAvailable;
      NSString *languageFolderPath;
      for (NSString *language in languages) {
        NSLog(@"Creating SQLite database file for the language: %@", language);
        languageFolderPath =
            [NSString stringWithFormat:@"%@/%@", geocodingMetadataDirectory, language];
        textFilesAvailable =
            [[NSFileManager defaultManager] contentsOfDirectoryAtPath:languageFolderPath
                                                                error:NULL];
        [textFilesAvailable enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
          NSString *filename = (NSString *)obj;
          NSString *extension = [[filename pathExtension] lowercaseString];

          if ([extension isEqualToString:@"txt"]) {
            NSString *completeFilePath =
                [NSString stringWithFormat:@"%@/%@", languageFolderPath, filename];
            [metadataParser convertFileToSQLiteDatabase:completeFilePath
                                           withFileName:filename
                                           withLanguage:language];
          }
        }];
        NSLog(@"Created SQLite database file for the language: %@", language);
      }
    }
  }

  return 0;
}
