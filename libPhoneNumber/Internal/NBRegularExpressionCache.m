//
//  NBRegularExpressionCache.m
//  libPhoneNumber
//
//  Created by Paween Itthipalkul on 11/29/17.
//  Copyright © 2017 Google LLC. All rights reserved.
//

#import "NBRegularExpressionCache.h"

@interface NBRegularExpressionCache()

@property (nonatomic, strong) NSCache *cache;

@end

@implementation NBRegularExpressionCache

+ (instancetype)sharedInstance {
  static NBRegularExpressionCache *instance;
  static dispatch_once_t token;
  dispatch_once(&token, ^{
    instance = [[NBRegularExpressionCache alloc] init];
  });

  return instance;
}

- (instancetype)init {
  self = [super init];
  if (self != nil) {
    _cache = [[NSCache alloc] init];
  }

  return self;
}

- (NSRegularExpression *)regularExpressionForPattern:(NSString *)pattern {
  @synchronized(self) {
    NSRegularExpression *cachedObject = [self.cache objectForKey:pattern];
    if (cachedObject != nil) {
      return cachedObject;
    }

    NSError *error = nil;
    NSRegularExpression *regEx = [[NSRegularExpression alloc] initWithPattern:pattern
                                                                      options:kNilOptions
                                                                        error:&error];
<<<<<<< HEAD
    if (regEx == nil && error != nil) {
=======
    if (regEx == nil || error != nil) {
>>>>>>> Add support for short number and emegerncy number in libPhoneNumber-iOS
      NSLog(@"An error parsing a regular expression: %@", error);
      return nil;
    }

    [self.cache setObject:regEx forKey:pattern];

    return regEx;
  }
}

@end
