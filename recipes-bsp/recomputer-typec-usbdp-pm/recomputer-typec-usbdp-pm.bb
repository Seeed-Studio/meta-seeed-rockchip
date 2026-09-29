SUMMARY = "Keep the RK3576 Type-C dwc3 controller out of runtime suspend"
DESCRIPTION = "The RK3576 Type-C port's dwc3 (23000000.usb) shares the USBDP \
combo PHY with the DP display controller.  With the vendor default runtime-PM \
autosuspend (power/control = auto), unplugging a DP alt-mode partner can race \
the xHCI bus suspend into an asynchronous SError (xhci_bus_suspend) and panic \
the kernel.  This package installs a udev rule that pins the controller to \
always-on, mirroring what the vendor runtime already does for the board's \
other dwc3 (23400000.usb).  The rule matches only the RK3576 controller \
address and is a no-op elsewhere."
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = "file://75-recomputer-typec-usbdp-pm.rules"

do_install() {
    install -D -m 0644 ${UNPACKDIR}/75-recomputer-typec-usbdp-pm.rules \
        ${D}${nonarch_base_libdir}/udev/rules.d/75-recomputer-typec-usbdp-pm.rules
}

FILES:${PN} += "${nonarch_base_libdir}/udev/rules.d/75-recomputer-typec-usbdp-pm.rules"
