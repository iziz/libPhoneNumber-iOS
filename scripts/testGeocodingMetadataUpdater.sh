#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

source_dir="$tmp_dir/source"
output_dir="$tmp_dir/output"

mkdir -p \
  "$source_dir/resources/geocoding/en" \
  "$source_dir/resources/geocoding/ko" \
  "$output_dir"

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

echo "Geocoding metadata updater smoke test passed."
