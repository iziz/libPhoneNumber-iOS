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
+(nullable NSString*)pathInBundles:(NSArray<NSBundle*>*)bundles forFirstResourceNamed:(nonnull NSString*)name ofType:(nullable NSString*)type visitedBundlePaths:(NSMutableSet<NSString*>*)visitedBundlePaths {
    for(NSBundle* b in bundles) {
        NSString *bundlePath = [b.bundlePath stringByResolvingSymlinksInPath];
        if(bundlePath != nil) {
            if([visitedBundlePaths containsObject:bundlePath]) {
                continue;
            }
            [visitedBundlePaths addObject:bundlePath];
        }

        NSString* path = [b pathForResource:name ofType:type];
        if(path != NULL) {
            return path;
        }
        
        path = [NSBundle pathInBundles:[b childBundles]
                  forFirstResourceNamed:name
                                  ofType:type
                      visitedBundlePaths:visitedBundlePaths];
        if(path != NULL) {
            return path;
        }
    }
    
    return NULL;
}

+(nullable NSString*)pathInBundles:(NSArray<NSBundle*>*)bundles forFirstResourceNamed:(nonnull NSString*)name ofType:(nullable NSString*)type {
    return [self pathInBundles:bundles
         forFirstResourceNamed:name
                         ofType:type
             visitedBundlePaths:[NSMutableSet set]];
}

+(NSArray<NSBundle*>*)bundlesInDirectory:(NSString*)directoryPath {
    NSMutableArray<NSBundle*> *bundles = [NSMutableArray array];
    NSArray<NSString*> *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:directoryPath error:nil];

    for(NSString *item in contents) {
        if(![item.pathExtension isEqualToString:@"bundle"]) {
            continue;
        }

        NSString *fullPath = [directoryPath stringByAppendingPathComponent:item];
        NSBundle *bundle = [NSBundle bundleWithPath:fullPath];
        if(bundle != nil) {
            [bundles addObject:bundle];
        }
    }

    return bundles;
}

+(nullable NSString*)pathForFirstResourceNamed:(nonnull NSString*)name ofType:(nullable NSString*)type {
    NSMutableArray<NSBundle*> *bundles = [[NSMutableArray alloc] init];
    [bundles addObjectsFromArray:[NSBundle allBundles]];

    NSString *mainBundleDirectory = [[NSBundle mainBundle].bundlePath stringByDeletingLastPathComponent];
    if(mainBundleDirectory != nil) {
        [bundles addObjectsFromArray:[self bundlesInDirectory:mainBundleDirectory]];
    }

    for(NSBundle *bundle in [NSBundle allBundles]) {
        if(![bundle.bundlePath.pathExtension isEqualToString:@"xctest"]) {
            continue;
        }

        NSString *testBundleDirectory = [bundle.bundlePath stringByDeletingLastPathComponent];
        if(testBundleDirectory != nil) {
            [bundles addObjectsFromArray:[self bundlesInDirectory:testBundleDirectory]];
        }
    }

    return [self pathInBundles:bundles forFirstResourceNamed:name ofType:type];
}

- (nullable NSArray<NSBundle *> *)childBundles {
    NSMutableArray<NSBundle *> *foundBundles = [NSMutableArray array];
    
    // Get the path of the parent bundle
    NSString *parentBundlePath = self.bundlePath;
    
    // Get all files and directories in the bundle's root directory
    NSArray<NSString *> *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:parentBundlePath error:nil];
    
    for (NSString *item in contents) {
        BOOL isDirectory = NO;
        NSString *fullPath = [parentBundlePath stringByAppendingPathComponent:item];

        if ([item.pathExtension isEqualToString:@"bundle"] &&
            [[NSFileManager defaultManager] fileExistsAtPath:fullPath isDirectory:&isDirectory] &&
            isDirectory) {
            NSBundle *bundle = [NSBundle bundleWithPath:fullPath];
            if (bundle != nil) {
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
