//
//  NBPhoneNumberToCarrierMapper.h
//  libPhoneNumberCarrier
//

#import <Foundation/Foundation.h>

@class NBPhoneNumber, NBPhoneNumberUtil;

NS_ASSUME_NONNULL_BEGIN

@interface NBPhoneNumberToCarrierMapper : NSObject

+ (instancetype)sharedInstance;

- (instancetype)initWithPhoneNumberUtil:(NBPhoneNumberUtil *)phoneNumberUtil
                                 bundle:(NSBundle *)bundle NS_DESIGNATED_INITIALIZER;
- (instancetype)init;

- (NSString *)nameForNumber:(NBPhoneNumber *)number localeCode:(NSString *)localeCode;
- (NSString *)nameForValidNumber:(NBPhoneNumber *)number localeCode:(NSString *)localeCode;
- (NSString *)safeDisplayNameForNumber:(NBPhoneNumber *)number localeCode:(NSString *)localeCode;

@end

NS_ASSUME_NONNULL_END
