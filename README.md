# vendor/extra — personal Evolution X `onyx` additions

Auto-included by the build system without appearing in any product makefile:

- `build/make/core/board_config.mk` globs `vendor/*/*/BoardConfig*.mk`, which
  picks up `BoardConfigExtra.mk` and `BoardConfigKernel.mk`.
- `vendor/lineage/config/common.mk` inherits `vendor/extra/product.mk` if it
  exists. Under Evolution X that path is `vendor_evolution`, which the manifest
  mounts at `vendor/lineage` — so this keeps working unchanged.

That is why this directory has to be at exactly `vendor/extra` and why nothing
in `device/xiaomi/onyx` needs to reference it.

## What's here

| File | Purpose |
|---|---|
| `BoardConfigExtra.mk` | `WITH_GMS := true` |
| `BoardConfigKernel.mk` | points `TARGET_OVERRIDE_KERNEL_BIN` at the Kono-Ha kernel Image |
| `product.mk` | `WITH_GMS`, relaxes `check_vintf` for the Kono-Ha kernel, ships one privapp allowlist |
| `permissions/**` | privapp-permission allowlist for AOSP DeskClock |

## Now Playing was removed

On 2026-08-28 the Now Playing work was dropped: the `music_detector` models, the
`SimpleDeviceConfigOverlayOnyx` RRO, and the SystemUI port in
`crdroid_onyx_patches`. It never produced a confirmed detection on `onyx` — the
ambient pipeline is gated on a `SoundTrigger$RecognitionEvent` this ADSP never
delivers — and Evolution X ships the feature natively on its `bka` branch, so a
port buys nothing. The removed files and the full decompiled evidence are
preserved on the `nowplaying-archive` branch of this repo.

## GApps come from Evolution X now

The crDroid build carried five PixelOS projects —
`vendor/pixel/{gms,launcher,themepicker,clocks,sounds}` — and `product.mk`
inherited each one by hand. All five are gone. Evolution X's own
`vendor/lineage/config/common_full_phone.mk` inherits `vendor/gms/gms_full.mk`
whenever `WITH_GMS` is true, and true is its default, so a single variable
replaces the lot:

| What PixelOS provided | Evolution X equivalent |
|---|---|
| `vendor/pixel/gms` | `vendor/gms` (`vendor_gms`) |
| `vendor/pixel/launcher` | `vendor_gms` ships `NexusLauncherRelease` |
| `vendor/pixel/sounds` | `vendor_gms` ships `SoundPickerPrebuilt` |
| `vendor/pixel/clocks`, `vendor/pixel/themepicker` | `vendor/pixel-style`'s RRO set plus `vendor_gms`' `PixelWallpapers2025` |

`vendor/pixel-style` also ships `PixelLauncherNoGestureHintOverlay` — the same
overlay the old `vendor_pixel_launcher` patch added by hand — and Evolution X's
`GestureNavigationSettingsFragment` already toggles it from the
`navigation_bar_hint` preference. That patch and its privileged helper app
(`com.loukious.pixellauncher.gesturehint`) are therefore gone, along with the
allowlist entry that went with them.

`vendor_gms` uses Git LFS against Evolution X's own server
(`git.evolution-x.org`), so `repo init` needs `--git-lfs`.

## The kernel Image is not committed

`kernel/` is gitignored. The 30 MB uncompressed `Image` is fetched from a
[`konoha-kernel-gki`](https://github.com/Loukious/konoha-kernel-gki) release by
`crdroid_onyx_patches/apply.sh`, which picks the KernelSU-Next `root` build with
charging bypass *off* and extracts `Image.gz` out of the AnyKernel3 zip.

## How the kernel actually gets swapped

Since the device tree's commit `575e7da99` ("onyx: Switch source built dtbo,
kernel and modules") the ROM builds the kernel from `kernel/xiaomi/sm8735`
rather than shipping a prebuilt. That source build still has to happen — it is
what produces every vendor module (`mi_fp`, `si_haptic`, the QCOM external
modules) and the dtb/dtbo images. Kono-Ha is a generic CLO GKI tree and carries
none of those Xiaomi drivers.

So the kernel is built normally and only the *installed* `Image` is swapped,
via a three-line `TARGET_OVERRIDE_KERNEL_BIN` hook added to
`vendor/lineage/build/tasks/kernel.mk` (`vendor_evolution` under Evolution X) by
`crdroid_onyx_patches/patches/vendor_lineage/0002-kernel-bin-override.patch`.

`TARGET_FORCE_PREBUILT_KERNEL` is deliberately **not** used: it sets
`FULL_KERNEL_BUILD := false`, which skips module and dtbo generation entirely
and yields an unbootable Image-only build.
