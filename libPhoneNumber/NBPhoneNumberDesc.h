//
//  NBPhoneNumberDesc.h
//  libPhoneNumber
//
//  Created by NHN Corp. Last Edited by BAND dev team (band_dev@nhn.com)
//

#import <Foundation/Foundation.h>

@interface NBPhoneNumberDesc : NSObject

// from phonemetadata.pb.js
/* 2 */ @property (nonatomic, strong, readwrite) NSString *nationalNumberPattern;
/* 3 */ @property (nonatomic, strong, readwrite) NSString *possibleNumberPattern;
/* 6 */ @property (nonatomic, strong, readwrite) NSString *exampleNumber;

- (id)initWithData:(id)data;

@end
