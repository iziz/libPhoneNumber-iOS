//
//  NBPhoneNumber.m
//  libPhoneNumber
//
//

#import "NBPhoneNumber.h"
#import "NBPhoneNumberDefines.h"


@implementation NBPhoneNumber

- (id)init
{
    self = [super init];
    
    if (self) {
        self.countryCodeSource = nil;
        self.italianLeadingZero = NO;
        self.nationalNumber = @-1;
        self.countryCode = @-1;
        self.numberOfLeadingZeros = @(1);
    }
    
    return self;
}


- (void)clearCountryCodeSource
{
    [self setCountryCodeSource:nil];
}


- (NBECountryCodeSource)getCountryCodeSourceOrDefault
{
    if (!self.countryCodeSource) {
        return NBECountryCodeSourceFROM_NUMBER_WITH_PLUS_SIGN;
    }
    
    return [self.countryCodeSource integerValue];
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
    if (![object isKindOfClass:[NBPhoneNumber class]]) {
        return NO;
    }
    
    NBPhoneNumber *other = object;
    return ([self.countryCode isEqualToNumber:other.countryCode]) && ([self.nationalNumber isEqualToNumber:other.nationalNumber]) &&
        (self.italianLeadingZero == other.italianLeadingZero) && ([self.numberOfLeadingZeros isEqualToNumber:other.numberOfLeadingZeros]) &&
        ((self.extension == nil && other.extension == nil) || [self.extension isEqualToString:other.extension]);
}


- (id)copyWithZone:(NSZone *)zone
{
	NBPhoneNumber *phoneNumberCopy = [[NBPhoneNumber allocWithZone:zone] init];
    
	phoneNumberCopy.countryCode = [self.countryCode copy];
    phoneNumberCopy.nationalNumber = [self.nationalNumber copy];
    phoneNumberCopy.extension = [self.extension copy];
    phoneNumberCopy.italianLeadingZero = self.italianLeadingZero;
    phoneNumberCopy.numberOfLeadingZeros = [self.numberOfLeadingZeros copy];
    phoneNumberCopy.rawInput = [self.rawInput copy];
    phoneNumberCopy.countryCodeSource = [self.countryCodeSource copy];
    phoneNumberCopy.preferredDomesticCarrierCode = [self.preferredDomesticCarrierCode copy];
    
	return phoneNumberCopy;
}


- (id)initWithCoder:(NSCoder*)coder
{
    if (self = [super init]) {
        self.countryCode = [coder decodeObjectForKey:@"countryCode"];
        self.nationalNumber = [coder decodeObjectForKey:@"nationalNumber"];
        self.extension = [coder decodeObjectForKey:@"extension"];
        self.italianLeadingZero = [[coder decodeObjectForKey:@"italianLeadingZero"] boolValue];
        self.numberOfLeadingZeros = [coder decodeObjectForKey:@"numberOfLeadingZeros"];
        self.rawInput = [coder decodeObjectForKey:@"rawInput"];
        self.countryCodeSource = [coder decodeObjectForKey:@"countryCodeSource"];
        self.preferredDomesticCarrierCode = [coder decodeObjectForKey:@"preferredDomesticCarrierCode"];
    }
    return self;
}


- (void)encodeWithCoder:(NSCoder*)coder
{
    [coder encodeObject:self.countryCode forKey:@"countryCode"];
    [coder encodeObject:self.nationalNumber forKey:@"nationalNumber"];
    [coder encodeObject:self.extension forKey:@"extension"];
    [coder encodeObject:[NSNumber numberWithBool:self.italianLeadingZero] forKey:@"italianLeadingZero"];
    [coder encodeObject:self.numberOfLeadingZeros forKey:@"numberOfLeadingZeros"];
    [coder encodeObject:self.rawInput forKey:@"rawInput"];
    [coder encodeObject:self.countryCodeSource forKey:@"countryCodeSource"];
    [coder encodeObject:self.preferredDomesticCarrierCode forKey:@"preferredDomesticCarrierCode"];
}



- (NSString *)description
{
    return [NSString stringWithFormat:@" - countryCode[%@], nationalNumber[%@], extension[%@], italianLeadingZero[%@], numberOfLeadingZeros[%@], rawInput[%@] countryCodeSource[%@] preferredDomesticCarrierCode[%@]", self.countryCode, self.nationalNumber, self.extension, self.italianLeadingZero?@"Y":@"N", self.numberOfLeadingZeros, self.rawInput, self.countryCodeSource, self.preferredDomesticCarrierCode];
}

@end
