LOG_STEP_IN "- Applying Exynos2100 Codec2 seccomp compatibility patch"

OMX_POLICY="$WORK_DIR/vendor/etc/seccomp_policy/samsung.software.media.c2-base-policy"
ORIGINAL_RULE='mremap: arg3 == 3'
PATCHED_RULE='mremap: arg3 == 3 || arg3 == MREMAP_MAYMOVE'

if [ -f "$OMX_POLICY" ]; then
    # Never append a conflicting rule: one mremap filter is expected.
    MREMAP_RULE_COUNT="$(grep -Ec '^mremap:[[:space:]]' "$OMX_POLICY" || true)"
    if [ "$MREMAP_RULE_COUNT" -gt 1 ]; then
        LOGE "Multiple mremap seccomp rules found; refusing ambiguous patch"
        return 1
    elif grep -Fxq "$ORIGINAL_RULE" "$OMX_POLICY"; then
        LOG "- Allowing MREMAP_MAYMOVE for the Codec2 sandbox"
        sed -i 's/^mremap: arg3 == 3$/mremap: arg3 == 3 || arg3 == MREMAP_MAYMOVE/' "$OMX_POLICY" || return 1
    elif grep -Fxq "$PATCHED_RULE" "$OMX_POLICY"; then
        LOG "- Codec2 mremap rule already patched"
    else
        LOGW "Unknown Codec2 mremap rule; leaving existing policy untouched"
    fi
else
    LOGW "Codec2 seccomp policy not found; skipping unverified policy modification"
fi

LOG_STEP_OUT
