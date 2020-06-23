//
//  libPhoneNumberGeocodingTests.m
//  libPhoneNumberGeocodingTests
//
//  Created by Frank Itthipalkul on 6/23/20.
//  Copyright © 2020 Google LLC. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <libPhoneNumberGeocoding/Geocoding.h>
#import <libPhoneNumberiOS/libPhoneNumberiOS.h>

@interface libPhoneNumberGeocodingTests : XCTestCase

@end

@implementation libPhoneNumberGeocodingTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testExample {
  NBPhoneNumber *phoneNumber = [[NBPhoneNumberUtil sharedInstance] parse:@"+14157460260" defaultRegion:@"us" error:nil];

  NBPhoneNumberOfflineGeocoder *geocoder = [[NBPhoneNumberOfflineGeocoder alloc] init];
  NSString *foo = [geocoder descriptionForNumber:phoneNumber];
  NSLog(@"%@", foo);
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
