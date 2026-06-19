_MENDER_BOOTLOADER_DEFAULT = "mender-uboot"
_MENDER_IMAGE_TYPE_DEFAULT = ""

inherit mender-full

MENDER_BOOT_PART_SIZE_MB = "0"
MENDER_DATA_PART_FSTYPE = "ext4"

# The signed FIT contains the dm-verity-aware initramfs. Store one FIT per
# rootfs slot on a shared boot filesystem and switch the pair through
# mender_boot_part.
TORADEX_MENDER_BOOTFIT_PART_SIZE_MB ?= "64"
TORADEX_MENDER_BOOTFIT_PART_NUMBER = "1"
TORADEX_MENDER_BOOTFIT_PART = "${MENDER_STORAGE_DEVICE_BASE}${TORADEX_MENDER_BOOTFIT_PART_NUMBER}"
MENDER_ROOTFS_PART_A_NUMBER = "2"
MENDER_ROOTFS_PART_B_NUMBER = "3"
MENDER_DATA_PART_NUMBER = "4"

# mender-setup-install normally budgets only A/B rootfs and data when no
# standard Mender boot partition is enabled. Reserve the FIT filesystem too.
MENDER_CALC_ROOTFS_SIZE = "${@mender_calculate_rootfs_size_kb(${MENDER_STORAGE_TOTAL_SIZE_MB}, \
                                                              ${TORADEX_MENDER_BOOTFIT_PART_SIZE_MB}, \
                                                              ${MENDER_DATA_PART_SIZE_MB}, \
                                                              ${MENDER_SWAP_PART_SIZE_MB}, \
                                                              ${MENDER_PARTITION_ALIGNMENT}, \
                                                              ${MENDER_PARTITIONING_OVERHEAD_KB}, \
                                                              ${MENDER_EXTRA_PARTS_TOTAL_SIZE_MB}, \
                                                              ${MENDER_RESERVED_SPACE_BOOTLOADER_DATA})}"

ARTIFACTIMG_FSTYPE:tdx-signed-dmverity = "${DM_VERITY_IMAGE_TYPE}.verity"
TORADEX_MENDER_DM_VERITY_OVERHEAD_KB:tdx-signed-dmverity ?= "65536"
MENDER_IMAGE_ROOTFS_SIZE_DEFAULT:tdx-signed-dmverity = "${@eval('${MENDER_CALC_ROOTFS_SIZE} - (${IMAGE_ROOTFS_EXTRA_SPACE}) - (${TORADEX_MENDER_DM_VERITY_OVERHEAD_KB})')}"

IMAGE_BOOT_FILES:remove = "boot.scr boot.scr-${MACHINE};boot.scr boot.scr-${MACHINE} boot.scr-verdin-imx8mm;boot.scr boot.scr-verdin-imx8mp;boot.scr"

ROOTFS_POSTPROCESS_COMMAND:append = " toradex_mender_update_fstab_file;"
toradex_mender_update_fstab_file() {
    # the Toradex BSP sets up a symlink called /dev/boot-part which is added to FSTAB.
    # The logic to determine which device node is the boot partition fails with the Mender
    # partitioning and when using Grub, systemd will fail to boot and drop to maintenance
    # mode.  Since Mender already has logic to mount this partition at /uboot we just want
    # to remove the line from fstab that mounts /dev/boot-part
    grep -v /dev/boot-part ${IMAGE_ROOTFS}${sysconfdir}/fstab > ${IMAGE_ROOTFS}${sysconfdir}/fstab.toradex
    mv ${IMAGE_ROOTFS}${sysconfdir}/fstab.toradex ${IMAGE_ROOTFS}${sysconfdir}/fstab
}

ROOTFS_POSTPROCESS_COMMAND:append = " toradex_mender_update_devicetree_overlays;"
toradex_mender_update_devicetree_overlays() {
    # the Toradex BSP uses Device Tree overlays which are normally populated to the boot
    # partition using WIC and bootimg-partition types. Since Mender does not use that partition
    # type we have to account for that here. We want it in a POSTPROCESS_COMMAND so that it
    # applies to all images
    cp ${DEPLOY_DIR_IMAGE}/overlays.txt ${IMAGE_ROOTFS}/boot/overlays.txt
    cp -R ${DEPLOY_DIR_IMAGE}/overlays/ ${IMAGE_ROOTFS}/boot/overlays
}

addhandler mender_tezi_sanity_handler
mender_tezi_sanity_handler[eventmask] = "bb.event.ParseCompleted"
python mender_tezi_sanity_handler() {
  menderOffset = d.getVar("MENDER_IMAGE_BOOTLOADER_BOOTSECTOR_OFFSET")
  bootromPayload = d.getVar("OFFSET_BOOTROM_PAYLOAD")
  if (menderOffset != None) and (bootromPayload != None) and (menderOffset != bootromPayload):
    bb.fatal("Error.  MENDER_IMAGE_BOOTLOADER_BOOTSECTOR_OFFSET (%s) != OFFSET_BOOTROM_PAYLOAD (%s)" % \
             (d.getVar("MENDER_IMAGE_BOOTLOADER_BOOTSECTOR_OFFSET"), d.getVar("OFFSET_BOOTROM_PAYLOAD")))
}

PREFERRED_RPROVIDER_u-boot-default-env = "u-boot-toradex"

TORADEX_BSP_VERSION ??= "toradex-bsp-7.6.0"
MACHINEOVERRIDES =. "${TORADEX_BSP_VERSION}:"
