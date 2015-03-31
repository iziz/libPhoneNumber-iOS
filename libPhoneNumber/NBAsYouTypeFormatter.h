//
//  NBAsYouTypeFormatter.h
//  libPhoneNumber
//
//  Created by ishtar on 13. 2. 25..
//

#import <Foundation/Foundation.h>


@class NBAsYouTypeFormatter;


@protocol NBAsYouTypeFormatterDelegate <NSObject>
@optional
- (void)formatter:(NBAsYouTypeFormatter *)formatter didFormatted:(BOOL)withResult;
@end


@interface NBAsYouTypeFormatter : NSObject

@property (nonatomic, unsafe_unretained) id <NBAsYouTypeFormatterDelegate> delegate;

- (id)initWithRegionCode:(NSString *)regionCode;
- (id)initWithRegionCodeForTest:(NSString *)regionCode;
- (id)initWithRegionCode:(NSString *)regionCode bundle:(NSBundle *)bundle;
- (id)initWithRegionCodeForTest:(NSString *)regionCode bundle:(NSBundle *)bundle;

- (NSString *)inputString:(NSString *)string;
- (NSString *)inputStringAndRememberPosition:(NSString *)string;

- (NSString *)inputDigit:(NSString*)nextChar;
- (NSString *)inputDigitAndRememberPosition:(NSString*)nextChar;

- (NSString *)removeLastDigit;
- (NSString *)removeLastDigitAndRememberPosition;

- (NSInteger)getRememberedPosition;

- (void)clear;

@end
