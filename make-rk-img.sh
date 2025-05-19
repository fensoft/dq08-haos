#!/bin/bash
set -x
set -e
ME=`cd $(dirname $0); pwd`
ARMBIAN=`ls rk3528-tvbox/armbian-build/output/images/*.img`
LO=`losetup -f`
losetup --partscan $LO $ARMBIAN
dd bs=512 if=$LO of=uboot.img count=16384 skip=16384
dd if=${LO}p1 of=boot.img bs=1M
dd if=${LO}p2 of=rootfs.img bs=1M
rm -rf dq08.img.dump dq08.img
mkdir -p dq08.img.dump/Image
mv uboot.img boot.img rootfs.img dq08.img.dump/Image
cp package-file image.cfg dq08.img.dump/
cp MiniLoaderAll.bin parameter.txt dq08.img.dump/Image
losetup -D
mkdir -p tmp
LO=`losetup -f`
losetup $LO dq08.img.dump/Image/rootfs.img
mount $LO tmp
rm tmp/root/.not_logged_in_yet
cp haos_install.sh tmp/usr/local/bin/
cp haos_install.rc tmp/etc/init.d/haos_install
sudo ln -s /etc/init.d/haos_install tmp/etc/rc2.d/S99haos_install
sudo ln -s /etc/init.d/haos_install tmp/etc/rc3.d/S99haos_install
sudo ln -s /etc/init.d/haos_install tmp/etc/rc4.d/S99haos_install
sudo ln -s /etc/init.d/haos_install tmp/etc/rc5.d/S99haos_install
umount tmp
rm -rf /tmp/imgrepacker
mkdir /tmp/imgrepacker
7z e $ME/tools/imgRePacker*.zip -o/tmp/imgrepacker
chmod a+x /tmp/imgrepacker/imgrepackerrk
/tmp/imgrepacker/imgrepackerrk dq08.img.dump
