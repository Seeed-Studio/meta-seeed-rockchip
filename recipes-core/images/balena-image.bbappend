# CI-only image trim, gated by CI_MINIMAL_IMAGE (injected via barys
# "-a CI_MINIMAL_IMAGE=1" from .github/workflows/seeed-balenaos.yml).
# Drops camera/multimedia/onboard-WiFi userspace so the scheduled CI build
# stays well under the runner time limit. The resulting image boots but has
# no camera, video acceleration or WiFi/BT — it is NOT a shippable product
# image; release builds (yocto-build-deploy) never set the variable.

CI_TRIM_PACKAGES = " \
    rockchip-rkaiq-server \
    rockchip-rkaiq-iqfiles \
    rockchip-rkisp-server \
    rockchip-rkisp-iqfiles \
    rockchip-mpp \
    gstreamer1.0-rockchip \
    gstreamer1.0-plugins-base \
    gstreamer1.0-plugins-good-jpeg \
    gstreamer1.0-plugins-good-video4linux2 \
    v4l-utils \
    media-ctl \
    aic8800-firmware \
    aic8800-driver \
    aic8800-bt \
"

IMAGE_INSTALL:remove = "${@'${CI_TRIM_PACKAGES}' if d.getVar('CI_MINIMAL_IMAGE') == '1' else ''}"
