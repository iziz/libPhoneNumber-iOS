//
//  NBPhoneNumberDesc.m
//  libPhoneNumber
//
//

#import "NBPhoneNumberDesc.h"
#import "NSArray+NBAdditions.h"

@implementation NBPhoneNumberDesc

- (id)initWithEntry:(NSArray *)entry
{
    self = [super init];
    if (self && entry != nil) {
        _nationalNumberPattern = [entry nb_safeStringAtIndex:2];
        _possibleNumberPattern = [entry nb_safeStringAtIndex:3];
        _possibleLength = [entry nb_safeArrayAtIndex:9];
        _possibleLengthLocalOnly = [entry nb_safeArrayAtIndex:10];
        _exampleNumber = [entry nb_safeStringAtIndex:6];
        _nationalNumberMatcherData = [entry nb_safeDataAtIndex:7];
        _possibleNumberMatcherData = [entry nb_safeDataAtIndex:8];
    }
    return self;
}


- (id)initWithNationalNumberPattern:(NSString *)nnp withPossibleNumberPattern:(NSString *)pnp
                 withPossibleLength:(NSArray<NSNumber *> *)pl withPossibleLengthLocalOnly:(NSArray<NSNumber *> *)pllo withExample:(NSString *)exp
      withNationalNumberMatcherData:(NSData *)nnmd withPossibleNumberMatcherData:(NSData *)pnmd {
    self = [super init];

    if (self) {
        _nationalNumberPattern = nnp;
        _possibleNumberPattern = pnp;
        _possibleLength = pl;
        _possibleLengthLocalOnly = pllo;
        _exampleNumber = exp;
        _nationalNumberMatcherData = nnmd;
        _possibleNumberMatcherData = pnmd;
    }

    return self;

}

- (id)initWithCoder:(NSCoder*)coder
{
    if (self = [super init]) {
        _nationalNumberPattern = [coder decodeObjectForKey:@"nationalNumberPattern"];
        _possibleNumberPattern = [coder decodeObjectForKey:@"possibleNumberPattern"];
        _possibleLength = [coder decodeObjectForKey:@"possibleLength"];
        _possibleLengthLocalOnly = [coder decodeObjectForKey:@"possibleLengthLocalOnly"];
        _exampleNumber = [coder decodeObjectForKey:@"exampleNumber"];
        _nationalNumberMatcherData = [coder decodeObjectForKey:@"nationalNumberMatcherData"];
        _possibleNumberMatcherData = [coder decodeObjectForKey:@"possibleNumberMatcherData"];
    }
    return self;
}


- (void)encodeWithCoder:(NSCoder*)coder
{
    [coder encodeObject:self.nationalNumberPattern forKey:@"nationalNumberPattern"];
    [coder encodeObject:self.possibleNumberPattern forKey:@"possibleNumberPattern"];
    [coder encodeObject:self.possibleLength forKey:@"possibleLength"];
    [coder encodeObject:self.possibleLengthLocalOnly forKey:@"possibleLengthLocalOnly"];
    [coder encodeObject:self.exampleNumber forKey:@"exampleNumber"];
    [coder encodeObject:self.nationalNumberMatcherData forKey:@"nationalNumberMatcherData"];
    [coder encodeObject:self.possibleNumberMatcherData forKey:@"possibleNumberMatcherData"];
}


- (NSString *)description
{
    return [NSString stringWithFormat:@"nationalNumberPattern[%@] possibleNumberPattern[%@] possibleLength[%@] possibleLengthLocalOnly[%@] exampleNumber[%@]",
            self.nationalNumberPattern, self.possibleNumberPattern, self.possibleLength, self.possibleLengthLocalOnly, self.exampleNumber];
}


- (id)copyWithZone:(NSZone *)zone
{
	return [[NBPhoneNumberDesc allocWithZone:zone] initWithNationalNumberPattern:self.nationalNumberPattern
                                                     withPossibleNumberPattern:self.possibleNumberPattern
                                                            withPossibleLength:self.possibleLength
                                                   withPossibleLengthLocalOnly:self.possibleLengthLocalOnly
                                                                   withExample:self.exampleNumber
                                                 withNationalNumberMatcherData:self.nationalNumberMatcherData
                                                 withPossibleNumberMatcherData:self.possibleNumberMatcherData];
}


- (BOOL)isEqual:(id)object
{
    if ([object isKindOfClass:[NBPhoneNumberDesc class]] == NO) {
        return NO;
    }

    NBPhoneNumberDesc *other = object;
    return [self.nationalNumberPattern isEqual:other.nationalNumberPattern] &&
        [self.possibleNumberPattern isEqual:other.possibleNumberPattern] &&
        [self.possibleLength isEqual:other.possibleLength] &&
        [self.possibleLengthLocalOnly isEqual:other.possibleLengthLocalOnly] &&
        [self.exampleNumber isEqual:other.exampleNumber] &&
        [self.nationalNumberMatcherData isEqualToData:other.nationalNumberMatcherData] &&
        [self.possibleNumberMatcherData isEqualToData:other.possibleNumberMatcherData];
}

@end
