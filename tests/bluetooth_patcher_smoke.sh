#!/usr/bin/env bash
set -euo pipefail

# Tests known-byte replacement and the explicit unpatched fallback in the
# root-library path. APEX extraction is tested by the full firmware build.
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PATCH="$ROOT/unica/patches/bt-lib-patch/customize.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

WORK_DIR="$TMP/work"
TMP_DIR="$TMP/apex"
BT_TEST_LIB="$WORK_DIR/system/system/lib64/libbluetooth_jni.so"
mkdir -p "$(dirname "$BT_TEST_LIB")"

LOG_STEP_IN() { :; }
LOG_STEP_OUT() { :; }
LOG() { :; }
LOGW() { :; }
LOGE() { printf 'EXPECTED DIAGNOSTIC: %s\n' "$*" >&2; }
EVAL() { eval "$1"; }
HEX_PATCH() {
    local original="$1" from="$2" to="$3"
    xxd -p -c 0 "$original" | sed "s/$from/$to/" | xxd -r -p > "$original.new"
    mv "$original.new" "$original"
}
SET_METADATA() { echo 'Unexpected new metadata on root library' >&2; return 1; }

# Unknown bytes must fail closed unless a user deliberately opts in.
printf '00112233445566778899aabb' | xxd -r -p > "$BT_TEST_LIB"
cp "$BT_TEST_LIB" "$TMP/stock.bin"
if (unset ALLOW_UNPATCHED_BLUETOOTH; . "$PATCH"); then
    echo 'Unknown Bluetooth JNI bytes passed without opt-in' >&2
    exit 1
fi

# Experimental build keeps the unrecognized bytes intact.
ALLOW_UNPATCHED_BLUETOOTH=true
. "$PATCH"
cmp -s "$TMP/stock.bin" "$BT_TEST_LIB"

# A known signature receives exactly the original supported byte sequence.
printf '001128977739480500372233' | xxd -r -p > "$BT_TEST_LIB"
. "$PATCH"
grep -q '289777392a000014' <(xxd -p -c 0 "$BT_TEST_LIB")
echo 'PASS: Bluetooth unknown revision fails closed or skips unchanged; known bytes patched'
