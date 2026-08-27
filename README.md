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
| `product.mk` | inherits PixelOS GMS, Launcher, ThemePicker, clocks and sounds; keeps crDroid Dialer; drops the Google comms suite; installs the `music_detector` blobs and the DeviceConfig RRO |
| `permissions/**` | privapp-permission allowlists for Deskclock and the gesture-hint launcher shim |
| `firmware/music_detector.*` | Now Playing models copied to `/product/etc/firmware`. Only ungrey ASI's toggle; see below |
| `rro/SimpleDeviceConfigOverlayOnyx/` | static RRO over `org.protonaosp.deviceconfig` supplying the `NowPlaying__*` DeviceConfig flags Phenotype withholds from non-Pixels |

## Now Playing: the flag that matters

`rro/SimpleDeviceConfigOverlayOnyx/res/values/config.xml` carries four flags in
namespace `device_personalization_services`. Three fix the song-database download
and history UI. The fourth is the one that decides whether ambient recognition
can run at all:

```
NowPlaying__ambient_music_use_dsp_audio_source=false
```

It defaults to **true** in the ASI APK, which strands every non-Pixel: on this
SoC `module_type="CUSTOM1"` resolves to a `CustomVAInterface` stub with no ACDB
graph, so PAL reports `LOAD_MODEL`/`START_RECOGNITION` success while the ADSP
session underneath is inert (`graph_set_config failed -131`). Recognition itself
was never on the DSP — ASI ships `libsense.so` / `libsense_nnfp_v3.so` in
userspace and the model is TFLite — so setting this false makes ASI open a plain
16 kHz mono mic `AudioRecord` instead, needing no ACDB graph.

**Necessary but not sufficient.** There is a second, separate DSP dependency: the
*trigger*. `Lyyx`, the object the ambient pipeline consumes, is only ever built
from a `SoundTrigger$RecognitionEvent`, which ASI never constructs itself and
which `onyx` never delivers. This flag decides where audio comes from *after* an
event arrives; it starts nothing. Keep it anyway — it is a prerequisite for any
trigger fix, since a synthesized event then needs no usable DSP capture session.

On-demand recognition is a different path and should already work: `Lyxx;->d()`
uses its own mic `AudioRecord` plus `MusicRecognitionManager`, no SoundTrigger.

Costs the mic privacy indicator and standby drain. Confirm the value survives
boot — `SimpleDeviceConfig` sets it with `makeDefault=true`, which a Phenotype
push of the same key would still overwrite:

```sh
adb shell device_config get device_personalization_services \
    NowPlaying__ambient_music_use_dsp_audio_source
```

The full decompiled evidence is in the comment block at the top of
`rro/SimpleDeviceConfigOverlayOnyx/res/values/config.xml` and in `product.mk`.

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
