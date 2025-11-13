//
//  NSString+Extensions.m
//  libPhoneNumber-GeocodingParser
//
//  Created by Kris Kline on 11/12/25.
//  Copyright © 2025 Rastaar Haghi. All rights reserved.
//

#import "NSString+Extensions.h"

@implementation NSString(Extensions)

- (BOOL)isVersion {
    static NSRegularExpression* versionRegex = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        versionRegex = [NSRegularExpression regularExpressionWithPattern:@"^\\d+(\\.\\d+){0,2}$"
                                                                 options:0
                                                                   error:nil];
    });
    NSRange range = NSMakeRange(0, self.length);
    NSUInteger matchCount = [versionRegex numberOfMatchesInString:self options:0 range:range];
    return matchCount == 1;
}

- (NSString*)removeAnyOccurrencesOfStrings:(NSArray<NSString *> *)substrings {
    NSString* result = [self copy];
    for (NSString* substr in substrings) {
        result = [result stringByReplacingOccurrencesOfString:substr withString:@""];
    }
    return result;
}
@end
