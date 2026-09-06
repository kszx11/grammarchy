#!/usr/bin/env bash
# Verify the exact upstream artifact bundled by Grammarchy. This script only
# writes to a temporary directory and never replaces files in the checkout.
set -euo pipefail

readonly ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly WORK_DIR="$(mktemp -d)"
readonly RELEASE_ASSET_ID="318906028"
readonly RELEASE_ASSET_API_URL="https://api.github.com/repos/ufal/udpipe/releases/assets/$RELEASE_ASSET_ID"
readonly RELEASE_SHA256="457f541e204737d354c749b473060a28b2debf625f23075543d9eba78be016c1"
readonly ARCHIVE_MEMBER="udpipe-1.4.0-bin/bin-linux64/udpipe"
readonly BINARY_SHA256="8770ff2114258a1df1ea8403dcbea92d3336ab6d3e420499d57c54e3dea6a11b"
readonly SOURCE_URL="https://github.com/ufal/udpipe/archive/a0e72fcb1ba0d36998dc671db4350bbd159861b5.tar.gz"
readonly SOURCE_SHA256="b06d279b1353b0cb417a989847b21789a7449520390b071d8cf48f168c0cc33e"

cleanup() {
  rm -rf "$WORK_DIR"
}
trap cleanup EXIT

verify_sha256() {
  local expected="$1"
  local file="$2"
  local actual
  actual="$(sha256sum "$file" | awk '{print $1}')"
  if [[ "$actual" != "$expected" ]]; then
    printf 'Checksum mismatch for %s\nexpected: %s\nactual:   %s\n' "$file" "$expected" "$actual" >&2
    exit 1
  fi
}

curl --fail --silent --show-error --location --proto '=https' --tlsv1.2 --retry 2 \
  --header 'Accept: application/octet-stream' \
  --header 'X-GitHub-Api-Version: 2022-11-28' \
  --output "$WORK_DIR/udpipe-1.4.0-bin.zip" "$RELEASE_ASSET_API_URL"
verify_sha256 "$RELEASE_SHA256" "$WORK_DIR/udpipe-1.4.0-bin.zip"
unzip -qq "$WORK_DIR/udpipe-1.4.0-bin.zip" "$ARCHIVE_MEMBER" -d "$WORK_DIR"
verify_sha256 "$BINARY_SHA256" "$WORK_DIR/$ARCHIVE_MEMBER"
cmp --silent "$WORK_DIR/$ARCHIVE_MEMBER" "$ROOT_DIR/runtime/linux-x86_64/udpipe"

# The source archive is not used to generate the release artifact. Verifying
# it supplies an independently checkable source identity for reviewer audits.
curl --fail --silent --show-error --location --proto '=https' --tlsv1.2 --retry 2 \
  --output "$WORK_DIR/udpipe-source.tar.gz" "$SOURCE_URL"
verify_sha256 "$SOURCE_SHA256" "$WORK_DIR/udpipe-source.tar.gz"
tar -tzf "$WORK_DIR/udpipe-source.tar.gz" > "$WORK_DIR/udpipe-source-files.txt"
grep -q '/src/udpipe.cpp$' "$WORK_DIR/udpipe-source-files.txt"

printf 'Verified upstream UDPipe v1.4.0 release asset %s and bundled Linux x86_64 binary.\n' "$RELEASE_ASSET_ID"
