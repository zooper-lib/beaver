#!/bin/sh
# Writes checksums.txt and beaver-manifest.json for the release binaries in
# DIR. The manifest maps each platform to its file and SHA-256; the IntelliJ
# plugin embeds it and verifies downloads against it.
#
#   tool/release/manifest.sh DIR VERSION PROTOCOL
set -eu
dir=$1 version=$2 protocol=$3
cd "$dir"

sha() {
  if command -v sha256sum >/dev/null; then sha256sum "$1" | cut -d' ' -f1
  else shasum -a 256 "$1" | cut -d' ' -f1; fi
}

: > checksums.txt
entries=""
for platform in linux-x64 linux-arm64 macos-x64 macos-arm64 windows-x64; do
  file=beaver-$platform
  [ "$platform" = windows-x64 ] && file=$file.exe
  if [ ! -f "$file" ]; then echo "missing $file" >&2; exit 1; fi
  sum=$(sha "$file")
  echo "$sum  $file" >> checksums.txt
  entries="$entries${entries:+,}
    \"$platform\": {\"file\": \"$file\", \"sha256\": \"$sum\"}"
done

cat > beaver-manifest.json <<JSON
{
  "version": "$version",
  "protocol": $protocol,
  "baseUrl": "https://github.com/zooper-lib/beaver/releases/download/v$version/",
  "binaries": {$entries
  }
}
JSON
echo "wrote checksums.txt and beaver-manifest.json for $version"
