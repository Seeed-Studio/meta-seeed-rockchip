# Copyright (C) 2026 Seeed Studio
# Released under the MIT license (see COPYING.MIT for the terms)
#
# Camera 3A stack for the reComputer Rockchip boards, on top of the
# meta-rockchip recipe:
#
#  (1) Newer engine snapshot.  The recipe's pinned mirrors rkaiq-2024_04_08
#      tree (AIQ v6.0x6.1) cannot parse the sensor calibrations this layer
#      ships - imx708_rpi-camera-v3 crashes rk_aiq_uapi2_sysctl_init with
#      SIGSEGV on scene lookup.  SRCREV pins Seeed's deb_source import of
#      the v6.0x8.0 (2024-09) snapshot, the tree their
#      camera-engine-rkaiq debs are built from.  Newer snapshots (v6.0x31+)
#      need 2025 BSP kernels (CAC mesh ioctl) and crash on the 6.1 kernel.
#
#  (2) systemd integration.  Upstream ships a SysV init script only, and
#      BalenaOS has no systemd-sysv-generator, so rkaiq_3A_server never
#      autostarts.  The unit installed here keeps the daemon running; the
#      systemd class removes the SysV script (rm_sysvinit_initddir), so
#      only one instance can ever race for the media devices.
#
#  (3) Board sensor calibrations.  The tree's per-ISP iqfiles sets miss
#      this board's Pi cameras (imx708 v3, imx219 v2); the IQ profiles
#      here are byte-identical to the files Seeed's deb installs, and to
#      the calibration verified on the reComputer RK3588 DevKit (the
#      container-side capture test used the same bytes).  The scene key
#      is per ISP generation - isp3x (RK3588) reads scene_isp30, isp39
#      (RK3576) scene_isp39 - so pick the matching file.
#
# The stock tree cmake builds and installs rkaiq_3A_server itself; no
# hand-compiled wrapper is needed.  The camera seats stay disabled in the
# base DT and are enabled by the dt-overlays choice, so with no overlay
# applied there is no media device to bind and the server simply exits
# until a camera is enabled.

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI = " \
    git://github.com/Seeed-Studio/seeed_armbian_extension.git;protocol=https;branch=deb_source \
    file://rkaiq_daemons.sh \
    file://rkaiq_3A.service \
    file://0002-rkaiq-replace-mmap64-with-mmap-for-non-LFS-builds.patch \
    file://iqfiles/imx708_rpi-camera-v3_default-isp3x.json \
    file://iqfiles/imx708_rpi-camera-v3_default-isp39.json \
    file://iqfiles/imx219_rpi-camera-v2_default-isp39.json \
"
SRCREV = "6ca4c304c4c91df3905e54b484cf25d165c74352"
S = "${UNPACKDIR}/rockchip-rkaiq-1.0/camera_engine_rkaiq"

# --- (2) systemd integration --------------------------------------------
inherit systemd

SYSTEMD_PACKAGES = "${PN}-server"
SYSTEMD_SERVICE:${PN}-server = "rkaiq_3A.service"
SYSTEMD_AUTO_ENABLE:${PN}-server = "enable"

do_install:append() {
    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${UNPACKDIR}/rkaiq_3A.service \
        ${D}${systemd_system_unitdir}/rkaiq_3A.service

    # --- (3) board sensor calibrations ----------------------------------
    if [ "${RK_SOC_FAMILY}" = "rk3576" ]; then
        install -m 0644 \
            ${UNPACKDIR}/iqfiles/imx708_rpi-camera-v3_default-isp39.json \
            ${D}${sysconfdir}/iqfiles/imx708_rpi-camera-v3_default.json
        install -m 0644 \
            ${UNPACKDIR}/iqfiles/imx219_rpi-camera-v2_default-isp39.json \
            ${D}${sysconfdir}/iqfiles/imx219_rpi-camera-v2_default.json
    else
        install -m 0644 \
            ${UNPACKDIR}/iqfiles/imx708_rpi-camera-v3_default-isp3x.json \
            ${D}${sysconfdir}/iqfiles/imx708_rpi-camera-v3_default.json
    fi
}

# The unit lands under /usr/lib/systemd/system (usrmerge), and the
# upstream FILES:${PN} glob ("/usr/lib") claims it before the -server
# package gets a turn (PACKAGES order: PN first, -server appended last).
# FILES:remove cannot punch a hole into a directory glob, so narrow the
# main package claim instead; the systemd class appends the unit path to
# FILES:-server itself, which then wins it.
FILES:${PN} = " \
    ${libdir}/librkaiq.so* \
    ${libdir}/libIspFec.so* \
    ${libdir}/libsmartIr.so* \
    ${libdir}/librkrawstream.so* \
    ${datadir} \
"
