# Normalize only the Exynos2100 audio/Codec2 properties. Running uniq on the
# entire build.prop does not resolve conflicting values or nonadjacent duplicates.
SYSTEM_BUILD_PROP="$WORK_DIR/system/system/build.prop"
if [ ! -f "$SYSTEM_BUILD_PROP" ]; then
    LOGE "Missing system build.prop: $SYSTEM_BUILD_PROP"
    return 1
fi

LOG "- Normalizing Exynos2100 spatializer and Codec2 compatibility properties"
sed -i \
    -e '/^# Exynos2100 audio and Codec2 compatibility$/d' \
    -e '/^ro\.audio\.spatializer_enabled=/d' \
    -e '/^debug\.codec2\.stop_hal_before_surface=/d' \
    "$SYSTEM_BUILD_PROP" || return 1

# Idempotent on subsequent module invocations.
printf '\n# Exynos2100 audio and Codec2 compatibility\nro.audio.spatializer_enabled=true\ndebug.codec2.stop_hal_before_surface=1\n' \
    >> "$SYSTEM_BUILD_PROP" || return 1
