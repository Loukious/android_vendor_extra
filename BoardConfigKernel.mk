#
# Personal onyx kernel override.
# Kono-Ha 1.1 with KernelSU Next.
#
# HOW THE SUBSTITUTION WORKS
#
# device/xiaomi/onyx builds the kernel from source -- BoardConfig.mk sets
# TARGET_KERNEL_SOURCE := kernel/xiaomi/sm8735 and there is no prebuilt under a
# PREBUILT_PATH any more (that changed in device commit 575e7da99, "onyx: Switch
# source built dtbo, kernel and modules"). The source build still has to happen:
# it is what produces the vendor modules (mi_fp, si_haptic, the QCOM external
# modules) and the dtb/dtbo images. Only the kernel binary is ours.
#
# So the swap goes through TARGET_OVERRIDE_KERNEL_BIN, which
# patches/vendor_lineage/0002-kernel-bin-override.patch adds to
# vendor/lineage/build/tasks/kernel.mk (vendor_evolution under Evolution X). It
# reassigns KERNEL_BIN immediately before
#
#     ifeq ($(NEEDS_KERNEL_COPY),true)
#     $(INSTALLED_KERNEL_TARGET): $(KERNEL_BIN)
#
# so it changes only the binary copied to $(PRODUCT_OUT)/kernel. Every module
# and device-tree rule above that point still consumes
# TARGET_PREBUILT_INT_KERNEL and is untouched.
#
# Deliberately NOT using TARGET_FORCE_PREBUILT_KERNEL: that sets
# FULL_KERNEL_BUILD := false, which would skip module and dtbo generation
# entirely.
#
# The override block sits inside kernel.mk's
# `ifneq ($(TARGET_NO_KERNEL_OVERRIDE),true)` region (line 106 to 838 on
# vendor_evolution bka). The onyx device tree does not set that variable, so the
# region is live. If it ever starts setting it, the block goes dark and the
# guarded PRODUCT_COPY_FILES fallback at the bottom of this file takes over.
#

# Fail loudly rather than silently shipping the tree's own kernel -- that is the
# exact bug this file exists to prevent, and it has happened before.
ifeq ($(wildcard vendor/extra/kernel/onyx/Image),)
$(error vendor/extra/kernel/onyx/Image is missing. Run crdroid_onyx_patches/apply.sh to stage the Kono-Ha kernel before building.)
endif

TARGET_OVERRIDE_KERNEL_BIN := vendor/extra/kernel/onyx/Image

# Fallback for a device tree that goes back to shipping a prebuilt kernel, which
# it would install with a plain
#     PRODUCT_COPY_FILES += $(PREBUILT_PATH)/images/kernel:kernel
# bypassing $(INSTALLED_KERNEL_TARGET) and therefore KERNEL_BIN entirely.
#
# Guarded on PREBUILT_PATH because with a source-built kernel both this entry and
# $(INSTALLED_KERNEL_TARGET) would write $(PRODUCT_OUT)/kernel, and two rules for
# one output is a hard ninja error.
ifneq ($(PREBUILT_PATH),)
PRODUCT_COPY_FILES := \
    $(filter-out $(PREBUILT_PATH)/images/kernel:kernel,$(PRODUCT_COPY_FILES))
PRODUCT_COPY_FILES += \
    vendor/extra/kernel/onyx/Image:kernel
endif
