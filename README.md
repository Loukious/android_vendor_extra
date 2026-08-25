# vendor/extra — personal crDroid `onyx` additions

Auto-included by the build system without appearing in any product makefile:

- `build/make/core/board_config.mk` globs `vendor/*/*/BoardConfig*.mk`, which
  picks up `BoardConfigExtra.mk` and `BoardConfigKernel.mk`.
- `vendor/lineage/config/common.mk` inherits `vendor/extra/product.mk` if it
  exists.

That is why this directory has to be at exactly `vendor/extra` and why nothing
in `device/xiaomi/onyx` needs to reference it.

## What's here

| File | Purpose |
|---|---|
| `BoardConfigExtra.mk` | `WITH_GMS`/`BUILD_WITH_GAPPS`, pulls in the four PixelOS `board.mk` files |
| `BoardConfigKernel.mk` | points `TARGET_OVERRIDE_KERNEL_BIN` at the Kono-Ha kernel Image |
| `product.mk` | inherits PixelOS GMS, Launcher, ThemePicker, clocks and sounds; keeps crDroid Dialer; drops the Google comms suite |
| `permissions/**` | privapp-permission allowlists for Deskclock and the gesture-hint launcher shim |

`product.mk` depends on five projects from `gitlab.com/pixelos-aosp` being in the
manifest: `vendor/pixel/{gms,launcher,themepicker,clocks,sounds}`.

## The kernel Image is not committed

`kernel/` is gitignored. The 30 MB uncompressed `Image` is fetched from a
[`konoha-kernel-gki`](https://github.com/Loukious/konoha-kernel-gki) release by
`crdroid_onyx_patches/apply.sh`, which picks the KernelSU-Next `root` build with
charging bypass *off* and extracts `Image.gz` out of the AnyKernel3 zip.

## How the kernel actually gets swapped

Since crDroid's device tree commit `575e7da99` ("onyx: Switch source built dtbo,
kernel and modules") the ROM builds the kernel from `kernel/xiaomi/sm8735`
rather than shipping a prebuilt. That source build still has to happen — it is
what produces every vendor module (`mi_fp`, `si_haptic`, the QCOM external
modules) and the dtb/dtbo images. Kono-Ha is a generic CLO GKI tree and carries
none of those Xiaomi drivers.

So the kernel is built normally and only the *installed* `Image` is swapped,
via a three-line `TARGET_OVERRIDE_KERNEL_BIN` hook added to
`vendor/lineage/build/tasks/kernel.mk` by
`crdroid_onyx_patches/patches/vendor_lineage/0002-kernel-bin-override.patch`.

`TARGET_FORCE_PREBUILT_KERNEL` is deliberately **not** used: it sets
`FULL_KERNEL_BUILD := false`, which skips module and dtbo generation entirely
and yields an unbootable Image-only build.
