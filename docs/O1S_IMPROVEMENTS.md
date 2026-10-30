# Project Berkyt — Exynos 2100 / o1s fixes

Independent source snapshot based on [Yacinegti-DZ/Project-Berkyt](https://github.com/Yacinegti-DZ/Project-Berkyt), branch `sixteen`, upstream commit `8a586e66d755b96d88475b8ef7f85178d7ddd128` (2026-10-09).

This is an independently hosted copy, **not** a GitHub-native fork. The owner's account already contains a separate fork of UN1CA, which prevents creating another GitHub fork in the same fork network. Synchronize upstream changes manually and review conflicts.

## Implemented

1. `platform/exynos2100/patches/eden/customize.sh`: locate the `libvpl.so` patcher in `$MODPATH` rather than the non-existent Exynos990 path; fail on a missing patcher or an unsuccessful binary-patching command.
2. `platform/exynos2100/patches/omx/customize.sh`: update the known Codec2 seccomp rule once, reject duplicate `mremap` rules, and avoid appending a new rule to an unknown policy.
3. `platform/exynos2100/patches/stock_props/customize.sh`: normalize the two relevant audio/Codec2 properties without globally applying `uniq` to `build.prop`; repeated runs do not accumulate properties.

Run script checks: `bash tests/o1s_patch_smoke.sh`.

## Build and flash cautions

- Intended target: Samsung Galaxy S21 Exynos (`o1s`, `SM-G991B`).
- Confirm the device's exact bootloader/revision against `target/o1s/installer/assertions.edify`; **unlocked** does not mean **compatible**.
- The installer can update bootloader, modem and `vbmeta`. Inspect the actual flashable ZIP before installing.
- **No kernel, GPU, Vulkan, Mali, boot image or root implementation has been changed.**
- This source snapshot is **not** a tested flashable ROM. The Instagram/TikTok video flicker is **not** claimed fixed.
- Full firmware extraction, ROM build, `boot.img` inspection, on-device media playback and recovery testing remain necessary.
- Do not flash `source.zip` or `git archive` as if they were recovery packages.

For an on-device test plan: reproduce the flicker using the same video across hardware acceleration paths and collect `logcat` / `dmesg` markers from MediaCodec, HWC, Mali and SurfaceFlinger before changing graphics blobs.
