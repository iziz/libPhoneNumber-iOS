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
      NSLog(@"Example arguments: Users/JohnDoe/Documents/geocoding Users/JohnDoe/Desktop");
    } else {
      NSString *geocodingMetadataDirectory = @(argv[1]);
      NSURL *databaseDesiredLocation = [NSURL URLWithString:@(argv[2])];
      NBGeocoderMetadataParser *metadataParser =
          [[NBGeocoderMetadataParser alloc] initWithDestinationPath:[databaseDesiredLocation copy]];
      NSError *error;
      NSArray *languages =
          [[NSFileManager defaultManager] contentsOfDirectoryAtPath:geocodingMetadataDirectory
                                                              error:&error];
      if (error != NULL) {
        NSLog(@"Error occurred when trying to read directory: %@"
              @"Error message: %@",
              geocodingMetadataDirectory, [error localizedDescription]);
        return 1;
      }
      NSArray *textFilesAvailable;
      NSString *languageFolderPath;
      for (NSString *language in languages) {
        NSLog(@"Creating SQLite database file for the language: %@", language);
        languageFolderPath =
            [NSString stringWithFormat:@"%@/%@", geocodingMetadataDirectory, language];
        textFilesAvailable =
            [[NSFileManager defaultManager] contentsOfDirectoryAtPath:languageFolderPath
                                                                error:&error];
        if (error != NULL) {
          NSLog(@"Error occurred when trying to read files for the language directory: %@",
                languageFolderPath);
          error = NULL;
          continue;
        }
        for (NSString *filename in textFilesAvailable) {
          NSString *extension = [[filename pathExtension] lowercaseString];

          if ([extension isEqualToString:@"txt"]) {
            NSString *completeFilePath =
                [NSString stringWithFormat:@"%@/%@", languageFolderPath, filename];
            [metadataParser convertFileToSQLiteDatabase:completeFilePath
                                           withFileName:filename
                                           withLanguage:language];
          }
        }
        NSLog(@"Created SQLite database file for the language: %@", language);
      }
    }
  }

  return 0;
}
