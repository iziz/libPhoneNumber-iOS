#!/bin/sh

#  GeneratePhoneNumberHeader.sh
#  libPhoneNumber
#
#  Created by Dave MacLachlan on 2/7/17.
#  Copyright © 2017 Google Inc. All rights reserved.

# Takes the data sets in the PhoneNumberMetaData files and compresses them and then
# writes them into headers that we can pull into our source. The compression reduces them from 300k
# of data to 44k (per architecture). It would possibly be better to have this as a resource file
# that is read in from disk (because then we only pay for the size once), but that would
# dramatically change how this library is currently used by clients.
# The testing data is zipped into a resource file.

set -eu

cd "${BASH_SOURCE%/*}" || exit

readonly CORE_METADATA_HEADER="../libPhoneNumber/NBGeneratedPhoneNumberMetaData.h"
readonly CORE_METADATA_IMPL="../libPhoneNumber/NBGeneratedPhoneNumberMetaData.m"
readonly SHORT_NUMBER_METADATA_HEADER="../libPhoneNumberShortNumber/NBGeneratedShortNumberMetaData.h"
readonly SHORT_NUMBER_METADATA_IMPL="../libPhoneNumberShortNumber/NBGeneratedShortNumberMetaData.m"

TEMPDIR=$(mktemp -d)
gzip -c "../generatedJSON/PhoneNumberMetaData.json" > "$TEMPDIR/PhoneNumberMetaData.zip"
gzip -c "../generatedJSON/ShortNumberMetaData.json" > "$TEMPDIR/ShortNumberMetaData.zip"

# Core Metadata Header
cat > "$CORE_METADATA_HEADER" <<'EOF'
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
EOF

# Core Metadata Implementation
cat > "$CORE_METADATA_IMPL" <<'EOF'
#include "NBGeneratedPhoneNumberMetaData.h"

z_const Bytef kPhoneNumberMetaData[] = {
EOF

cat "$TEMPDIR/PhoneNumberMetaData.zip" | xxd -i  >> "$CORE_METADATA_IMPL"

cat >> "$CORE_METADATA_IMPL" <<'EOF'
};
z_const size_t kPhoneNumberMetaDataCompressedLength = sizeof(kPhoneNumberMetaData);
EOF
LIB_SIZE=$(stat -f%z "../generatedJSON/PhoneNumberMetaData.json")
echo "z_const size_t kPhoneNumberMetaDataExpandedLength = $LIB_SIZE;" >> "$CORE_METADATA_IMPL"

# Short Number Metadata Header
cat > "$SHORT_NUMBER_METADATA_HEADER" <<'EOF'
/*****
 * Data Generated from GeneratePhoneNumberHeader.sh
 * Off of ShortNumberMetaData.json
 */

#include <zlib.h>

// z_const is not defined in some versions of zlib, so define it here
// in case it has not been defined.
#if defined(ZLIB_CONST) && !defined(z_const)
#  define z_const const
#else
#  define z_const
#endif

extern z_const Bytef kShortNumberMetaData[];
extern z_const size_t kShortNumberMetaDataCompressedLength;
extern z_const size_t kShortNumberMetaDataExpandedLength;
EOF

# Short Number Metadata Implementation
cat > "$SHORT_NUMBER_METADATA_IMPL" <<'EOF'
#include "NBGeneratedShortNumberMetaData.h"

z_const Bytef kShortNumberMetaData[] = {
EOF

cat "$TEMPDIR/ShortNumberMetaData.zip" | xxd -i  >> "$SHORT_NUMBER_METADATA_IMPL"

cat >> "$SHORT_NUMBER_METADATA_IMPL" <<'EOF'
};
z_const size_t kShortNumberMetaDataCompressedLength = sizeof(kShortNumberMetaData);
EOF
LIB_SIZE=$(stat -f%z "../generatedJSON/ShortNumberMetaData.json")
echo "z_const size_t kShortNumberMetaDataExpandedLength = $LIB_SIZE;" >> "$SHORT_NUMBER_METADATA_IMPL"

# Metadata for testing
gzip -c "../generatedJSON/PhoneNumberMetaDataForTesting.json" > "../Resources/libPhoneNumberMetadataForTesting"
LIB_SIZE=$(stat -f%z "../generatedJSON/PhoneNumberMetaDataForTesting.json")
echo "static size_t kPhoneNumberMetaDataForTestingExpandedLength = $LIB_SIZE;" > "../libPhoneNumberTests/NBTestingMetaData.h"
echo "static size_t kPhoneNumberMetaDataForTestingExpandedLength = $LIB_SIZE;" > "../libPhoneNumberShortNumberTests/NBTestingMetaData.h"

rm "$TEMPDIR/PhoneNumberMetaData.zip"
rm "$TEMPDIR/ShortNumberMetaData.zip"
rmdir "$TEMPDIR"
