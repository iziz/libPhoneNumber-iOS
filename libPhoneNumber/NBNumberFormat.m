//
//  NBPhoneNumberFormat.m
//  libPhoneNumber
//
//

#import "NBNumberFormat.h"
#import "NSArray+NBAdditions.h"

@implementation NBNumberFormat


- (id)initWithPattern:(NSString *)pattern withFormat:(NSString *)format withLeadingDigitsPatterns:(NSArray *)leadingDigitsPatterns withNationalPrefixFormattingRule:(NSString *)nationalPrefixFormattingRule whenFormatting:(BOOL)nationalPrefixOptionalWhenFormatting withDomesticCarrierCodeFormattingRule:(NSString *)domesticCarrierCodeFormattingRule
{
    self = [super init];
    if (self) {
				_pattern = pattern;
				_format = format;
				_leadingDigitsPatterns = leadingDigitsPatterns;
				_nationalPrefixFormattingRule = nationalPrefixFormattingRule;
				_nationalPrefixOptionalWhenFormatting = nationalPrefixOptionalWhenFormatting;
				_domesticCarrierCodeFormattingRule = domesticCarrierCodeFormattingRule;
    }
    return self;
}

- (id)initWithEntry:(NSArray *)entry
{
    self = [super init];
    if (self && entry != nil) {
        _pattern = [entry nb_safeStringAtIndex:1];
        _format = [entry nb_safeStringAtIndex:2];
        _leadingDigitsPatterns = [entry nb_safeArrayAtIndex:3];
        _nationalPrefixFormattingRule = [entry nb_safeStringAtIndex:4];
        _nationalPrefixOptionalWhenFormatting = [[entry nb_safeNumberAtIndex:6] boolValue];
        _domesticCarrierCodeFormattingRule = [entry nb_safeStringAtIndex:5];
    }
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"[pattern:%@, format:%@, leadingDigitsPattern:%@, nationalPrefixFormattingRule:%@, nationalPrefixOptionalWhenFormatting:%@, domesticCarrierCodeFormattingRule:%@]",
            self.pattern, self.format, self.leadingDigitsPatterns, self.nationalPrefixFormattingRule, self.nationalPrefixOptionalWhenFormatting?@"Y":@"N", self.domesticCarrierCodeFormattingRule];
}


- (id)copyWithZone:(NSZone *)zone
{
    return [[NBNumberFormat alloc] initWithPattern:self.pattern
                                        withFormat:self.format
                         withLeadingDigitsPatterns:self.leadingDigitsPatterns
                  withNationalPrefixFormattingRule:self.nationalPrefixFormattingRule
                                    whenFormatting:self.nationalPrefixOptionalWhenFormatting
             withDomesticCarrierCodeFormattingRule:self.domesticCarrierCodeFormattingRule];
}


- (id)initWithCoder:(NSCoder*)coder
{
    if (self = [super init]) {
        _pattern = [coder decodeObjectForKey:@"pattern"];
        _format = [coder decodeObjectForKey:@"format"];
        _leadingDigitsPatterns = [coder decodeObjectForKey:@"leadingDigitsPatterns"];
        _nationalPrefixFormattingRule = [coder decodeObjectForKey:@"nationalPrefixFormattingRule"];
        _nationalPrefixOptionalWhenFormatting = [[coder decodeObjectForKey:@"nationalPrefixOptionalWhenFormatting"] boolValue];
        _domesticCarrierCodeFormattingRule = [coder decodeObjectForKey:@"domesticCarrierCodeFormattingRule"];
    }
    return self;
}


- (void)encodeWithCoder:(NSCoder*)coder
{
    [coder encodeObject:self.pattern forKey:@"pattern"];
    [coder encodeObject:self.format forKey:@"format"];
    [coder encodeObject:self.leadingDigitsPatterns forKey:@"leadingDigitsPatterns"];
    [coder encodeObject:self.nationalPrefixFormattingRule forKey:@"nationalPrefixFormattingRule"];
    [coder encodeObject:[NSNumber numberWithBool:self.nationalPrefixOptionalWhenFormatting] forKey:@"nationalPrefixOptionalWhenFormatting"];
    [coder encodeObject:self.domesticCarrierCodeFormattingRule forKey:@"domesticCarrierCodeFormattingRule"];
}


@end
