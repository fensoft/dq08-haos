#!/bin/bash
set -e
set -x
if [ ! -e rkdeveloptool ]; then
  sudo apt-get install -y libudev-dev libusb-1.0-0-dev dh-autoreconf pkg-config libusb-1.0
  git clone https://github.com/rockchip-linux/rkdeveloptool
  cd rkdeveloptool
  autoreconf -i
  ./configure
  make
  cd ..
fi

sudo ./rkdeveloptool/rkdeveloptool wl 16384 dq08_ha_supervised_3.0.0.img.dump/Image/uboot.img
sudo ./rkdeveloptool/rkdeveloptool wl 34816 dq08_ha_supervised_3.0.0.img.dump/Image/boot.img
sudo ./rkdeveloptool/rkdeveloptool wl 561152 dq08_ha_supervised_3.0.0.img.dump/Image/rootfs.img
sudo ./rkdeveloptool/rkdeveloptool rd