#!/usr/bin/env bash
set -euo pipefail

# Logic tests only. These do not validate a ROM image, a GPU driver or a device.
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
WORK_DIR="$TMP/work"
MODPATH="$ROOT/platform/exynos2100/patches/eden"

LOG_STEP_IN() { :; }
LOG_STEP_OUT() { :; }
LOG() { :; }
LOGW() { :; }
LOGE() { printf 'ERROR: %s\n' "$*" >&2; }
EVAL() { eval "$1"; }

EDEN="$ROOT/platform/exynos2100/patches/eden/customize.sh"
OMX="$ROOT/platform/exynos2100/patches/omx/customize.sh"
PROPS="$ROOT/platform/exynos2100/patches/stock_props/customize.sh"
for f in "$EDEN" "$OMX" "$PROPS"; do bash -n "$f"; done
grep -Fq 'PATCH_SCRIPT="$MODPATH/patch_libvpl_unload.py"' "$EDEN"

mkdir -p "$WORK_DIR/vendor/etc/seccomp_policy" "$WORK_DIR/vendor/lib64" "$WORK_DIR/system/system"
printf 'keep=1\nlog.tag.EDEN=INFO\n' > "$WORK_DIR/vendor/build.prop"
printf 'ro.audio.spatializer_enabled=false\ndebug.codec2.stop_hal_before_surface=0\nkeep=2\n' > "$WORK_DIR/system/system/build.prop"

# EDEN: missing libvpl.so means no binary modification, but debug props are cleaned.
. "$EDEN"
! grep -q '^log.tag.EDEN=INFO$' "$WORK_DIR/vendor/build.prop"
grep -qxF 'keep=1' "$WORK_DIR/vendor/build.prop"

. "$PROPS"
cp "$WORK_DIR/system/system/build.prop" "$TMP/once"
. "$PROPS"
cmp -s "$TMP/once" "$WORK_DIR/system/system/build.prop"
test "$(grep -c '^ro.audio.spatializer_enabled=' "$WORK_DIR/system/system/build.prop")" -eq 1
test "$(grep -c '^debug.codec2.stop_hal_before_surface=' "$WORK_DIR/system/system/build.prop")" -eq 1
grep -qxF 'keep=2' "$WORK_DIR/system/system/build.prop"

POLICY="$WORK_DIR/vendor/etc/seccomp_policy/samsung.software.media.c2-base-policy"
printf 'read: 1\nmremap: arg3 == 3\n' > "$POLICY"
. "$OMX"
. "$OMX"
test "$(grep -c '^mremap:' "$POLICY")" -eq 1
grep -qxF 'mremap: arg3 == 3 || arg3 == MREMAP_MAYMOVE' "$POLICY"

printf 'mremap: arg3 == 3\nmremap: 1\n' > "$POLICY"
if (. "$OMX"); then
    echo 'Duplicate seccomp rule should reject the build' >&2
    exit 1
fi
echo 'PASS: EDEN path, build.prop idempotence and Codec2 seccomp guards'
