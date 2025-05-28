#!/bin/bash
set -e
set -x
echo "   open fat" > /tmp/screen
SOURCE=`mount | grep " on / " | awk '{ print $1 }' | sed "s#p2##"`
umount /mnt || true
mount ${SOURCE}p3 /mnt
echo "   eHtract" > /tmp/screen
unzip /mnt/*.zip -d /tmp

echo "   partItIon" > /tmp/screen
TARGET=/dev/mmcblk2
sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | fdisk $TARGET
  d # delete
  3
  d # delete
  4
  d # delete
  5
  d # delete
  6
  d # delete
  7
  d # delete
  8
  d # delete
  9
  d # delete
  10
  d # delete
  11
  d # delete
  12
  d # delete
  13
  d # delete
  14
  d # delete
  2
  n # new partition
  2
  16384
  +16384
  n # new partition
  3

  +524288
  n # new partition
  4

  61071295
  n # new partition
  5
  61071296
  61071325
  x # expert mode
  n # set name
  2
  uboot
  n # set name
  3
  boot
  n # set name
  4
  rootfs
  p # print
  r # return
  w # save
  q # quit
EOF
sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | gdisk $TARGET
  x # expert mode
  a # set attribute
  3
  2

  w
  Y
EOF

LO=`losetup -f`
IN=`ls /tmp/*.img`
losetup --partscan $LO ${IN}
echo "   put 1" > /tmp/screen
dd bs=512 if=$LO of=${TARGET}p2 count=16384 skip=16384
echo "   put 2" > /tmp/screen
dd if=${LO}p1 of=${TARGET}p3 bs=1M status=progress
echo "   put 3" > /tmp/screen
dd if=${LO}p2 of=${TARGET}p4 bs=1M status=progress
losetup -D
sync
echo "   fInIshed" > /tmp/screen