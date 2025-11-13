//
//  NSString+Extensions.h
//  libPhoneNumber-GeocodingParser
//
//  Created by Kris Kline on 11/12/25.
//  Copyright © 2025 Rastaar Haghi. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (Extensions)

/**
 @returns: Whether this string represents a numbered version: X.Y.Z, X.Y, or Z
 */
- (BOOL)isVersion;

/**
 Removes any occurrence of the specific strings from this string and returns the new string
 - parameter substrings: The strings to remove from this string
 
 - returns: The new string without any occurrences of the specified strings
 */
- (NSString*)removeAnyOccurrencesOfStrings:(NSArray<NSString*>*)substrings;

@end
