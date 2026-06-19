FILESEXTRAPATHS:prepend:mender-uboot := "${THISDIR}/files:${THISDIR}/files/${TORADEX_BSP_VERSION}:"

include ${@mender_feature_is_enabled("mender-uboot","recipes-bsp/u-boot/u-boot-mender.inc","",d)}

MENDER_UBOOT_AUTO_CONFIGURE:mender-uboot = "0"
BOOTENV_SIZE:mender-uboot = "0x2000"
MENDER_UBOOT_CONFIG_SYS_MMC_ENV_PART:mender-uboot = "1"
MENDER_UBOOT_ENV_STORAGE_DEVICE_OFFSET:mender-uboot = "0xFFFFDE00"
MENDER_UBOOT_ENV_STORAGE_DEVICE_OFFSET_2:mender-uboot = "0xFFFFBE00"
MENDER_RESERVED_SPACE_BOOTLOADER_DATA:mender-uboot:colibri-imx6ull ="0x40000"
BOOTENV_SIZE:mender-uboot:colibri-imx6ull = "0x20000"

PROVIDES += "${@mender_feature_is_enabled("mender-uboot","u-boot-default-env","",d)}"
PROVIDES += "${@mender_feature_is_enabled("mender-uboot","u-boot","",d)}"
RPROVIDES:${PN} += "${@mender_feature_is_enabled("mender-uboot","u-boot","",d)}"
PROVIDES += "${@mender_feature_is_enabled("mender-uboot","u-boot-default-env","",d)}"

# Apply custom patches for Toradex u-boot
SRC_URI:append:mender-uboot = " \
    file://0001-configs-toradex-board-specific-mender-integration.patch \
    file://0001-Use-mender_dtb_name-for-fdtfile.patch \
"
SRC_URI:append:mender-uboot:colibri-imx6ull = " \
    ${@bb.utils.contains("IMAGE_FEATURES", "read-only-rootfs", "file://0002-use-read-only-rootfs.patch", "",d)}"

# Use the Toradex specific version of this patch
SRC_URI:remove:mender-uboot = " file://0002-Integration-of-Mender-boot-code-into-U-Boot.patch "
SRC_URI:append:mender-uboot = " file://0002-Integration-of-Mender-boot-code-into-U-Boot-fix.patch "

do_deploy:append:mender-uboot() {
    cat > ${DEPLOYDIR}/fw_env.config.default <<EOF
${MENDER_UBOOT_MMC_ENV_LINUX_DEVICE_PATH} -0x2200 ${BOOTENV_SIZE}
${MENDER_UBOOT_MMC_ENV_LINUX_DEVICE_PATH} -0x4200 ${BOOTENV_SIZE}
EOF
}
