# CI-only trim, gated by CI_MINIMAL_IMAGE (barys "-a CI_MINIMAL_IMAGE=1").
# None of these wireless firmwares match hardware on the Seeed Rockchip
# boards; they are pulled in from meta-balena-common and its wrynose
# bbappend. The boards' onboard aic8800 WiFi/BT is trimmed separately in
# recipes-core/images/balena-image.bbappend; wired ethernet (PCIe RTL8125,
# linux-firmware-rtl-nic) is untouched.

CI_TRIM_CONNECTIVITY_FIRMWARES = " \
    linux-firmware-ath9k \
    linux-firmware-mt7601u \
    linux-firmware-ralink \
    linux-firmware-rtl8192cu \
    linux-firmware-rtl8192su \
    linux-firmware-rtl8723 \
    linux-firmware-rtl8723b-bt \
    linux-firmware-bcm43143 \
    linux-firmware-iwlwifi-135-6 \
    linux-firmware-iwlwifi-3160 \
    linux-firmware-iwlwifi-6000-4 \
    linux-firmware-iwlwifi-6000g2a-6 \
    linux-firmware-iwlwifi-6000g2b-6 \
    linux-firmware-iwlwifi-6050-5 \
    linux-firmware-iwlwifi-7260 \
    linux-firmware-iwlwifi-7265 \
    linux-firmware-iwlwifi-7265d \
    linux-firmware-iwlwifi-8000c \
    linux-firmware-iwlwifi-8265 \
    linux-firmware-iwlwifi-9260 \
    linux-firmware-rtl8188eu \
    linux-firmware-wl12xx \
    linux-firmware-wl18xx \
    wireless-regdb-static \
"

CONNECTIVITY_FIRMWARES:remove = "${@'${CI_TRIM_CONNECTIVITY_FIRMWARES}' if d.getVar('CI_MINIMAL_IMAGE') == '1' else ''}"
