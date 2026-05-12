//
//  NBPhoneNumberToTimeZonesMapper.h
//  libPhoneNumberTimeZones
//

#import <Foundation/Foundation.h>

@class NBPhoneNumber, NBPhoneNumberUtil;

NS_ASSUME_NONNULL_BEGIN

@interface NBPhoneNumberToTimeZonesMapper : NSObject

+ (instancetype)sharedInstance;
+ (NSString *)unknownTimeZone;

- (instancetype)initWithPhoneNumberUtil:(NBPhoneNumberUtil *)phoneNumberUtil
                                 bundle:(NSBundle *)bundle NS_DESIGNATED_INITIALIZER;
- (instancetype)init;

- (NSArray<NSString *> *)timeZonesForNumber:(NBPhoneNumber *)number;
- (NSArray<NSString *> *)timeZonesForGeographicalNumber:(NBPhoneNumber *)number;

@end

NS_ASSUME_NONNULL_END
