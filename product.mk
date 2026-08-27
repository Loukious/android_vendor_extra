#
# Personal crDroid onyx product additions
#

# Unofficial build identity.
#
# Settings' "Device maintainer" entry (BuildMaintainerPreference) and the donate
# link behind it read these two properties. They exist because the stock
# behaviour is to look the maintainer up in crDroid's OTA index by device
# codename alone -- and onyx *does* have an official entry there, so without
# these an unofficial build would proudly credit the official maintainer and
# point donations at their PayPal. See
# patches/packages_apps_Settings/0001-maintainer-from-prop.patch.
PRODUCT_PRODUCT_PROPERTIES += \
    ro.crdroid.maintainer=Loukious \
    ro.crdroid.donate.url=https://buymeacoffee.com/loukious

# Build a bundled-GApps variant.
WITH_GMS := true
BUILD_WITH_GAPPS := true

# PixelOS provides the same SystemUIClocks module names as crDroid's stock
# prebuilts. Exclude the stock definitions so PixelOS is the sole provider.
PRODUCT_SOURCE_ROOT_DIRS += -vendor/addons/themes/SystemUIClocks

# The bundled Kono-Ha kernel is runtime-tested on onyx.
# It does not expose every Android kernel FCM config expected by check_vintf.
PRODUCT_OTA_ENFORCE_VINTF_KERNEL_REQUIREMENTS := false

# Do not include PixelOS Google Phone and messaging suite.
WITH_GMS_COMMS_SUITE := false

# PixelOS Android 16 QPR2 Google Mobile Services.
$(call inherit-product, vendor/pixel/gms/common/common-vendor.mk)

# PixelOS Android 16 QPR2 Pixel Launcher.
$(call inherit-product, vendor/pixel/launcher/products/launcher.mk)

# PixelOS Android 16 QPR2 Wallpaper & style / ThemePicker.
$(call inherit-product, vendor/pixel/themepicker/products/themepicker.mk)

# PixelOS Android 16 QPR2 lockscreen clock faces.
$(call inherit-product, vendor/pixel/clocks/products/clocks.mk)

# PixelOS Android 16 QPR2 sounds and Sound Picker.
# Import the proprietary sounds and overlays without PixelOS default ringtone
# properties, which conflict with crDroid/Onyx defaults on Android 16.
$(call inherit-product, vendor/pixel/sounds/common/common-vendor.mk)
PRODUCT_PACKAGES += \
    FrameworkPixelSounds \
    SettingsPixelSounds

# Keep crDroid Dialer and retain Google Messages.
PRODUCT_PACKAGES += \
    Dialer \
    PrebuiltBugle

# Local privileged-permission allowlists.
PRODUCT_COPY_FILES += \
    vendor/extra/permissions/product/privapp-permissions-com.android.deskclock.xml:$(TARGET_COPY_OUT_PRODUCT)/etc/permissions/privapp-permissions-com.android.deskclock.xml \
    vendor/extra/permissions/system_ext/privapp-permissions-com.loukious.pixellauncher.gesturehint.xml:$(TARGET_COPY_OUT_SYSTEM_EXT)/etc/permissions/privapp-permissions-com.loukious.pixellauncher.gesturehint.xml


