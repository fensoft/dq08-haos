#!/bin/bash
if [ ! "$1" ]; then
  echo "usage: $0 <version>"
  exit 1
fi
set -e
set -x
IN=rk3528-tvbox/dq08.img
OUT=dq08_recovery_$1.img
cp ${IN} ${OUT}
dd if=/dev/zero bs=1M count=500 >> ${OUT}
LO=`sudo losetup -f`
sudo losetup --partscan $LO ${OUT}
sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | sudo fdisk $LO
n # new partition



t # change type

11
w # write change
EOF
sudo mkfs.vfat -F 32 ${LO}p3
mkdir -p tmp
sudo mount ${LO}p3 tmp
sudo umount tmp
sudo mount ${LO}p2 tmp
sudo rm tmp/root/.not_logged_in_yet
sudo cp i2c_screen_daemon.sh tmp/usr/local/bin/
sudo cp i2c_screen_daemon.rc tmp/etc/init.d/i2c_screen_daemon
sudo chmod a+x tmp/etc/init.d/i2c_screen_daemon
sudo ln -s /etc/init.d/i2c_screen_daemon tmp/etc/rc2.d/S99i2c_screen_daemon
sudo cp img_to_emmc.sh tmp/usr/local/bin/
sudo cp img_to_emmc.rc tmp/etc/init.d/img_to_emmc
sudo chmod a+x tmp/etc/init.d/img_to_emmc
sudo ln -s /etc/init.d/img_to_emmc tmp/etc/rc2.d/S99img_to_emmc
sudo umount tmp
sudo losetup -d $LO
sudo sync