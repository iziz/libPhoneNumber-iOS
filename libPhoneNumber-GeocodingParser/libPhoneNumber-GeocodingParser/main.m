//
//  main.m
//  libPhoneNumber-GeocodingParser
//
//  Created by Rastaar Haghi on 7/1/20.
//  Copyright © 2020 Google LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NBGeocoderMetadataParser.h"
#import "SSZipArchive.h"

int main(int argc, const char *argv[]) {
  @autoreleasepool {
    if (argc != 2) {
      NSLog(@"The libPhoneNumber-iOS Geocoder Parser requires 1 input arguments to properly "
            @"function.");
      NSLog(@"1. The complete directory path to the desired location to store the corresponding "
            @"SQLite databases created.");
      NSLog(@"Example argument: Users/JohnDoe/Desktop");
    } else {
      // Download zip file from GitHub.
      NSString *repositoryString = @"https://github.com/google/libphonenumber/archive/master.zip";
      NSURL *databaseDesiredLocation = [NSURL fileURLWithPath:@(argv[1])];
      NSURL *libPhoneNumberRepoURL = [NSURL URLWithString:repositoryString];

      NSLog(@"Downloading geocoding metadata files from %@", repositoryString);
      NSData *libPhoneNumberData = [NSData dataWithContentsOfURL:libPhoneNumberRepoURL];
      NSLog(@"Downloaded geocoding metadata files.");

      // Gather the documents directory path
      NSString *temporaryDirectoryPath = NSTemporaryDirectory();
      NSString *zipFilePath =
          [temporaryDirectoryPath stringByAppendingPathComponent:@"/libPhoneNumber-iOS.zip"];
      zipFilePath = [zipFilePath stringByStandardizingPath];
      [libPhoneNumberData writeToFile:zipFilePath atomically:YES];
      NSLog(@"Attempting to unzip downloaded metadata.");

      // Unzip libphonenumber-master project using SSZipArchive library.
      [SSZipArchive unzipFileAtPath:zipFilePath toDestination:temporaryDirectoryPath];
      NSLog(@"Successfully unzipped metadata files.");

      // Navigate through project to geocoding metadata resource files.
      NSString *libPhoneNumberFolderPath =
          [NSString stringWithFormat:@"%@/libphonenumber-master", temporaryDirectoryPath];
      NSError *error;
      NSArray *filesInDirectory =
          [[NSFileManager defaultManager] contentsOfDirectoryAtPath:libPhoneNumberFolderPath
                                                              error:&error];
      if (error != nil) {
        NSLog(@"An error occurred when attempting to access files in repository. Error message: %@",
              error.description);
        return 1;
      }
      if ([filesInDirectory containsObject:@"resources"]) {
        NSString *resourcesFolderPath =
            [NSString stringWithFormat:@"%@/resources", libPhoneNumberFolderPath];
        filesInDirectory =
            [[NSFileManager defaultManager] contentsOfDirectoryAtPath:resourcesFolderPath
                                                                error:&error];
        if (error != NULL) {
          NSLog(@"An error occurred when attempting to access files in project's 'resources' "
                @"folder. Error message: %@",
                error.description);
          return 1;
        }
        if ([filesInDirectory containsObject:@"geocoding"]) {
          NSString *geocodingFolderPath =
              [NSString stringWithFormat:@"%@/geocoding", resourcesFolderPath];
          NSArray *languages =
              [[NSFileManager defaultManager] contentsOfDirectoryAtPath:geocodingFolderPath
                                                                  error:&error];
          if (error != NULL) {
            NSLog(@"An error occurred when attempting to access files in project's 'geocoding' "
                  @"folder. Error message: %@",
                  error.description);
            return 1;
          }
          NBGeocoderMetadataParser *metadataParser = [[NBGeocoderMetadataParser alloc]
              initWithDestinationPath:[databaseDesiredLocation copy]];
            
          NSArray *textFilesAvailable;
          NSString *languageFolderPath;
          for (NSString *language in languages) {
            NSLog(@"Creating SQLite database file for the language: %@", language);
            languageFolderPath =
                [NSString stringWithFormat:@"%@/%@", geocodingFolderPath, language];
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
    }
  }

  return 0;
}
