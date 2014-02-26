//
//  NBPhoneNumber.m
//  libPhoneNumber
//
//  Created by NHN Corp. Last Edited by BAND dev team (band_dev@nhn.com)
//

#import "NBPhoneNumber.h"
#import "NBPhoneNumberDefines.h"

@implementation NBPhoneNumber

@synthesize countryCode, nationalNumber, extension, italianLeadingZero, rawInput, countryCodeSource, preferredDomesticCarrierCode;

- (id)init
{
    self = [super init];
    
    if (self)
    {
        self.countryCodeSource = nil;
        self.italianLeadingZero = NO;
        self.nationalNumber = -1;
        self.countryCode = -1;
    }
    
    return self;
}


- (void)clearCountryCodeSource
{
    [self setCountryCodeSource:nil];
}


- (NBECountryCodeSource)getCountryCodeSourceOrDefault
{
    if (self.countryCodeSource == nil)
        return NBECountryCodeSourceFROM_NUMBER_WITH_PLUS_SIGN;
    
    return [self.countryCodeSource intValue];
}


- (BOOL)isEqualToObject:(NBPhoneNumber*)otherObj
{
    return [self isEqual:otherObj];
}


- (NSUInteger)hash
{
    NSData *selfObject = [NSKeyedArchiver archivedDataWithRootObject:self];
    return [selfObject hash];
}


- (BOOL)isEqual:(id)object
{
    if ([object isKindOfClass:[NBPhoneNumber class]] == NO)
        return NO;
    
    NBPhoneNumber *other = object;
    return (self.countryCode == other.countryCode) && (self.nationalNumber == other.nationalNumber) &&
        (self.italianLeadingZero == other.italianLeadingZero) &&
        ((self.extension == nil && other.extension == nil) || [self.extension isEqualToString:other.extension]);
}


- (id)copyWithZone:(NSZone *)zone
{
	NBPhoneNumber *phoneNumberCopy = [[NBPhoneNumber allocWithZone:zone] init];
    
	phoneNumberCopy.countryCode = self.countryCode;
    phoneNumberCopy.nationalNumber = self.nationalNumber;
    phoneNumberCopy.extension = [self.extension copy];
    phoneNumberCopy.italianLeadingZero = self.italianLeadingZero;
    phoneNumberCopy.rawInput = [self.rawInput copy];
    phoneNumberCopy.countryCodeSource = [self.countryCodeSource copy];
    phoneNumberCopy.preferredDomesticCarrierCode = [self.preferredDomesticCarrierCode copy];
    
	return phoneNumberCopy;
}


- (id)initWithCoder:(NSCoder*)coder
{
    if (self = [super init])
    {
        self.countryCode = [[coder decodeObjectForKey:@"countryCode"] longValue];
        self.nationalNumber = [[coder decodeObjectForKey:@"nationalNumber"] longLongValue];
        self.extension = [coder decodeObjectForKey:@"extension"];
        self.italianLeadingZero = [[coder decodeObjectForKey:@"italianLeadingZero"] boolValue];
        self.rawInput = [coder decodeObjectForKey:@"rawInput"];
        self.countryCodeSource = [coder decodeObjectForKey:@"countryCodeSource"];
        self.preferredDomesticCarrierCode = [coder decodeObjectForKey:@"preferredDomesticCarrierCode"];
    }
    return self;
}


- (void)encodeWithCoder:(NSCoder*)coder
{
    [coder encodeObject:[NSNumber numberWithLong:self.countryCode] forKey:@"countryCode"];
    [coder encodeObject:[NSNumber numberWithLongLong:self.nationalNumber] forKey:@"nationalNumber"];
    [coder encodeObject:self.extension forKey:@"extension"];
    [coder encodeObject:[NSNumber numberWithBool:self.italianLeadingZero] forKey:@"italianLeadingZero"];
    [coder encodeObject:self.rawInput forKey:@"rawInput"];
    [coder encodeObject:self.countryCodeSource forKey:@"countryCodeSource"];
    [coder encodeObject:self.preferredDomesticCarrierCode forKey:@"preferredDomesticCarrierCode"];
}



- (NSString *)description
{
    return [NSString stringWithFormat:@" - countryCode[%u], nationalNumber[%llu], extension[%@], italianLeadingZero[%@], rawInput[%@] countryCodeSource[%d] preferredDomesticCarrierCode[%@]", (unsigned int)self.countryCode, self.nationalNumber, self.extension, self.italianLeadingZero?@"Y":@"N", self.rawInput, [self.countryCodeSource intValue], self.preferredDomesticCarrierCode];
}

@end
