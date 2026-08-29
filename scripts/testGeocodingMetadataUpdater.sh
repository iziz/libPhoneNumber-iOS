#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

source_dir="$tmp_dir/source"
output_dir="$tmp_dir/output"
wrapper_repo="$tmp_dir/wrapper-repo"
review_dir="$tmp_dir/review"
bundle_dir="$wrapper_repo/libPhoneNumberGeocodingMetaData/GeocodingMetaData.bundle"

mkdir -p \
  "$source_dir/resources/geocoding/en" \
  "$source_dir/resources/geocoding/ko" \
  "$output_dir" \
  "$wrapper_repo/scripts" \
  "$bundle_dir"

cat > "$source_dir/resources/geocoding/en/1.txt" <<'EOF'
# United States and NANPA test data.
1650|Mountain View, CA
1212|New York, NY
EOF

cat > "$source_dir/resources/geocoding/en/82.txt" <<'EOF'
822|Seoul
EOF

cat > "$source_dir/resources/geocoding/ko/82.txt" <<'EOF'
822|서울
EOF

"$repo_root/scripts/updateGeocodingMetadata.swift" \
  --source "$source_dir" \
  --output "$output_dir"

test "$(sqlite3 "$output_dir/en.db" "select DESCRIPTION from geocodingpairs1 where NATIONALNUMBER='1650';")" = "Mountain View, CA"
test "$(sqlite3 "$output_dir/en.db" "select DESCRIPTION from geocodingpairs82 where NATIONALNUMBER='822';")" = "Seoul"
test "$(sqlite3 "$output_dir/ko.db" "select DESCRIPTION from geocodingpairs82 where NATIONALNUMBER='822';")" = "서울"

cp "$repo_root/scripts/updateGeocodingMetadata.swift" "$wrapper_repo/scripts/updateGeocodingMetadata.swift"
sqlite3 "$bundle_dir/stale.db" "create table stale(value text);"

"$wrapper_repo/scripts/updateGeocodingMetadata.swift" \
  --source "$source_dir" \
  --output "$review_dir" \
  --replace-bundle

test "$(sqlite3 "$review_dir/en.db" "select DESCRIPTION from geocodingpairs1 where NATIONALNUMBER='1650';")" = "Mountain View, CA"
test "$(sqlite3 "$bundle_dir/en.db" "select DESCRIPTION from geocodingpairs1 where NATIONALNUMBER='1650';")" = "Mountain View, CA"
test "$(sqlite3 "$bundle_dir/ko.db" "select DESCRIPTION from geocodingpairs82 where NATIONALNUMBER='822';")" = "서울"
test ! -e "$bundle_dir/stale.db"

echo "Geocoding metadata updater smoke test passed."
