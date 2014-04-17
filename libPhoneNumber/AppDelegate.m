//
//  AppDelegate.m
//  libPhoneNumber
//
//

#import "AppDelegate.h"
#import "NBPhoneMetaDataGenerator.h"

#import "NBPhoneNumberUtil.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor blackColor];
    [self.window makeKeyAndVisible];
    
    NBPhoneMetaDataGenerator *generator = [[NBPhoneMetaDataGenerator alloc] init];
    [generator generateMetadataClasses];

    /* 
     
    // Unit test for isValidNumber is failing some valid numbers. #7
     
    NBPhoneNumberUtil *phoneUtil = [NBPhoneNumberUtil sharedInstance];
    
    {
        NSError *error = nil;
        NBPhoneNumber *phoneNumberUS = [phoneUtil parse:@"(366) 522-8999" defaultRegion:@"US" error:&error];
        if (error) {
            NSLog(@"err [%@]", [error localizedDescription]);
        }
        NSLog(@"- isValidNumber [%@]", [phoneUtil isValidNumber:phoneNumberUS] ? @"YES" : @"NO");
        NSLog(@"- isPossibleNumber [%@]", [phoneUtil isPossibleNumber:phoneNumberUS error:&error] ? @"YES" : @"NO");
        NSLog(@"- getRegionCodeForNumber [%@]", [phoneUtil getRegionCodeForNumber:phoneNumberUS]);
    }
    
    NSLog(@"- - - - -");
    
    {
        NSError *error = nil;
        NBPhoneNumber *phoneNumberZZ = [phoneUtil parse:@"+84 74 883313" defaultRegion:@"ZZ" error:&error];
        if (error) {
            NSLog(@"err [%@]", [error localizedDescription]);
        }
        NSLog(@"- isValidNumber [%@]", [phoneUtil isValidNumber:phoneNumberZZ] ? @"YES" : @"NO");
        NSLog(@"- isPossibleNumber [%@]", [phoneUtil isPossibleNumber:phoneNumberZZ error:&error] ? @"YES" : @"NO");
        NSLog(@"- getRegionCodeForNumber [%@]", [phoneUtil getRegionCodeForNumber:phoneNumberZZ]);
    }
     
    */
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
