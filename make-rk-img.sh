#!/bin/bash
set -x
set -e
OUT=dq08_ha_supervised_3.0.0.img
ME=`cd $(dirname $0); pwd`
ARMBIAN=`ls rk3528-tvbox/armbian-build/output/images/*.img`
LO=`sudo losetup -f`
sudo losetup --partscan $LO $ARMBIAN
sudo dd bs=512 if=$LO of=uboot.img count=16384 skip=16384
sudo dd if=${LO}p1 of=boot.img bs=1M
sudo dd if=${LO}p2 of=rootfs.img bs=1M
rm -rf ${OUT}.dump ${OUT} ${OUT}.zip
mkdir -p ${OUT}.dump/Image
mv uboot.img boot.img rootfs.img ${OUT}.dump/Image
cp package-file image.cfg ${OUT}.dump/
cp MiniLoaderAll.bin parameter.txt ${OUT}.dump/Image
sudo losetup -D
mkdir -p tmp
LO=`sudo losetup -f`
sudo losetup $LO ${OUT}.dump/Image/rootfs.img
sudo mount $LO tmp
sudo rm tmp/root/.not_logged_in_yet
sudo cp haos_install.sh tmp/usr/local/bin/
sudo cp haos_install.rc tmp/etc/init.d/haos_install
sudo chmod a+x tmp/etc/init.d/haos_install
sudo ln -s /etc/init.d/haos_install tmp/etc/rc2.d/S99haos_install
sudo ln -s /etc/init.d/haos_install tmp/etc/rc3.d/S99haos_install
sudo ln -s /etc/init.d/haos_install tmp/etc/rc4.d/S99haos_install
sudo ln -s /etc/init.d/haos_install tmp/etc/rc5.d/S99haos_install
sudo umount tmp
sudo losetup -D
sync
IMGREPACKER=/tmp/imgrepacker
rm -rf $IMGREPACKER
mkdir $IMGREPACKER
7z e $ME/tools/imgRePacker*.zip -o$IMGREPACKER
chmod a+x $IMGREPACKER/imgrepackerrk
if [ `uname -m` == "aarch64" ]; then
  if [ ! `which FEXInterpreter` ]; then
    curl --silent https://raw.githubusercontent.com/FEX-Emu/FEX/main/Scripts/InstallFEX.py --output /tmp/InstallFEX.py
    sed -i 's#\["FEXRootFSFetcher"\]#\["FEXRootFSFetcher","-y","-a"\]#' /tmp/InstallFEX.py
    python3 /tmp/InstallFEX.py
    rm /tmp/InstallFEX.py
  fi
  FEXInterpreter $IMGREPACKER/imgrepackerrk ${OUT}.dump
else
  $IMGREPACKER/imgrepackerrk ${OUT}.dump || wine $IMGREPACKER/imgRePackerRK.exe ${OUT}.dump
fi
zip ${OUT}.zip ${OUT}