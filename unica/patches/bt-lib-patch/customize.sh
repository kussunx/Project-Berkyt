# Bluetooth Library Patcher for known libbluetooth_jni.so revisions.
# An unrecognized APEX binary must never receive a guessed ARM branch patch.
BT_SYSTEM_LIB="$WORK_DIR/system/system/lib64/libbluetooth_jni.so"
BT_LIB="$BT_SYSTEM_LIB"
BT_EXTRACTED_FROM_APEX=false

if [ ! -f "$BT_SYSTEM_LIB" ]; then
    LOG_STEP_IN "- Extracting Bluetooth JNI library from com.android.bt.apex"

    [ ! -d "$TMP_DIR" ] || rm -rf "$TMP_DIR"
    mkdir -p "$TMP_DIR" || return 1

    EVAL "unzip -j \"$WORK_DIR/system/system/apex/com.android.bt.apex\" \"apex_payload.img\" -d \"$TMP_DIR\"" || return 1

    if command -v debugfs &> /dev/null; then
        EVAL "debugfs -R \"dump /lib64/libbluetooth_jni.so $TMP_DIR/libbluetooth_jni.so\" \"$TMP_DIR/apex_payload.img\"" || return 1
    else
        if ! sudo -n -v &> /dev/null; then
            ABORT "Root permissions are required to unpack Bluetooth APEX image"
        fi
        mkdir -p "$TMP_DIR/tmp_out" || return 1
        EVAL "sudo mount -o ro \"$TMP_DIR/apex_payload.img\" \"$TMP_DIR/tmp_out\"" || return 1
        EVAL "sudo cat \"$TMP_DIR/tmp_out/lib64/libbluetooth_jni.so\" > \"$TMP_DIR/libbluetooth_jni.so\"" || return 1
        EVAL "sudo umount \"$TMP_DIR/tmp_out\"" || return 1
    fi

    BT_LIB="$TMP_DIR/libbluetooth_jni.so"
    BT_EXTRACTED_FROM_APEX=true
    LOG_STEP_OUT
fi

if [ ! -s "$BT_LIB" ]; then
    LOGE "Bluetooth JNI library was not found or is empty: $BT_LIB"
    return 1
fi

BT_HEX="$(xxd -p -c 0 "$BT_LIB")" || return 1
BT_PATCH_FROM=""
BT_PATCH_TO=""

# Disable Samsung VaultKeeper branch only for byte patterns previously
# identified by the ROM's original Bluetooth Library Patcher.
case "$BT_HEX" in
    *39d9199428518152*) BT_PATCH_FROM="39d9199428518152"; BT_PATCH_TO="000080d228518152" ;;
    *2897773948050037*) BT_PATCH_FROM="2897773948050037"; BT_PATCH_TO="289777392a000014" ;;
    *183a009048050037*) BT_PATCH_FROM="183a009048050037"; BT_PATCH_TO="183a00902a000014" ;;
    *88f6713948050037*) BT_PATCH_FROM="88f6713948050037"; BT_PATCH_TO="88f671392a000014" ;;
    *2897663948050037*) BT_PATCH_FROM="2897663948050037"; BT_PATCH_TO="289766392a000014" ;;
    *6872743908530037*) BT_PATCH_FROM="6872743908530037"; BT_PATCH_TO="6872743998020014" ;;
    *76743948050037330080*) BT_PATCH_FROM="76743948050037330080"; BT_PATCH_TO="7674392a000014330080" ;;
    *88d6743948050037*) BT_PATCH_FROM="88d6743948050037"; BT_PATCH_TO="88d674392a000014" ;;
esac

if [ -z "$BT_PATCH_FROM" ]; then
    BT_SHA256="$(sha256sum "$BT_LIB" | cut -d ' ' -f 1)"
    LOGW "Unknown libbluetooth_jni.so SHA-256: $BT_SHA256"
    if [ "${ALLOW_UNPATCHED_BLUETOOTH:-false}" != "true" ]; then
        LOGE "No verified Bluetooth patch matches this firmware; build remains blocked by default"
        return 1
    fi

    # Explicit opt-in for experimental ROM builds. Preserve the source APEX
    # untouched and avoid installing a new system/lib64 override. Bluetooth
    # pairing persistence across reboot/airplane mode is NOT validated.
    LOGW "Experimental build: skipping Bluetooth Library Patcher; pairing persistence is unverified"
    if $BT_EXTRACTED_FROM_APEX; then
        rm -rf "$TMP_DIR"
    fi
    return 0
fi

# If the pattern is known, patch it before injecting into the work directory.
HEX_PATCH "$BT_LIB" "$BT_PATCH_FROM" "$BT_PATCH_TO" || return 1

if $BT_EXTRACTED_FROM_APEX; then
    EVAL "cp -f \"$BT_LIB\" \"$BT_SYSTEM_LIB\"" || return 1
    SET_METADATA "system" "system/lib64/libbluetooth_jni.so" 0 0 644 "u:object_r:system_lib_file:s0" || return 1
    rm -rf "$TMP_DIR"
fi
