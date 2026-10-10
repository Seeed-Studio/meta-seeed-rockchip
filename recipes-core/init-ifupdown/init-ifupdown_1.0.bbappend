# Board-specific network bring-up for the reComputer Rockchip devkits.
#
# The stock template marks only eth0 auto, so a cable in eth1 never comes
# up at boot (both devkits expose two ethernet ports).  Override the
# interfaces file to mark both SoC GMACs auto with DHCP: busybox ifup
# runs udhcpc with -b, so a missing carrier just backgrounds the lease
# retry and never stalls boot.  wlan0 stays manual - association needs a
# user-supplied /etc/wpa_supplicant.conf, otherwise the retry loop is
# dead weight; the wpa-supplicant package ships the ifupdown hook that
# associates before udhcpc runs once the file exists.
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
