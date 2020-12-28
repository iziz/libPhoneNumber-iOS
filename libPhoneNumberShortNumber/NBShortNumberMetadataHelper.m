//
//  NBShortNumberMetadataHelper.m
//  libPhoneNumberShortNumber
//
//  Created by Rastaar Haghi on 7/15/20.
//  Copyright © 2020 Google. All rights reserved.
//

#import "NBShortNumberMetadataHelper.h"
#import "NBGeneratedShortNumberMetadata.h"
#import "NBMetadataHelper.h"
#import "NBPhoneMetaData.h"

static NSString *StringByTrimming(NSString *aString) {
  static dispatch_once_t onceToken;
  static NSCharacterSet *whitespaceCharSet = nil;
  dispatch_once(&onceToken, ^{
    NSMutableCharacterSet *spaceCharSet =
        [NSMutableCharacterSet characterSetWithCharactersInString:NB_NON_BREAKING_SPACE];
    [spaceCharSet formUnionWithCharacterSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    whitespaceCharSet = spaceCharSet;
  });
  return [aString stringByTrimmingCharactersInSet:whitespaceCharSet];
}

@implementation NBShortNumberMetadataHelper {
  NSCache<NSString *, NBPhoneMetaData *> *_shortNumberMetadataCache;
  NBMetadataHelper *_helper;
  NSDictionary *_shortNumberDataMap;
}

- (instancetype)init {
  return [self initWithZippedDataBytes:kShortNumberMetaData
                      compressedLength:kShortNumberMetaDataCompressedLength
                        expandedLength:kShortNumberMetaDataExpandedLength
                        metadataHelper:[[NBMetadataHelper alloc] init]];
}

- (instancetype)initWithZippedData:(NSData *)data
                    expandedLength:(NSUInteger)expandedLength
                    metadataHelper:(NBMetadataHelper *)helper {
  return [self initWithZippedDataBytes:(z_const Bytef *)data.bytes
                      compressedLength:data.length
                        expandedLength:expandedLength
                        metadataHelper:helper];
}

- (instancetype)initWithZippedDataBytes:(z_const Bytef *)data
                       compressedLength:(NSUInteger)compressedLength
                         expandedLength:(NSUInteger)expandedLength
                         metadataHelper:(NBMetadataHelper *)helper {
  self = [super init];

  if (self != nil) {
    _helper = [[NBMetadataHelper alloc] init];
    _shortNumberMetadataCache = [[NSCache alloc] init];
    _shortNumberDataMap =
        [NBShortNumberMetadataHelper jsonObjectFromZippedDataWithBytes:data
                                                      compressedLength:compressedLength
                                                        expandedLength:expandedLength];
  }

  return self;
}

- (NBPhoneMetaData *)shortNumberMetadataForRegion:(NSString *)regionCode {
  regionCode = StringByTrimming(regionCode);
  if (regionCode.length == 0) {
    return nil;
  }
  regionCode = [regionCode uppercaseString];

  NBPhoneMetaData *cachedMetadata = [_shortNumberMetadataCache objectForKey:regionCode];
  if (cachedMetadata != nil) {
    return cachedMetadata;
  }

  NSDictionary *dict = _shortNumberDataMap[@"countryToMetadata"];
  NSArray *entry = dict[regionCode];
  if (entry) {
    NBPhoneMetaData *metadata = [[NBPhoneMetaData alloc] initWithEntry:entry];
    [_shortNumberMetadataCache setObject:metadata forKey:regionCode];
    return metadata;
  }

  return nil;
}

/**
 * Expand gzipped data into a JSON object.

 * @param bytes Array<Bytef> of zipped data.
 * @param compressedLength Length of the compressed bytes.
 * @param expandedLength Length of the expanded bytes.
 * @return JSON dictionary.
 */
+ (NSDictionary *)jsonObjectFromZippedDataWithBytes:(z_const Bytef[])bytes
                                   compressedLength:(NSUInteger)compressedLength
                                     expandedLength:(NSUInteger)expandedLength {
  // Data is a gzipped JSON file that is embedded in the binary.
  // See GeneratePhoneNumberHeader.sh and PhoneNumberMetaData.h for details.
  NSMutableData *gunzippedData = [NSMutableData dataWithLength:expandedLength];

  z_stream zStream;
  memset(&zStream, 0, sizeof(zStream));
  __attribute((unused)) int err = inflateInit2(&zStream, 16);
  NSAssert(err == Z_OK, @"Unable to init stream. err = %d", err);

  zStream.next_in = bytes;
  zStream.avail_in = (uint)compressedLength;
  zStream.next_out = (Bytef *)gunzippedData.bytes;
  zStream.avail_out = (uint)gunzippedData.length;

  err = inflate(&zStream, Z_FINISH);
  NSAssert(err == Z_STREAM_END, @"Unable to inflate compressed data. err = %d", err);

  err = inflateEnd(&zStream);
  NSAssert(err == Z_OK, @"Unable to inflate compressed data. err = %d", err);

  NSError *error = nil;
  NSDictionary *jsonObject = [NSJSONSerialization JSONObjectWithData:gunzippedData
                                                             options:0
                                                               error:&error];
  NSAssert(error == nil, @"Unable to convert JSON - %@", error);

  return jsonObject;
}

@end
