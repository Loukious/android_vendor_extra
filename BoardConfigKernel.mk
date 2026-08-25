#
# Personal onyx kernel override.
# Kono-Ha 1.1 with KernelSU Next.
#
# Since crdroidandroid/android_device_xiaomi_onyx 575e7da99 ("onyx: Switch
# source built dtbo, kernel and modules") the device tree no longer ships a
# prebuilt kernel, so there is no PRODUCT_COPY_FILES entry left to filter out.
# The kernel source at $(TARGET_KERNEL_SOURCE) still has to be built, because
# that is what produces every vendor module (mi_fp, si_haptic, the QCOM
# external modules) and the dtb/dtbo images -- Kono-Ha is a generic CLO GKI
# tree and carries none of those Xiaomi drivers.
#
# So build the kernel normally and swap only the installed Image. This is the
# same arrangement that boots today: Kono-Ha's GKI Image alongside vendor
# modules built against Xiaomi's kernel.
#
# Deliberately NOT using TARGET_FORCE_PREBUILT_KERNEL: that sets
# FULL_KERNEL_BUILD := false, which skips module and dtbo generation entirely
# (vendor/lineage/build/tasks/kernel.mk, the FULL_KERNEL_BUILD blocks) and
# would yield an unbootable Image-only build. TARGET_OVERRIDE_KERNEL_BIN is
# added by patches/vendor_lineage/0002-kernel-bin-override.patch.

TARGET_OVERRIDE_KERNEL_BIN := vendor/extra/kernel/onyx/Image