# Now Playing (ambient music) music-detector model.
#
# ASI probes a fixed search order and uses the first hit:
#
#     /product/etc/firmware/music_detector.sound_model_tflite   <- newest
#     /product/etc/firmware/music_detector.sound_model_2
#     /product/etc/firmware/music_detector.sound_model
#     /system/etc/firmware/music_detector.sound_model           <- legacy
#     /vendor/etc/firmware/music_detector.sound_model
#
# (Confirmed by disassembling the string table of our own prebuilt,
# DevicePersonalizationPrebuiltPixel2024-playstore_aiai_20250306.00_RC10, and of
# Evolution X's DevicePersonalizationAiAiPrebuiltPixel2026 - both search the same
# five paths.) The model is NOT optional: with none of them present, ASI throws
# "java.lang.IllegalArgumentException: Can't load ..." out of
# NowPlayingInitializerImpl and greys the Now Playing toggle out. There is no
# software-only fallback.
#
# These come from TheMuppets/proprietary_vendor_google_tokay @ lineage-23.2 -
# Pixel 9, Android 16, i.e. the same ASI generation as our prebuilt. Note
# sound_model and sound_model_tflite are byte-identical (22932 B); sound_model_2
# is the 216 KB TFLite flatbuffer. Ship all four so the search order resolves to
# the newest entry rather than to a legacy one.
#
# Do NOT substitute the barbet/redfin/sunfish pair from
# TheMuppets/proprietary_vendor_google @ lineage-19.1 that used to live here. It
# is an Android 12 blob (34432 B), it only satisfies the legacy /system path, and
# while PAL does load it and arm the DSP, it never produces a single detection -
# recognition_history stayed empty forever. Version this by Android release, not
# by SoC.
#
# ---------------------------------------------------------------------------
# 2026-08-27: WHY AMBIENT NOW PLAYING DOES NOT WORK ON onyx, in two parts.
# Read this before spending another hour on model generation or soundtrigger XML.
# Part 1 (the audio source) is fixed below. Part 2 (the trigger) is not, and it
# is the one that actually blocks detections.
#
# A 45 s PAL/AGM/ACDB trace taken while ASI armed the session proves the
# Qualcomm ADSP on this SoC rejects Google's model outright:
#
#   E/PAL:  CustomVAInterface: SetParameter: Unsupported param id 2
#   E/PAL:  CustomVAInterface: GetParameter: Unsupported param id 30
#   E/AGM:  graph_set_config failed -131
#   E/AGM:  session_obj_set_sess_aif_params: Error:-131 ... sess_id:112 aif_id:54
#   E/PAL:  SessionAlsaPcm setParameters: Failed to set mixer param, status = -131
#   E/PAL:  SoundTriggerEngineGsl UpdateSessionPayload: Failed to set payload
#           for param id 20, status = -131
#   E/ACDB: AcdbCmdGetGraphAlias Error[19]: Unable to find graph key vector
#
# Our module_type="CUSTOM1" resolves to model type 102 -> CustomVAInterface, and
# libcustomva_intf.so on this device is a Qualcomm *stub*: ACDB carries no DSP
# graph for it. PAL still reports success to the HAL, so the session ends up
# armed and inert -- which is exactly why recognition_history stays empty no
# matter which model is shipped. Nothing on the DSP side can fix that; it needs
# an ACDB graph we do not have, and no amount of model regeneration produces one.
#
# WHAT DOES FIX IT: stop asking for the DSP. Recognition itself never ran on the
# DSP -- the DSP was only the low-power microphone. ASI carries its own userspace
# recognizer inside the APK (lib/arm64-v8a/libsense.so 433 KB and
# libsense_nnfp_v3.so 4.8 MB; NNFP = neural network fingerprint), and the model
# shipped below is a TFLite graph ("TFL3" magic at offset 4), not a DSP blob. The
# audio source is selected by one flag, decompiled here from the ASI prebuilt:
#
#   iget-boolean v1, v1, Lyxc;->o:Z    # ambient_music_use_dsp_audio_source
#   if-eqz v1, :cond_5e
#   ...  "Creating AudioRecord accessing DSP audio."   -> Lyyx;->d(F)
#  :cond_5e
#   ...  "Creating AudioRecord accessing Mic audio (shouldn't happen)."
#        new AudioRecord(0 /* DEFAULT/MIC */, 16000, CHANNEL_IN_MONO,
#                        ENCODING_PCM_16BIT, size)
#
# It defaults to true (myz.<clinit>: const/4 v0,0x1 -> Boolean.valueOf, wired to
# the NowPlaying__ambient_music_use_dsp_audio_source qvp), so every non-Pixel
# gets the unsatisfiable path by default. The mic branch touches neither
# SoundTrigger nor Lyyx and therefore needs no ACDB graph. Its "(shouldn't
# happen)" string is Google's own and only means no Pixel ever takes it -- the
# code is fully implemented. We set it false in the RRO below.
#
# NECESSARY BUT NOT SUFFICIENT. Tracing up the pipeline settles what the flag
# does not fix. Lylv is com/google/intelligence/sense/ambientmusic/buffer/
# AudioBufferManager, Lyls is the lambda above, and Lyyx is the trigger object
# every stage consumes. Lyyx has exactly ONE <init> call site in the entire APK,
# inside Lyyx;->b(Landroid/hardware/soundtrigger/SoundTrigger$RecognitionEvent;),
# and its only two callers are Lyyp (extends SoundTriggerDetectionService,
# onGenericRecognitionEvent) and Lyys (a BroadcastReceiver pulling the event out
# of an Intent). SoundTrigger$RecognitionEvent is never constructed inside the
# APK. So the ambient pipeline is hard-gated on the framework delivering a real
# recognition event; this flag only decides where audio comes from *after* one
# arrives. On onyx the session arms and stays inert, no event ever fires, and the
# mic branch is never reached.
#
# Keep the flag regardless: it is correct, free, and a prerequisite for any fix
# to the trigger, since a synthesized event would not need to carry a usable DSP
# capture session if ASI opens its own AudioRecord anyway.
#
# The remaining blocker is tractable only because we build frameworks/base:
# something has to hand ASI a SoundTrigger$RecognitionEvent, and Lyys being a
# plain BroadcastReceiver is the opening. That is a project, not a config change.
#
# WHAT SHOULD ALREADY WORK: on-demand recognition. Lyxx;->d() opens its own
# AudioRecord(1 /* MIC */, 16000, CHANNEL_IN_MONO, PCM_16BIT, 0x3e800) and drives
# android.media.musicrecognition.RecognitionRequest -- MusicRecognitionManager,
# no SoundTrigger anywhere. That is the "identify this song" button, not passive
# detection. Test it before assuming the whole feature is dead.
#
# Cost of the mic path once a trigger exists: a real mic AudioRecord instead of a
# DSP island means the mic privacy indicator stays lit and standby drain worsens.
#
# Confirm the flag actually stuck after a boot -- SimpleDeviceConfig sets it at
# LOCKED_BOOT_COMPLETED with makeDefault=true, which a Phenotype push of the same
# key would still overwrite:
#   adb shell device_config get device_personalization_services \
#       NowPlaying__ambient_music_use_dsp_audio_source
#
# Independently of ASI, the lock screen indicator is driven by the Evolution X
# non-Pixel port (com.android.systemui.nowplaying.ambient, frameworks_base
# 5748e136d), which does NO audio recognition -- it follows MediaSessionManager
# and depends on neither com.google.android.as nor any ambientindication
# broadcast. See patches/frameworks_base/0004-lockscreen-now-playing.patch. That
# port is why the indicator works for music playing *on* the device; ASI is what
# would additionally identify music playing in the room.
#
# The four blobs below ungrey ASI's own Now Playing toggle. On their own, with
# the DSP source still selected, they produce no detections.
# ---------------------------------------------------------------------------
PRODUCT_COPY_FILES += \
    vendor/extra/firmware/music_detector.descriptor:$(TARGET_COPY_OUT_PRODUCT)/etc/firmware/music_detector.descriptor \
    vendor/extra/firmware/music_detector.sound_model:$(TARGET_COPY_OUT_PRODUCT)/etc/firmware/music_detector.sound_model \
    vendor/extra/firmware/music_detector.sound_model_2:$(TARGET_COPY_OUT_PRODUCT)/etc/firmware/music_detector.sound_model_2 \
    vendor/extra/firmware/music_detector.sound_model_tflite:$(TARGET_COPY_OUT_PRODUCT)/etc/firmware/music_detector.sound_model_tflite

# Now Playing, userspace half: the DeviceConfig flags Phenotype withholds.
#
# Shipping the model above is necessary but not sufficient. ASI reads its Now
# Playing config from the DeviceConfig namespace device_personalization_services,
# and Google's Phenotype server only sends part of it to a non-Pixel device: our
# ASI prebuilt references 106 NowPlaying__* flags and we receive 53. One of the
# absentees, ambient_music_index_manifest_17_09_02, is the URL of the song
# database itself, and the APK has no compiled-in fallback for it -- so ASI hung
# on "Downloading song database" indefinitely.
#
# packages/apps/SimpleDeviceConfig (already in PRODUCT_PACKAGES via
# vendor/lineage/config/common.mk) pushes namespace/key=value strings into
# DeviceConfig on every LOCKED_BOOT_COMPLETED. This RRO supplies the device half
# of its list, including the ambient_music_use_dsp_audio_source=false above. See
# rro/SimpleDeviceConfigOverlayOnyx/res/values/config.xml for why the list is
# only four flags long, and how to refresh the corpus version.
PRODUCT_PACKAGES += \
    SimpleDeviceConfigOverlayOnyx
