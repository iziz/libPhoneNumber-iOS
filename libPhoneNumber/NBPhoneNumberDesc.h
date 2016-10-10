//
//  NBPhoneNumberDesc.h
//  libPhoneNumber
//
//

#import <Foundation/Foundation.h>


@interface NBPhoneNumberDesc : NSObject

// from phonemetadata.pb.js
/*  2 */ @property (nonatomic, strong, readwrite) NSString *nationalNumberPattern;
/*  3 */ @property (nonatomic, strong, readwrite) NSString *possibleNumberPattern;
/*  9 */ @property (nonatomic, strong, readwrite) NSArray<NSNumber *> *possibleLength;
/* 10 */ @property (nonatomic, strong, readwrite) NSArray<NSNumber *> *possibleLengthLocalOnly;
/*  6 */ @property (nonatomic, strong, readwrite) NSString *exampleNumber;
/*  7 */ @property (nonatomic, strong, readwrite) NSData *nationalNumberMatcherData;
/*  8 */ @property (nonatomic, strong, readwrite) NSData *possibleNumberMatcherData;

- (id)initWithNationalNumberPattern:(NSString *)nnp withPossibleNumberPattern:(NSString *)pnp
                 withPossibleLength:(NSArray<NSNumber *> *)pl withPossibleLengthLocalOnly:(NSArray<NSNumber *> *)pllo
                        withExample:(NSString *)exp
      withNationalNumberMatcherData:(NSData *)nnmd withPossibleNumberMatcherData:(NSData *)pnmd;

@end
