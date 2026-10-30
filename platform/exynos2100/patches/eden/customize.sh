LOG_STEP_IN "- Fixing EDEN debug logging"

# Remove EDEN debug logging from each partition without touching other props.
for BUILD_PROP in "$WORK_DIR/vendor/build.prop" "$WORK_DIR/system/system/build.prop"; do
    if [ -f "$BUILD_PROP" ]; then
        LOG "- Removing EDEN INFO debug logging from $BUILD_PROP"
        EVAL "sed -i '/^log\.tag\.EDEN=INFO$/d' \"$BUILD_PROP\"" || return 1
    fi
done

LOG_STEP_OUT

LOG_STEP_IN "- Patching libvpl.so (64-bit only)"

LIBVPL_64="$WORK_DIR/vendor/lib64/libvpl.so"
# Resolve the patcher from the module directory; Exynos990 was an invalid path.
PATCH_SCRIPT="$MODPATH/patch_libvpl_unload.py"

if [ -f "$LIBVPL_64" ]; then
    if [ ! -f "$PATCH_SCRIPT" ]; then
        LOGE "Missing Exynos2100 EDEN patcher: $PATCH_SCRIPT"
        return 1
    fi
    LOG "- Patching vendor/lib64/libvpl.so (vplUnload -> immediate return)"
    EVAL "python3 \"$PATCH_SCRIPT\" \"$LIBVPL_64\"" || return 1
else
    LOGW "vendor/lib64/libvpl.so not found; skipping EDEN binary patch"
fi

LOG_STEP_OUT
