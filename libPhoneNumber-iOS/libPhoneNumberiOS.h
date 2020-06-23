//
//  libPhoneNumber-iOS.h
//  libPhoneNumber-iOS
//
//  Created by Roy Marmelstein on 04/08/2015.
//  Copyright (c) 2015 ohtalk.me. All rights reserved.
//

#import <UIKit/UIKit.h>

//! Project version number for libPhoneNumber-iOS.
FOUNDATION_EXPORT double libPhoneNumber_iOSVersionNumber;

//! Project version string for libPhoneNumber-iOS.
FOUNDATION_EXPORT const unsigned char libPhoneNumber_iOSVersionString[];

// In this header, you should import all the public headers of your framework
// using statements like #import <libPhoneNumber_iOS/PublicHeader.h>

#import "NBPhoneNumberDefines.h"

// Features
#import "NBAsYouTypeFormatter.h"
#import "NBPhoneNumberUtil.h"

// Metadata
#import "NBMetadataHelper.h"

// Model
#import "NBNumberFormat.h"
#import "NBPhoneMetaData.h"
#import "NBPhoneNumber.h"
#import "NBPhoneNumberDesc.h"
