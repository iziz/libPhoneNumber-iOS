//
//  NBMetadataHelper.m
//  libPhoneNumber
//
//  Created by tabby on 2015. 2. 8..
//  Copyright (c) 2015년 ohtalk.me. All rights reserved.
//

#import "NBMetadataHelper.h"
#import "NBGeneratedPhoneNumberMetaData.h"
#import "NBPhoneMetaData.h"

@interface NBMetadataHelper ()

// Cached metadata
@property(nonatomic, strong) NSCache<NSString *, NBPhoneMetaData *> *metadataCache;
@property(nonatomic, strong) NSCache<NSString *, id> *metadataMapCache;

@end

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

@implementation NBMetadataHelper {
 @private
  NSDictionary *_phoneNumberDataDictionary;
  NSDictionary *_countryCodeToCountryNumberDictionary;
}

- (instancetype)init {
  return [self initWithZippedDataBytes:kPhoneNumberMetaData
                      compressedLength:kPhoneNumberMetaDataCompressedLength
                        expandedLength:kPhoneNumberMetaDataExpandedLength];
}

- (instancetype)initWithZippedData:(NSData *)data expandedLength:(NSUInteger)expandedLength {
  return [self initWithZippedDataBytes:(z_const Bytef *)data.bytes
                      compressedLength:data.length
                        expandedLength:expandedLength];
}

- (instancetype)initWithZippedDataBytes:(z_const Bytef *)data
                       compressedLength:(NSUInteger)compressedLength
                         expandedLength:(NSUInteger)expandedLength {
  self = [super init];

  if (self != nil) {
    _metadataCache = [[NSCache alloc] init];
    _metadataMapCache = [[NSCache alloc] init];
    _phoneNumberDataDictionary =
        [NBMetadataHelper jsonObjectFromZippedDataWithBytes:data
                                           compressedLength:compressedLength
                                             expandedLength:expandedLength];
  }

  return self;
}

/*
 Terminologies
 - Country Number (CN)  = Country code for i18n calling
 - Country Code   (CC) : ISO country codes (2 chars)
 Ref. site (countrycode.org)
 */

- (NSDictionary *)countryCodeToCountryNumberDictionary {
  if (_countryCodeToCountryNumberDictionary == nil) {
    NSDictionary *countryCodeToRegionCodeMap = [self countryCodeToRegionCodeDictionary];
    NSMutableDictionary *map = [[NSMutableDictionary alloc] init];
    for (NSString *countryCode in countryCodeToRegionCodeMap) {
      NSArray *regionCodes = countryCodeToRegionCodeMap[countryCode];
      for (NSString *regionCode in regionCodes) {
        map[regionCode] = countryCode;
      }
    }
    _countryCodeToCountryNumberDictionary = [map copy];
  }

  return _countryCodeToCountryNumberDictionary;
}

- (NSDictionary *)countryCodeToRegionCodeDictionary {
  return _phoneNumberDataDictionary[@"countryCodeToRegionCodeMap"];
}

- (NSArray *)getAllMetadata {
  NSArray *countryCodes = [NSLocale ISOCountryCodes];
  NSMutableArray *resultMetadata = [[NSMutableArray alloc] initWithCapacity:countryCodes.count];

  for (NSString *countryCode in countryCodes) {
    id countryDictionaryInstance = [NSDictionary dictionaryWithObject:countryCode
                                                               forKey:NSLocaleCountryCode];
    NSString *identifier = [NSLocale localeIdentifierFromComponents:countryDictionaryInstance];
    NSString *country = [[NSLocale currentLocale] displayNameForKey:NSLocaleIdentifier
                                                              value:identifier];

    NSMutableDictionary *countryMeta = [[NSMutableDictionary alloc] init];
    if (country) {
      [countryMeta setObject:country forKey:@"name"];
    } else {
      NSString *systemCountry = [[NSLocale systemLocale] displayNameForKey:NSLocaleIdentifier
                                                                     value:identifier];
      if (systemCountry) {
        [countryMeta setObject:systemCountry forKey:@"name"];
      }
    }

    if (countryCode) {
      [countryMeta setObject:countryCode forKey:@"code"];
    }

    NBPhoneMetaData *metaData = [self getMetadataForRegion:countryCode];
    if (metaData) {
      [countryMeta setObject:metaData forKey:@"metadata"];
    }

    [resultMetadata addObject:countryMeta];
  }

  return resultMetadata;
}

- (NSArray *)regionCodeFromCountryCode:(NSNumber *)countryCodeNumber {
  NSArray *res = [self countryCodeToRegionCodeDictionary][[countryCodeNumber stringValue]];
  if ([res isKindOfClass:[NSArray class]] && [res count] > 0) {
    return res;
  }

  return nil;
}

- (NSString *)countryCodeFromRegionCode:(NSString *)regionCode {
  return [self countryCodeToCountryNumberDictionary][regionCode];
}

/**
 * Returns the metadata for the given region code or {@code nil} if the region
 * code is invalid or unknown.
 *
 * @param {?string} regionCode
 * @return {i18n.phonenumbers.PhoneMetadata}
 */
- (NBPhoneMetaData *)getMetadataForRegion:(NSString *)regionCode {
  regionCode = StringByTrimming(regionCode);
  if (regionCode.length == 0) {
    return nil;
  }

  regionCode = [regionCode uppercaseString];

  NBPhoneMetaData *cachedMetadata = [_metadataCache objectForKey:regionCode];
  if (cachedMetadata != nil) {
    return cachedMetadata;
  }

  NSDictionary *dict = _phoneNumberDataDictionary[@"countryToMetadata"];
  NSArray *entry = dict[regionCode];
  if (entry) {
    NBPhoneMetaData *metadata = [[NBPhoneMetaData alloc] initWithEntry:entry];
    [_metadataCache setObject:metadata forKey:regionCode];

    return metadata;
  }

  return nil;
}

/**
 * @param countryCallingCode countryCallingCode
 * @return {i18n.phonenumbers.PhoneMetadata}
 */
- (NBPhoneMetaData *)getMetadataForNonGeographicalRegion:(NSNumber *)countryCallingCode {
  NSString *countryCallingCodeStr = countryCallingCode.stringValue;
  return [self getMetadataForRegion:countryCallingCodeStr];
}

+ (BOOL)hasValue:(NSString *)string {
  string = StringByTrimming(string);
  return string.length != 0;
}

/**
 * Expand gzipped data into a JSON object.

 * @param bytes Array<Bytef> of zipped data.
 * @param compressedLength Length of the compressed bytes.
 * @param expandedLength Length of the expanded bytes.
 * @return JSON dictionary.
 */
+ (NSDictionary *)jsonObjectFromZippedDataWithBytes:(z_const Bytef *)bytes
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
