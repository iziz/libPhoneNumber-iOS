//
//  NBPhoneNumberDesc.m
//  libPhoneNumber
//
//

#import "NBPhoneNumberDesc.h"

@interface NSArray (NBAdditions)
- (id)safeObjectAtIndex:(NSUInteger)index;
@end

@implementation NSArray (NBAdditions)
- (id)safeObjectAtIndex:(NSUInteger)index {
    @synchronized(self) {
        if (index >= [self count]) return nil;
        id res = [self objectAtIndex:index];
        if (res == nil || (NSNull*)res == [NSNull null]) {
            return nil;
        }
        return res;
    }
}
@end


@implementation NBPhoneNumberDesc

- (id)initWithData:(id)data
{
    NSString *nnp = nil;
    NSString *pnp = nil;
    NSArray<NSNumber *> *pl = nil;
    NSArray<NSNumber *> *pllo = nil;
    NSString *exp = nil;
    NSData *nnmd = nil;
    NSData *pnmd = nil;
    
    if (data != nil && [data isKindOfClass:[NSArray class]]) {
        /*  2 */ nnp = [data safeObjectAtIndex:2];
        /*  3 */ pnp = [data safeObjectAtIndex:3];

        /*  9 */ pl = [data safeObjectAtIndex:9];
        /* 10 */ pllo = [data safeObjectAtIndex:10];
        /*  6 */ exp = [data safeObjectAtIndex:6];
        /*  7 */ nnmd = [data safeObjectAtIndex:7];
        /*  8 */ pnmd = [data safeObjectAtIndex:8];
    }
    
    return [self initWithNationalNumberPattern:nnp withPossibleNumberPattern:pnp
                            withPossibleLength:pl withPossibleLengthLocalOnly:pllo withExample:exp
                 withNationalNumberMatcherData:nnmd withPossibleNumberMatcherData:pnmd];
}


- (id)initWithNationalNumberPattern:(NSString *)nnp withPossibleNumberPattern:(NSString *)pnp
                 withPossibleLength:(NSArray<NSNumber *> *)pl withPossibleLengthLocalOnly:(NSArray<NSNumber *> *)pllo withExample:(NSString *)exp
      withNationalNumberMatcherData:(NSData *)nnmd withPossibleNumberMatcherData:(NSData *)pnmd {
    self = [self init];
    
    if (self) {
        self.nationalNumberPattern = nnp;
        self.possibleNumberPattern = pnp;
        self.possibleLength = pl;
        self.possibleLengthLocalOnly = pllo;
        self.exampleNumber = exp;
        self.nationalNumberMatcherData = nnmd;
        self.possibleNumberMatcherData = pnmd;
    }
    
    return self;

}


- (id)init
{
    self = [super init];
    
    if (self) {
    }
    
    return self;
}


- (id)initWithCoder:(NSCoder*)coder
{
    if (self = [super init]) {
        self.nationalNumberPattern = [coder decodeObjectForKey:@"nationalNumberPattern"];
        self.possibleNumberPattern = [coder decodeObjectForKey:@"possibleNumberPattern"];
        self.possibleLength = [coder decodeObjectForKey:@"possibleLength"];
        self.possibleLengthLocalOnly = [coder decodeObjectForKey:@"possibleLengthLocalOnly"];
        self.exampleNumber = [coder decodeObjectForKey:@"exampleNumber"];
        self.nationalNumberMatcherData = [coder decodeObjectForKey:@"nationalNumberMatcherData"];
        self.possibleNumberMatcherData = [coder decodeObjectForKey:@"possibleNumberMatcherData"];
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
	NBPhoneNumberDesc *phoneDescCopy = [[NBPhoneNumberDesc allocWithZone:zone] init];
    
    phoneDescCopy.nationalNumberPattern = [self.nationalNumberPattern copy];
    phoneDescCopy.possibleNumberPattern = [self.possibleNumberPattern copy];
    phoneDescCopy.possibleLength = [self.possibleLength copy];
    phoneDescCopy.possibleLengthLocalOnly = [self.possibleLengthLocalOnly copy];
    phoneDescCopy.exampleNumber = [self.exampleNumber copy];
    phoneDescCopy.nationalNumberMatcherData = [self.nationalNumberMatcherData copy];
    phoneDescCopy.possibleNumberMatcherData = [self.possibleNumberMatcherData copy];
    
	return phoneDescCopy;
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
