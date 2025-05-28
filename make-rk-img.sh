#!/bin/bash
if [ ! "$1" ]; then
  echo "usage: $0 <version>"
  exit 1
fi
set -x
set -e

IN=dq08_ha_supervised_$1.sd.img
OUT=dq08_ha_supervised_$1.img
ME=`cd $(dirname $0); pwd`
LO=`sudo losetup -f`
sudo losetup --partscan $LO $IN
rm -rf ${OUT}.dump ${OUT} ${OUT}.zip
mkdir -p ${OUT}.dump/Image
sudo dd bs=512 if=$LO of=${OUT}.dump/Image/uboot.img count=16384 skip=16384
sudo dd if=${LO}p1 of=${OUT}.dump/Image/boot.img bs=1M
sudo dd if=${LO}p2 of=${OUT}.dump/Image/rootfs.img bs=1M
cp package-file image.cfg ${OUT}.dump/
cp MiniLoaderAll.bin parameter.txt ${OUT}.dump/Image

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