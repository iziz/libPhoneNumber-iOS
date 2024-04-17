/*****
 * Data Generated from GeneratePhoneNumberHeader.sh
 * Off of PhoneNumberMetaData.json
 */

#include <zlib.h>

// z_const is not defined in some versions of zlib, so define it here
// in case it has not been defined.
#if defined(ZLIB_CONST) && !defined(z_const)
#  define z_const const
#else
#  define z_const
#endif

extern z_const Bytef kPhoneNumberMetaData[];
extern z_const size_t kPhoneNumberMetaDataCompressedLength;
extern z_const size_t kPhoneNumberMetaDataExpandedLength;
