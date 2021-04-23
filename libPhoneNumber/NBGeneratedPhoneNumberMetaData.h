/*****
 * Data Generated from GeneratePhoneNumberHeader.sh
 * Off of PhoneNumberMetaDataForTesting.json, PhoneNumberMetaData.json, and ShortNumberMetaData.json
 */

#include <zlib.h>

// z_const is not defined in some versions of zlib, so define it here
// in case it has not been defined.
#if defined(ZLIB_CONST) && !defined(z_const)
#  define z_const const
#else
#  define z_const
#endif

#if TESTING==1

extern z_const Bytef kPhoneNumberMetaData[];
extern z_const size_t kPhoneNumberMetaDataCompressedLength;
extern z_const size_t kPhoneNumberMetaDataExpandedLength;

#else  // TESTING == 1

extern z_const Bytef kPhoneNumberMetaData[];
extern z_const size_t kPhoneNumberMetaDataCompressedLength;
extern z_const size_t kPhoneNumberMetaDataExpandedLength;
#endif  // TESTING

#if SHORT_NUMBER_SUPPORT

extern z_const Bytef kShortNumberMetaData[] ;
extern z_const size_t kShortNumberMetaDataCompressedLength;
extern z_const size_t kShortNumberMetaDataExpandedLength;
#endif  // SHORT_NUMBER_SUPPORT
