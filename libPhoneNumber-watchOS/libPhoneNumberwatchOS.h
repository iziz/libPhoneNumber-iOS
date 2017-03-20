//
//  libPhoneNumber-watchOS.h
//  libPhoneNumber-watchOS
//
//  Created by Jeff Kelley on 11/16/16.
//  Copyright © 2016 ohtalk.me. All rights reserved.
//

#import <WatchKit/WatchKit.h>

//! Project version number for libPhoneNumber-watchOS.
FOUNDATION_EXPORT double libPhoneNumber_watchOSVersionNumber;

//! Project version string for libPhoneNumber-watchOS.
FOUNDATION_EXPORT const unsigned char libPhoneNumber_watchOSVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <libPhoneNumber_watchOS/PublicHeader.h>


#import "NBPhoneNumberDefines.h"

// Features
#import "NBPhoneNumberUtil.h"
#import "NBAsYouTypeFormatter.h"

// Metadata
#import "NBMetadataCore.h"
#import "NBMetadataCoreMapper.h"
#import "NBMetadataHelper.h"

// Model
#import "NBPhoneMetaData.h"
#import "NBNumberFormat.h"
#import "NBPhoneNumber.h"
#import "NBPhoneNumberDesc.h"
