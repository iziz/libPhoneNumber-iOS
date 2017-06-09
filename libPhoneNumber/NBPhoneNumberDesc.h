//
//  NBPhoneNumberDesc.h
//  libPhoneNumber
//
//

#import <Foundation/Foundation.h>


@interface NBPhoneNumberDesc : NSObject

// from phonemetadata.pb.js
/*  2 */ @property (nonatomic, strong, readonly) NSString *nationalNumberPattern;
/*  3 */ @property (nonatomic, strong, readonly) NSString *possibleNumberPattern;
/*  9 */ @property (nonatomic, strong, readonly) NSArray<NSNumber *> *possibleLength;
/* 10 */ @property (nonatomic, strong, readonly) NSArray<NSNumber *> *possibleLengthLocalOnly;
/*  6 */ @property (nonatomic, strong, readonly) NSString *exampleNumber;
/*  7 */ @property (nonatomic, strong, readonly) NSData *nationalNumberMatcherData;
/*  8 */ @property (nonatomic, strong, readonly) NSData *possibleNumberMatcherData;

- (id)initWithNationalNumberPattern:(NSString *)nnp
          withPossibleNumberPattern:(NSString *)pnp
                 withPossibleLength:(NSArray<NSNumber *> *)pl
        withPossibleLengthLocalOnly:(NSArray<NSNumber *> *)pllo
                        withExample:(NSString *)exp
      withNationalNumberMatcherData:(NSData *)nnmd
      withPossibleNumberMatcherData:(NSData *)pnmd;

- (id)initWithEntry:(NSArray *)entry;
@end
