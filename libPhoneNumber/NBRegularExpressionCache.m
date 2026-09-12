//
//  NBRegularExpressionCache.m
//  libPhoneNumber
//
//  Created by Paween Itthipalkul on 11/29/17.
//  Copyright © 2017 Google LLC. All rights reserved.
//

#import "NBRegularExpressionCache.h"

#import <os/lock.h>

@interface NBRegularExpressionCache()

@property (nonatomic, strong) NSCache *cache;

@end

@implementation NBRegularExpressionCache {
  os_unfair_lock _cacheLock;
}

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
    _cacheLock = OS_UNFAIR_LOCK_INIT;
    _cache = [[NSCache alloc] init];
  }

  return self;
}

- (NSRegularExpression *)regularExpressionForPattern:(NSString *)pattern error:(NSError **)error {
  // Cache hits, which are the overwhelmingly common case, only hold the lock
  // for the lookup itself. Compilation happens outside the lock so concurrent
  // callers are not serialized behind an unrelated pattern being built. Two
  // threads racing on the same new pattern may each compile it; the duplicate
  // is simply discarded by the insertion below.
  os_unfair_lock_lock(&_cacheLock);
  NSRegularExpression *cachedObject = [self.cache objectForKey:pattern];
  os_unfair_lock_unlock(&_cacheLock);

  if (cachedObject != nil) {
    return cachedObject;
  }

  NSError *regExError = nil;
  NSRegularExpression *regEx = [[NSRegularExpression alloc] initWithPattern:pattern
                                                                    options:kNilOptions
                                                                      error:&regExError];
  if (regEx == nil) {
    if (error != NULL) {
      *error = regExError;
    }
    return nil;
  }

  os_unfair_lock_lock(&_cacheLock);
  NSRegularExpression *raced = [self.cache objectForKey:pattern];
  if (raced != nil) {
    regEx = raced;
  } else {
    [self.cache setObject:regEx forKey:pattern];
  }
  os_unfair_lock_unlock(&_cacheLock);

  return regEx;
}

@end
