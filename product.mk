#
# Personal Evolution X onyx product additions
#

# GApps are Evolution X's own: vendor/lineage/config/common_full_phone.mk
# inherits vendor/gms/gms_full.mk whenever WITH_GMS is true, and true is already
# its default. Stated explicitly anyway because
# vendor/lineage/config/version.mk also reads WITH_GMS -- with it false the
# version string picks up a "-Vanilla" suffix.
#
# That one switch replaces all five PixelOS projects the crDroid build carried
# (vendor/pixel/{gms,launcher,themepicker,clocks,sounds}). vendor_gms ships
# NexusLauncherRelease, SoundPickerPrebuilt, PixelWallpapers2025,
# WallpaperAIPrebuilt, PrebuiltDeskClockGoogle, GoogleDialer and PrebuiltBugle;
# vendor/pixel-style supplies the Pixel RRO set, including
# PixelLauncherNoGestureHintOverlay.
WITH_GMS := true

# The bundled Kono-Ha kernel is runtime-tested on onyx, but it does not expose
# every Android kernel FCM config that check_vintf expects.
PRODUCT_OTA_ENFORCE_VINTF_KERNEL_REQUIREMENTS := false

# Local privileged-permission allowlist.
#
# Kept even though vendor_gms ships PrebuiltDeskClockGoogle
# (com.google.android.deskclock): Lineage's common_mobile_full.mk still brings
# AOSP DeskClock (com.android.deskclock) along, and without these two entries the
# privapp allowlist check is fatal at build time. An allowlist entry for a
# package that is not installed is simply ignored, so this is safe either way.
PRODUCT_COPY_FILES += \
    vendor/extra/permissions/product/privapp-permissions-com.android.deskclock.xml:$(TARGET_COPY_OUT_PRODUCT)/etc/permissions/privapp-permissions-com.android.deskclock.xml

# GONE, and why
#
#   ro.crdroid.maintainer / ro.crdroid.donate.url
#       crDroid's Settings looked the maintainer up in its OTA index by codename
#       and would have credited onyx's official maintainer on an unofficial
#       build. Evolution X's Settings has no maintainer preference at all -- the
#       name only ever appears in the OTA JSON that vendor_evolution's
#       build/tools/createjson.py fetches server-side for official builds -- so
#       there is nothing left to spoof.
#
#   Unofficial build type
#       vendor/lineage/config/version.mk already does EVO_BUILD_TYPE ?= Unofficial,
#       so unofficial is the default and needs no help.
#
#   PRODUCT_SOURCE_ROOT_DIRS += -vendor/addons/themes/SystemUIClocks
#       Excluded crDroid's stock clock prebuilts so PixelOS could provide the
#       same module names. Both sides of that collision are gone.
#
#   WITH_GMS_COMMS_SUITE := false, plus Dialer and PrebuiltBugle
#       PixelOS variables and packages. vendor_gms ships GoogleDialer and
#       PrebuiltBugle itself.
#
#   privapp-permissions-com.loukious.pixellauncher.gesturehint.xml
#       Belonged to PixelLauncherGestureHintController, which is gone: Evo ships
#       PixelLauncherNoGestureHintOverlay in vendor/pixel-style and toggles it
#       straight from GestureNavigationSettingsFragment's navigation_bar_hint
#       preference.
