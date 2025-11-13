//
//  ArgumentParser.m
//  libPhoneNumber-GeocodingParser
//
//  Created by Kris Kline on 11/12/25.
//  Copyright © 2025 Rastaar Haghi. All rights reserved.
//

#import "ArgumentParser.h"

#import "NSString+Extensions.h"

ArgResult *parseArguments(int argc, const char * argv[]) {
    NSString *dir = nil;
    NSString *ver = nil;
    for(int i=1; i<argc; i++) {
        NSString *arg = [NSString stringWithUTF8String:argv[i]];
        // Remove known version prefixes
        NSString *normalized = arg;
        if ([arg hasPrefix:@"--v"] || [arg hasPrefix:@"-v"] || [arg hasPrefix:@"v"]) {
            normalized = [arg removeAnyOccurrencesOfStrings:@[@"v", @"-v", @"--v"]];
            if (normalized.isVersion) {
                ver = normalized;
            }
        } else if (arg.isVersion) {
            ver = normalized;
        } else if ([arg isEqualToString:@"master"] || [arg isEqualToString:@"-master"] || [arg isEqualToString:@"--master"]) {
            ver = @"master";
        } else {
            dir = arg;
        }
    }
    if (dir==nil || ver==nil) {
        return nil;
    }
    ArgResult *result = malloc(sizeof(ArgResult));
    result->directory = dir;
    result->version = ver;
    return result;
}
