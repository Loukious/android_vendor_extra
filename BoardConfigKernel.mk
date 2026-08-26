#
# Personal onyx kernel override.
# Kono-Ha 1.1 with KernelSU Next.
#
# HISTORY / WHY THIS LOOKS THE WAY IT DOES
#
# An earlier version of this file relied solely on TARGET_OVERRIDE_KERNEL_BIN
# (added by patches/vendor_lineage/0002-kernel-bin-override.patch) on the theory
# that the device tree no longer ships a prebuilt kernel. That theory was wrong,
# and the resulting build silently shipped crDroid's kernel instead of ours --
# no error, no warning, just the wrong Image inside boot.img.
#
# Two independent reasons it failed, both still true today:
#
#   1. device/xiaomi/onyx/BoardConfig.mk sets TARGET_NO_KERNEL_OVERRIDE := true.
#      In vendor/lineage/build/tasks/kernel.mk that opens an
#      `ifneq ($(TARGET_NO_KERNEL_OVERRIDE),true)` at line 106 which does not
#      close until line 810. The TARGET_OVERRIDE_KERNEL_BIN block lives at ~790,
#      i.e. *inside* the skipped region, so nothing ever reads the variable.
#
#   2. The kernel does not arrive via $(INSTALLED_KERNEL_TARGET) at all. It is a
#      plain PRODUCT_COPY_FILES entry in BoardConfig.mk:
#          PRODUCT_COPY_FILES += $(PREBUILT_PATH)/images/kernel:kernel
#      which copies crDroid's prebuilt straight to $(PRODUCT_OUT)/kernel, and
#      that is what boot.img is assembled from.
#
# So the substitution has to happen at the PRODUCT_COPY_FILES level. This file is
# `-include`d from BoardConfig.mk:265, well after the entry is added at :110, so
# filter-out can see it.
#
# TARGET_OVERRIDE_KERNEL_BIN is kept as belt-and-braces: if the device tree ever
# goes back to source-built kernels it will drop both TARGET_NO_KERNEL_OVERRIDE
# and the PRODUCT_COPY_FILES entry, at which point the filter-out below becomes a
# no-op and the kernel.mk hook takes over instead.
#
# Deliberately NOT using TARGET_FORCE_PREBUILT_KERNEL: it sets
# FULL_KERNEL_BUILD := false, which would skip module and dtbo generation. Not
# that it matters while TARGET_NO_KERNEL_OVERRIDE is set (modules and dtbo are
# themselves prebuilts under $(PREBUILT_PATH)), but it would matter the moment
# that changes.
#

# Fail loudly rather than silently shipping crDroid's kernel -- that is the exact
# bug this file exists to prevent.
ifeq ($(wildcard vendor/extra/kernel/onyx/Image),)
$(error vendor/extra/kernel/onyx/Image is missing. Run crdroid_onyx_patches/apply.sh to stage the Kono-Ha kernel before building.)
endif

# 1. Drop crDroid's prebuilt kernel copy, 2. substitute ours.
PRODUCT_COPY_FILES := \
    $(filter-out $(PREBUILT_PATH)/images/kernel:kernel,$(PRODUCT_COPY_FILES))
PRODUCT_COPY_FILES += \
    vendor/extra/kernel/onyx/Image:kernel

# Inert while TARGET_NO_KERNEL_OVERRIDE is true; see the comment above.
TARGET_OVERRIDE_KERNEL_BIN := vendor/extra/kernel/onyx/Image
