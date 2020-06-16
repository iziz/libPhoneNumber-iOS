//
//  NBPhoneNumberOfflineGeocoder.m
//  libPhoneNumberiOS
//
//  Created by Rastaar Haghi on 6/12/20.
//  Copyright © 2020 ohtalk.me. All rights reserved.
//

#import "NBPhoneNumberOfflineGeocoder.h"

@implementation NBPhoneNumberOfflineGeocoder

-(instancetype) init {
    self = [super init];
    // gather all available language database files
    NSBundle *bundle = [NSBundle bundleForClass: self.classForCoder];
    NSURL *bundleURL = [[bundle resourceURL] URLByAppendingPathComponent:@"Resources.bundle"];
    NSArray *filesInResourceBundle = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:bundleURL includingPropertiesForKeys:NULL options:0 error:NULL];
    self.supportedLanguages = [[NSMutableArray alloc] init];
    [filesInResourceBundle enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSString *filename = (NSString *)obj;
        if(filename != NULL) {
            [self.supportedLanguages addObject: [[filename lastPathComponent] stringByDeletingPathExtension]];
        }
    }];
//    NSLog(@"The supported languages are: %@", self.supportedLanguages);
    
    // need to get from ios device settings
    if ([[NSLocale preferredLanguages] count] > 0) {
        // set language to preferred
        self.language = [NSLocale preferredLanguages][0];
        // if the preferred language isn't supported by metadata, set by default to english
        if(![self.supportedLanguages containsObject:self.language]) {
            self.language = @"en";
            NSLog(@"Set default language to ENGLISH");
        }
    }
    
//    NSLog(@"Preferred language: %@", self.language);
    self.geocoderHelper = [[NBGeocoderMetadataHelper alloc] initWithCountryCode:@1 withLanguage: self.language];
    return self;
}
-(NSString*) getCountryNameForNumber: (NBPhoneNumber*) number withLanguage: (NSString*) language {
    return @"";
}
-(NSString*) getDescriptionForNumber: (NBPhoneNumber*) number {
    NSString* descriptionResult = [self.geocoderHelper searchPhoneNumberInDatabase:number withLanguage: self.language];
    if(descriptionResult == NULL) {
        return @"unknown";
    } else {
        return descriptionResult;
    }
}

@end
