//
//  NBGeocoderMetadataParser.h
//  libPhoneNumber-GeocodingParser
//
//  Created by Rastaar Haghi on 7/1/20.
//  Copyright © 2020 Google LLC. All rights reserved.
//

#import "NBSQLiteDatabaseConnection.h"

NS_ASSUME_NONNULL_BEGIN

@interface NBGeocoderMetadataParser : NSObject

- (instancetype)initWithDestinationPath:(NSURL *)desiredDatabaseLocation;

- (void)convertFileToSQLiteDatabase:(NSString *)metaData
                       withFileName:(NSString *)textFile
                       withLanguage:(NSString *)language;
@end

NS_ASSUME_NONNULL_END
