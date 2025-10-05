#!/bin/bash
if [ ! "$1" ]; then
  echo "usage: $0 <version>"
  exit 1
fi
set -x
set -e
IN=rk3528-tvbox/dq08.img
OUT=dq08_bookworm_$1.sd.img
cp $IN $OUT
LO=`sudo losetup -f`
sudo losetup --partscan $LO $OUT
mkdir -p tmp
sudo mount ${LO}p2 tmp
sudo rm tmp/root/.not_logged_in_yet
sudo cp i2c_screen_daemon.sh tmp/usr/local/bin/
sudo cp i2c_screen_daemon.rc tmp/etc/init.d/i2c_screen_daemon
sudo chmod a+x tmp/etc/init.d/i2c_screen_daemon
sudo ln -s /etc/init.d/i2c_screen_daemon tmp/etc/rc2.d/S99i2c_screen_daemon
sudo umount tmp
sudo losetup -D
sync