//
//  NSBundle+Extensions.h
//  libPhoneNumber
//
//  Created by Kris Kline on 11/5/25.
//

#import <Foundation/Foundation.h>

@interface NSBundle (PathForFirst)

/**
 * Searches through all of the bundles and returns the path for the first resource with the specified name and type found
 * - NOTE: This means the behavior is undefined if there are multiple files with the same name located in different bundles of this application
 *
 * - parameter name: The name of the file to look for: <name>.<type>
 * - parameter type: The type of the file to look for: <name>.<type>
 *
 * - returns The path to the found resource, nil if the specified resource couldn't be found in any bundles
 */
+(nullable NSString*)pathForFirstResourceNamed:(nonnull NSString*)name ofType:(nullable NSString*)type;

/**
 * Return an array of child bundles within this bundle. Nil if no child bundles
 *
 * - returns An array of child bundles within this bundle. Nil if no child bundles exist.
 */
-(nullable NSArray<NSBundle*>*)childBundles;

@end
