#!/bin/bash
set -x
set -e
OUT=dq08.img
ME=`cd $(dirname $0); pwd`
ARMBIAN=`ls rk3528-tvbox/armbian-build/output/images/*.img`
LO=`sudo losetup -f`
sudo losetup --partscan $LO $ARMBIAN
sudo dd bs=512 if=$LO of=uboot.img count=16384 skip=16384
sudo dd if=${LO}p1 of=boot.img bs=1M
sudo dd if=${LO}p2 of=rootfs.img bs=1M
rm -rf ${OUT}.dump ${OUT}
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
sudo ln -s /etc/init.d/haos_install tmp/etc/rc2.d/S99haos_install
sudo ln -s /etc/init.d/haos_install tmp/etc/rc3.d/S99haos_install
sudo ln -s /etc/init.d/haos_install tmp/etc/rc4.d/S99haos_install
sudo ln -s /etc/init.d/haos_install tmp/etc/rc5.d/S99haos_install
sudo umount tmp
rm -rf /tmp/imgrepacker
mkdir /tmp/imgrepacker
7z e $ME/tools/imgRePacker*.zip -o/tmp/imgrepacker
chmod a+x /tmp/imgrepacker/imgrepackerrk
if [ `uname -m` == "aarch64" ]; then
  if [ ! `which FEXInterpreter` ]; then
    curl --silent https://raw.githubusercontent.com/FEX-Emu/FEX/main/Scripts/InstallFEX.py --output /tmp/InstallFEX.py
    python3 /tmp/InstallFEX.py
    rm /tmp/InstallFEX.py
    FEXRootFSFetcher -y -a
  fi
  FEXInterpreter /tmp/imgrepacker/imgrepackerrk ${OUT}.dump
else
  /tmp/imgrepacker/imgrepackerrk ${OUT}.dump
fi
