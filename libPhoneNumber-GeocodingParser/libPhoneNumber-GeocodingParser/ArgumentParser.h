//
//  ArgumentParser.h
//  libPhoneNumber-GeocodingParser
//
//  Created by Kris Kline on 11/12/25.
//  Copyright © 2025 Rastaar Haghi. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 Struct to represent the command line arguments
 */
typedef struct {
    /// The directory to output all the language specific databases to
    NSString *directory;
    
    /// The version of metadata to download ('X.Y.Z' or 'master')
    NSString *version;
} ArgResult;

/**
 Parses the command arguments passed to this program
 
 - parameter argc: The argument count
 - parameter argv: The array of arguments
 
 - returns: An ArgResult representing the arguments passed to this program
 */
ArgResult *parseArguments(int argc, const char * argv[]);
