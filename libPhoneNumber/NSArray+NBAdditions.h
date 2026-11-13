//
//  NSArray+NBAdditions.h
//  libPhoneNumber
//
//  Created by Dave MacLachlan on 2/7/17.
//  Copyright © 2017 ohtalk.me. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSArray (NBAdditions)
- (id _Nullable)nb_safeObjectAtIndex:(NSUInteger)index class:(Class _Null_unspecified)clazz;
- (NSString * _Nullable)nb_safeStringAtIndex:(NSUInteger)index;
- (NSNumber * _Nullable)nb_safeNumberAtIndex:(NSUInteger)index;
- (NSArray * _Nullable)nb_safeArrayAtIndex:(NSUInteger)index;
- (NSData * _Nullable)nb_safeDataAtIndex:(NSUInteger)index;
@end
