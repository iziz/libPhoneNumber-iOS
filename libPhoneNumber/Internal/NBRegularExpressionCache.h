//
//  NBRegularExpressionCache.h
//  libPhoneNumber
//
//  Created by Paween Itthipalkul on 11/29/17.
//  Copyright © 2017 Google LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NBRegularExpressionCache : NSObject

/**
 Returns a singleton instance of the regular expression cache.

 @return An instance of NBRegularExpressionCache
 */
+ (instancetype)sharedInstance;

/**
 Returns compiled regular expression for a given pattern.

 @param pattern Regular expression pattern.
 @return A regular expression.
 */
- (nullable NSRegularExpression *)regularExpressionForPattern:(NSString *)pattern;

@end

NS_ASSUME_NONNULL_END
