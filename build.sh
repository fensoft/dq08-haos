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
mkdir -p userpatches/extensions
# for i in ha docker-ce; do
#   curl https://raw.githubusercontent.com/armbian/os/refs/heads/main/userpatches/extensions/$i.sh > userpatches/extensions/$i.sh
# done
# ENABLE_EXTENSIONS=ha
./compile.sh build BOARD=rk3528-tvbox BRANCH=legacy BUILD_DESKTOP=no BUILD_MINIMAL=yes EXPERT=yes KERNEL_CONFIGURE=no KERNEL_GIT=shallow RELEASE=bookworm PACKAGE_LIST_BOARD="i2c-tools gettext-base"
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
EOF
chmod a+x rk3528-tvbox/build.sh
docker run -it -v /dev:/dev --privileged=true -v `pwd`/rk3528-tvbox:/build --rm armbian.local.only/armbian-build:initial /build/build.sh
