//
//  NSBundle+Extensions.m
//  libPhoneNumber
//
//  Created by Kris Kline on 11/5/25.
//

#import "NSBundle+Extensions.h"

@implementation NSBundle(PathForFirst)

/**
 * Recursive method for searching through all the bundles in the array for the specified file, but also seach all child bundles of each bundle in the array, until the file is found
 *
 * - parameter name: The name of the file to look for: <name>.<type>
 * - parameter type: The type of the file to look for: <name>.<type>
 *
 * - returns The path to the found resource. Nil if the specified resource couldn't be found in any bundles
 */
+(nullable NSString*)pathInBundles:(NSArray<NSBundle*>*)bundles forFirstResourceNamed:(nonnull NSString*)name ofType:(nullable NSString*)type {
    for(NSBundle* b in bundles) {
        NSString* path = [b pathForResource:name ofType:type];
        if(path != NULL) {
            return path;
        }
        
        path = [NSBundle pathInBundles:[b childBundles] forFirstResourceNamed:name ofType:type];
        if(path != NULL) {
            return path;
        }
    }
    
    return NULL;
}

+(nullable NSString*)pathForFirstResourceNamed:(nonnull NSString*)name ofType:(nullable NSString*)type {
    return [self pathInBundles:[NSBundle allBundles] forFirstResourceNamed:name ofType:type];
}

- (nullable NSArray<NSBundle *> *)childBundles {
    NSMutableArray<NSBundle *> *foundBundles = [NSMutableArray array];
    
    // Get the path of the parent bundle
    NSString *parentBundlePath = self.bundlePath;
    
    // Get all files and directories in the bundle's root directory
    NSArray<NSString *> *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:parentBundlePath error:nil];
    
    for (NSString *item in contents) {
        // Check if the item has a .bundle extension
        if ([item.pathExtension isEqualToString:@"bundle"]) {
            NSString *bundlePath = [parentBundlePath stringByAppendingPathComponent:item];
            NSBundle *bundle = [NSBundle bundleWithPath:bundlePath];
            if (bundle) {
                [foundBundles addObject:bundle];
            }
        }
    }
    
    if(foundBundles.count>0) {
        return foundBundles;
    }
    
    return NULL;
}

@end
