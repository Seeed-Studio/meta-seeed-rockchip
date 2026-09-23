SUMMARY = "Host-side Bluetooth attach service for the AIC8800D80 combo"
DESCRIPTION = "Opens both rfkill gates of the AIC8800D80 WiFi/BT combo and \
attaches its H4 controller on the board's Bluetooth UART, so hci0 appears \
and the stock balenaOS stack takes over (udev 99-systemd.rules -> \
bluetooth.target -> bluetoothd with AutoEnable=true).  Deliberately does \
not pull in bluetooth.service itself: the Armbian aic8800 units that \
Requires=/Wants= bluetooth.service either start bluetoothd before any \
controller exists or risk ordering loops."
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = "file://aic8800-bt-attach \
           file://aic8800-bt.service \
           file://aic8800-bt.conf \
           "

# Board wiring of the combo's Bluetooth UART: tty name plus the DT node the
# tty must be backed by (runtime cross-check, so an alias change fails
# loudly instead of as an HCI timeout).  The serialN aliases in the vendor
# SoC dtsi pin the tty number: rk3588 wires uart6 (feb90000.serial) ->
# ttyS6, rk3576 wires uart4 (2ad70000.serial) -> ttyS4.  New machines must
# pick explicitly - the anonymous python check below fails the parse
# otherwise.
AIC8800_BT_TTY ??= ""
AIC8800_BT_UART_NODE ??= ""
AIC8800_BT_TTY:recomputer-rk3588-devkit = "ttyS6"
AIC8800_BT_UART_NODE:recomputer-rk3588-devkit = "feb90000.serial"
AIC8800_BT_TTY:recomputer-rk3576-devkit = "ttyS4"
AIC8800_BT_UART_NODE:recomputer-rk3576-devkit = "2ad70000.serial"

inherit systemd

# Content differs per machine via the overrides above.
PACKAGE_ARCH = "${MACHINE_ARCH}"

SYSTEMD_SERVICE:${PN} = "aic8800-bt.service"

python () {
    if not d.getVar("AIC8800_BT_TTY") or not d.getVar("AIC8800_BT_UART_NODE"):
        bb.fatal("aic8800-bt: AIC8800_BT_TTY/AIC8800_BT_UART_NODE unset for MACHINE '%s'" % d.getVar("MACHINE"))
}

do_install() {
    install -D -m 0755 ${UNPACKDIR}/aic8800-bt-attach ${D}${sbindir}/aic8800-bt-attach

    install -d ${D}${systemd_system_unitdir}
    sed -e "s,@TTY@,${AIC8800_BT_TTY},g" \
        -e "s,@UART_NODE@,${AIC8800_BT_UART_NODE},g" \
        -e "s,@SBINDIR@,${sbindir},g" \
        ${UNPACKDIR}/aic8800-bt.service \
        > ${D}${systemd_system_unitdir}/aic8800-bt.service

    install -D -m 0644 ${UNPACKDIR}/aic8800-bt.conf \
        ${D}${nonarch_base_libdir}/modules-load.d/aic8800-bt.conf
}

# Default FILES:${PN} does not cover modules-load.d under /lib.
FILES:${PN} += "${nonarch_base_libdir}/modules-load.d"

# aic8800_btlpm ships in aic8800-driver (no modalias, must be loaded by
# modules-load.d); hciattach ships in the bluez5 main package (PACKAGECONFIG
# "tools"+"deprecated"; meta-balena only splits *test/btmon/l2ping/mpris-proxy out).
RDEPENDS:${PN} += "aic8800-driver bluez5"
