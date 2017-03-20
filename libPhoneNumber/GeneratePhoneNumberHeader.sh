#!/bin/sh

#  GeneratePhoneNumberHeader.sh
#  libPhoneNumber
#
#  Created by Dave MacLachlan on 2/7/17.
#  Copyright © 2017 Google Inc. All rights reserved.

# Takes the data sets in the PhoneNumberMetaData testing files and compresses them and then
# writes them into a header that we can pull into our source. The compression reduces them from 300k
# of data to 44k (per architecture). It would possibly be better to have this as a resource file
# that is read in from disk (because then we only pay for the size once), but that would
# dramatically change how this library is currently used by clients.
#
# The data set used is controlled by the value of the "TESTING" macro when the code is actually
# compiled.

set -eu

cd "${BASH_SOURCE%/*}" || exit

TEMPDIR=$(mktemp -d)
gzip -c "../libPhoneNumberTests/generatedJSON/PhoneNumberMetaDataForTesting.json" > "$TEMPDIR/PhoneNumberMetaDataForTesting.zip"
gzip -c "../libPhoneNumberTests/generatedJSON/PhoneNumberMetaData.json" > "$TEMPDIR/PhoneNumberMetaData.zip"

cat > "NBGeneratedPhoneNumberMetaData.h" <<'EOF'
/*****
 * Data Generated from GeneratePhoneNumberHeader.sh
 * Off of PhoneNumberMetaDataForTesting.json and PhoneNumberMetaData.json
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

z_const Bytef kPhoneNumberMetaData[] = {
EOF

cat "$TEMPDIR/PhoneNumberMetaDataForTesting.zip" | xxd -i  >> "NBGeneratedPhoneNumberMetaData.h"

cat >> "NBGeneratedPhoneNumberMetaData.h" <<'EOF'
};
z_const size_t kPhoneNumberMetaDataCompressedLength = sizeof(kPhoneNumberMetaData);
EOF
LIB_SIZE=$(stat -f%z "../libPhoneNumberTests/generatedJSON/PhoneNumberMetaDataForTesting.json")
echo "z_const size_t kPhoneNumberMetaDataExpandedLength = $LIB_SIZE;" >> "NBGeneratedPhoneNumberMetaData.h"

cat >> "NBGeneratedPhoneNumberMetaData.h" <<'EOF'

#else  // TESTING == 1

z_const Bytef kPhoneNumberMetaData[] = {
EOF

cat "$TEMPDIR/PhoneNumberMetaData.zip" | xxd -i  >> "NBGeneratedPhoneNumberMetaData.h"

cat >> "NBGeneratedPhoneNumberMetaData.h" <<'EOF'
};
z_const size_t kPhoneNumberMetaDataCompressedLength = sizeof(kPhoneNumberMetaData);
EOF
LIB_SIZE=$(stat -f%z "../libPhoneNumberTests/generatedJSON/PhoneNumberMetaData.json")
echo "z_const size_t kPhoneNumberMetaDataExpandedLength = $LIB_SIZE;" >> "NBGeneratedPhoneNumberMetaData.h"
echo "#endif  // TESTING" >> "NBGeneratedPhoneNumberMetaData.h"

rm "$TEMPDIR/PhoneNumberMetaDataForTesting.zip"
rm "$TEMPDIR/PhoneNumberMetaData.zip"
rmdir "$TEMPDIR"
