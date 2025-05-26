#!/bin/bash
set -e
set -x
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

SOURCE=/dev/mmcblk1
dd bs=512 if=$SOURCE of=${TARGET}p2 count=16384 skip=16384
umount /boot || true
umount /mnt || true
dd if=${SOURCE}p1 of=${TARGET}p3 bs=1M status=progress
mkfs.ext4 -F ${TARGET}p4
mount ${TARGET}p4 /mnt
rsync -axHAX / /mnt
UUID=`blkid ${TARGET}p4 -o export | grep "^UUID" | sed "s#UUID=##"`
echo emmc > /mnt/etc/hostname
umount /mnt
mount ${TARGET}p3 /mnt
sed -i "s#rootdev=UUID=.*#rootdev=UUID=$UUID#" /mnt/armbianEnv.txt
umount /mnt