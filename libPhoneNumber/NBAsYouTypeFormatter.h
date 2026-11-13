//
//  NBAsYouTypeFormatter.h
//  libPhoneNumber
//
//  Created by ishtar on 13. 2. 25..
//

#import <Foundation/Foundation.h>

@class NBAsYouTypeFormatter;
@class NBMetadataHelper;

@interface NBAsYouTypeFormatter : NSObject

- (instancetype _Nonnull)initWithRegionCode:(NSString * _Nullable)regionCode;
- (instancetype _Nonnull)initWithRegionCode:(NSString * _Nullable)regionCode metadataHelper:(NBMetadataHelper * _Nonnull)helper;

- (NSString * _Nonnull)inputString:(NSString * _Nullable)string;
- (NSString * _Nonnull)inputStringAndRememberPosition:(NSString * _Nullable)string;

- (NSString * _Nonnull)inputDigit:(NSString * _Nullable)nextChar;
- (NSString * _Nonnull)inputDigitAndRememberPosition:(NSString * _Nullable)nextChar;

- (NSString * _Nonnull)removeLastDigit;
- (NSString * _Nonnull)removeLastDigitAndRememberPosition;

- (NSInteger)getRememberedPosition;

- (void)clear;

@property(nonatomic, assign, readonly) BOOL isSuccessfulFormatting;

@end
