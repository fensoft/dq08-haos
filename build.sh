#!/bin/bash
set -x
set -e
if [ ! -e rk3528-tvbox ]; then
  git clone https://github.com/ilyakurdyukov/rk3528-tvbox.git
fi
cd rk3528-tvbox
git stash
patch devicetree/orig/rk3528.dtsi < ../dt_i2c.patch
cp ../uboot-new-gcc.patch armbian-patch/patch/u-boot/legacy/board_rk3528-tvbox
if [ ! -e armbian-build ]; then
  git clone --depth=1 https://github.com/armbian/build armbian-build
fi
cp -R armbian-patch/* armbian-build/
cd armbian-build
cat <<EOF >> config/kernel/linux-rk3528-tvbox-legacy.config
CONFIG_USB_SERIAL=y
CONFIG_USB_SERIAL_SIMPLE=y
CONFIG_USB_SERIAL_CH341=y
CONFIG_USB_SERIAL_CP210X=y
CONFIG_USB_SERIAL_FTDI_SIO=y
CONFIG_USB_SERIAL_PL2303=y
EOF
mkdir -p userpatches/extensions
# for i in ha docker-ce; do
#   curl https://raw.githubusercontent.com/armbian/os/refs/heads/main/userpatches/extensions/$i.sh > userpatches/extensions/$i.sh
# done
# ENABLE_EXTENSIONS=ha
./compile.sh build BOARD=rk3528-tvbox BRANCH=legacy BUILD_DESKTOP=no BUILD_MINIMAL=yes EXPERT=yes KERNEL_CONFIGURE=no KERNEL_GIT=shallow RELEASE=bookworm PACKAGE_LIST_BOARD="i2c-tools gettext-base unzip gdisk"
cd ../..
cat <<EOF > rk3528-tvbox/build.sh
#!/bin/bash
set -e
set -x
cd /build
IMAGE=\`ls /build/armbian-build/output/images/*.img\`
losetup -D
DEVICE=\`losetup -f\`
losetup --partscan \$DEVICE \$IMAGE
mount \${DEVICE}p1 /mnt
cd devicetree
cp orig/*.dtsi .
patch -p1 -i rk3528-tvbox.patch
make NAME=rk3528-vontar-dq08 PRESET=LINUX
cp rk3528-vontar-dq08.dtb /mnt/dtb/rockchip
sed "s#fdtfile=.*#fdtfile=rockchip/rk3528-vontar-dq08.dtb#" -i /mnt/armbianEnv.txt
losetup -D
mv /build/armbian-build/output/images/*.img /build/dq08.img
EOF
chmod a+x rk3528-tvbox/build.sh
docker run -it -v /dev:/dev --privileged=true -v `pwd`/rk3528-tvbox:/build --rm armbian.local.only/armbian-build:initial /build/build.sh
if [ ! -e u-boot ]; then
  git clone https://github.com/u-boot/u-boot
  cd u-boot
  git checkout 93905ab6e7564089f5d7b703b660464d675e5ab0
  git clone https://github.com/rockchip-linux/rkbin.git
  cd rkbin
  git checkout f43a462e7a1429a9d407ae52b4745033034a6cf9
  cd ../..
fi
cd u-boot
git stash -u
patch -p1 < ../u-boot-2025-i2c.patch
export ROCKCHIP_TPL=rkbin/bin/rk35/rk3528_ddr_1056MHz_4BIT_PCB_v1.10.bin
export BL31=rkbin/bin/rk35/rk3528_bl31_v1.18.elf
make generic-rk3528_defconfig
patch -p1 < ../u-boot-2025-config.patch
make -j$(nproc)
dd if=idbloader.img of=../rk3528-tvbox/dq08.img conv=notrunc seek=64 bs=512
dd if=u-boot.itb of=../rk3528-tvbox/dq08.img conv=notrunc bs=512 seek=16384
