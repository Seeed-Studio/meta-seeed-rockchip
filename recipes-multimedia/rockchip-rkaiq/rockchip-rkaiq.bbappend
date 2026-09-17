# Copyright (C) 2026 Seeed Studio
# Released under the MIT license (see COPYING.MIT for the terms)
#
# Rebuild the rkaiq 3A stack from a newer source snapshot: the recipe's
# pinned mirrors rkaiq-2024_04_08 tree (AIQ v6.0x6.1) cannot parse the
# current sensor calibrations - newer iq files such as
# imx708_rpi-camera-v3 crash rk_aiq_uapi2_sysctl_init with SIGSEGV.
# SRCREV below pins Seeed's deb_source import of the v6.0x8.0 (2024-09)
# snapshot, the exact tree their camera-engine-rkaiq-rk3576 deb was
# built from.  Newer snapshots (v6.0x31+) need 2025 BSP kernels (CAC
# mesh ioctl) and crash on our 6.1 kernel.
#
# The vendored server wrapper (files/server/, same Seeed branch) adds
# the sensor-less-seat guards the stock server lacks on the RK3576
# dual virtual-ISP topology; it compiles against the tree's own
# headers (this snapshot ships xcam_log as plain C with the
# 3-argument xcam_print_log).  The engine lives in the
# camera_engine_rkaiq/ subdirectory of the extension repository, and
# local-git checks out under ${UNPACKDIR}/rockchip-rkaiq-1.0/, hence
# the S override.
#
# rkaiq-3a.service ships here for systemd distros without a
# sysv-generator, which never run upstream's
# /etc/init.d/rkaiq_daemons.sh (the systemd class keeps the unit
# inert on sysv builds).

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI = " \
    git://github.com/Seeed-Studio/seeed_armbian_extension.git;protocol=https;branch=deb_source \
    file://rkaiq_daemons.sh \
    file://server/rkaiq_3A_server.cpp \
    file://iqfiles \
    file://rkaiq-3a.service \
    file://0002-rkaiq-replace-mmap64-with-mmap-for-non-LFS-builds.patch \
"
SRCREV = "6ca4c304c4c91df3905e54b484cf25d165c74352"
S = "${UNPACKDIR}/rockchip-rkaiq-1.0/camera_engine_rkaiq"

SRCSRVR = "${UNPACKDIR}/server"

do_compile:append() {
    # The vendored wrapper plus the two support translation units from
    # ${S}, so every TU matches the tree's headers.  The -I set
    # mirrors the rkaiq_3A_server CMake include list.
    LIBDIR="$(dirname "$(find ${B} -name 'librkaiq.so' | head -n1)")"
    INC=" \
        -I${S}/rkaiq/include \
        -I${S}/rkaiq/include/uAPI2 \
        -I${S}/rkaiq/include/common \
        -I${S}/rkaiq/include/common/mediactl \
        -I${S}/rkaiq/include/algos \
        -I${S}/rkaiq/include/isp \
        -I${S}/rkaiq/include/iq_parser \
        -I${S}/rkaiq/include/iq_parser_v2 \
        -I${S}/rkaiq/include/xcore \
        -I${S}/rkaiq/include/xcore/base \
        -I${S}/rkaiq_3A_server/common/mediactl \
        -I${S}/rkaiq_3A_server \
        -I${S}/rkaiq \
        -I${S}/rkaiq/common/mediactl \
        -I${S}/rkaiq/xcore \
        -I${S}/rkaiq/xcore/base \
    "
    ${CC} ${CFLAGS} -DADD_RK_AIQ -D_DEFAULT_SOURCE -std=gnu11 ${INC} \
        -include sys/time.h -c \
        ${S}/rkaiq/common/mediactl/mediactl.c -o ${B}/mediactl.mirrors.o
    ${CC} ${CFLAGS} -DADD_RK_AIQ -D_DEFAULT_SOURCE -std=gnu11 ${INC} \
        -include sys/time.h -c \
        ${S}/rkaiq/xcore/xcam_log.c -o ${B}/xcam_log.mirrors.o
    ${CXX} ${CXXFLAGS} -DADD_RK_AIQ -std=c++11 ${INC} -c \
        ${SRCSRVR}/rkaiq_3A_server.cpp -o ${B}/rkaiq_3A_server.seeed.o
    ${CXX} ${LDFLAGS} \
        ${B}/rkaiq_3A_server.seeed.o ${B}/mediactl.mirrors.o \
        ${B}/xcam_log.mirrors.o -o ${B}/rkaiq_3A_server.seeed \
        -L${LIBDIR} -lrkaiq -lpthread -ldl -lm
}

do_install:append() {
    # Guarded wrapper over meta-rockchip's binary.
    install -m 0755 ${B}/rkaiq_3A_server.seeed ${D}${bindir}/rkaiq_3A_server

    # systemd unit, see header comment.
    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${UNPACKDIR}/rkaiq-3a.service \
        ${D}${systemd_system_unitdir}/

    # Board sensor calibrations (the DTS declares imx708@1a and
    # imx219@10 on both camera connectors) - the v6.0x8.0 tree ships
    # neither.  Drop additional sensors into files/iqfiles/ as the DTS
    # grows support for them.
    install -m 0644 ${UNPACKDIR}/iqfiles/*.json \
        ${D}${sysconfdir}/iqfiles/
}

inherit systemd
SYSTEMD_PACKAGES = "${PN}-server"
SYSTEMD_SERVICE:${PN}-server = "rkaiq-3a.service"
SYSTEMD_AUTO_ENABLE:${PN}-server = "enable"

# The hand-compiled wrapper embeds ${UNPACKDIR}/${B} paths in its
# DWARF; relax buildpaths QA like Seeed's original recipe did.
INSANE_SKIP:${PN}-dbg += "buildpaths"
INSANE_SKIP:${PN}-server += "buildpaths"
