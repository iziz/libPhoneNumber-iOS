//
//  main.m
//  libPhoneNumber-GeocodingParser
//
//  Created by Rastaar Haghi on 7/1/20.
//  Copyright © 2020 Google LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SSZipArchive.h"

#import "NBGeocoderMetadataParser.h"
#import "ArgumentParser.h"

int main(int argc, const char *argv[]) {
  @autoreleasepool {
    ArgResult* argResult = parseArguments(argc, argv);
    if (argResult == nil) {
      NSLog(@"The libPhoneNumber-iOS Geocoder Parser requires 2 input arguments to properly function.\n"
            "1. The version of metadata to download from the libphonenumber repo\n"
            "2. The complete directory path to the desired location to store the corresponding SQLite databases created.\n"
            "Example argument: /Users/JohnDoe/Desktop/geocoding/");
      return 1;
    }

    // Download zip file from GitHub.
      
    NSString* branch = argResult->version;
    NSString* archiveVersion = branch;
    if(![branch isEqualToString:@"master"]) {
        archiveVersion = [NSString stringWithFormat:@"v%@", branch];
    }

    NSString *repositoryString = [NSString stringWithFormat:@"https://github.com/google/libphonenumber/archive/%@.zip", archiveVersion];
    
    NSURL *libPhoneNumberRepoURL = [NSURL URLWithString:repositoryString];
    NSURL *databaseDesiredLocation = [NSURL fileURLWithPath:argResult->directory];

    NSLog(@"Downloading geocoding metadata files from %@", repositoryString);
    NSData *libPhoneNumberData = [NSData dataWithContentsOfURL:libPhoneNumberRepoURL];
    if(libPhoneNumberData==nil) {
      NSLog(@"Failed to download data from: %@", repositoryString);
      return 1;
    }
    
    NSLog(@"Downloaded geocoding metadata files.");

    // Gather the documents directory path
    NSString *temporaryDirectoryPath = NSTemporaryDirectory();
    NSString *zipFilePath =  [temporaryDirectoryPath stringByAppendingPathComponent:@"libPhoneNumber-iOS.zip"];
    zipFilePath = [zipFilePath stringByStandardizingPath];
    if(![libPhoneNumberData writeToFile:zipFilePath atomically:YES]) {
      NSLog(@"Failed to write to file: %@", zipFilePath);
      return 1;
    }
      
    NSLog(@"Attempting to unzip downloaded metadata.");

    // Unzip libphonenumber-master project using SSZipArchive library.
    [SSZipArchive unzipFileAtPath:zipFilePath toDestination:temporaryDirectoryPath];
    NSLog(@"Successfully unzipped metadata files.");

    // Navigate through project to geocoding metadata resource files.
    NSString *libPhoneNumberFolderPath = [temporaryDirectoryPath stringByAppendingPathComponent:[NSString stringWithFormat:@"libphonenumber-%@", branch]];
    NSError *error;
    NSArray *filesInDirectory = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:libPhoneNumberFolderPath error:&error];
    if (error != nil) {
      NSLog(@"An error occurred when attempting to access files in repository. Error message: %@", error.description);
      return 1;
    }
    
    if (![filesInDirectory containsObject:@"resources"]) {
      NSLog(@"No 'resources' directory found");
      return 1;
    }
    
      NSString *resourcesFolderPath = [libPhoneNumberFolderPath stringByAppendingPathComponent:@"resources"];
    filesInDirectory = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:resourcesFolderPath error:&error];
    if (error != NULL) {
      NSLog(@"An error occurred when attempting to access files in project's 'resources' folder. Error message: %@", error.description);
      return 1;
    }
    
    if (![filesInDirectory containsObject:@"geocoding"]) {
      NSLog(@"No 'geocoding' directory found");
      return 1;
    }
    
    NSString *geocodingFolderPath = [resourcesFolderPath stringByAppendingPathComponent:@"geocoding"];
    NSArray *languages = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:geocodingFolderPath error:&error];
    if (error != NULL) {
      NSLog(@"An error occurred when attempting to access files in project's 'geocoding' folder. Error message: %@", error.description);
      return 1;
    }

    NBGeocoderMetadataParser *metadataParser = [[NBGeocoderMetadataParser alloc] initWithDestinationPath:[databaseDesiredLocation copy]];

    NSLog(@"Saving language databases to folder: %@", databaseDesiredLocation.path);
      
    NSArray *textFilesAvailable;
    NSString *languageFolderPath;
    for (NSString *language in languages) {
      NSLog(@"Creating SQLite database file for the language: %@", language);
      languageFolderPath = [geocodingFolderPath stringByAppendingPathComponent:language];
      textFilesAvailable = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:languageFolderPath error:&error];
      if (error != NULL) {
        NSLog(@"Error occurred when trying to read files for the language directory: %@", languageFolderPath);
        error = NULL;
        continue;
      }

      for (NSString *filename in textFilesAvailable) {
        NSString *extension = [[filename pathExtension] lowercaseString];
        if ([extension isEqualToString:@"txt"]) {
          NSString *completeFilePath = [languageFolderPath stringByAppendingPathComponent:filename];
          [metadataParser convertFileToSQLiteDatabase:completeFilePath
                                         withFileName:filename
                                         withLanguage:language
                                        loggingIndent:@"   "];
        }
      }
        
      NSLog(@"  Created SQLite database file for the language: %@", language);
    }
  }
  
    NSLog(@"\nGeocoding data updated successfully!\n\n");
  return 0;
}
