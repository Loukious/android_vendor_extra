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

