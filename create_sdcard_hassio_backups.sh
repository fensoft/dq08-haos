#!/bin/bash
set -e

LABEL="hassio_backups"
MOUNTPOINT="/var/lib/homeassistant/backup"
FSTAB_LINE="LABEL=${LABEL} ${MOUNTPOINT} ext4 defaults,nofail,x-systemd.automount,x-systemd.idle-timeout=60 0 2"

echo "Waiting for SD card insertion..."

DEVICE=""

# Wait for new mmcblk device (your fixed version)
while read -r line; do
    # Detect "add" event for mmcblk*
    if echo "$line" | grep -q "add.*mmcblk"; then
        DEV=$(echo "$line" | grep -o "mmcblk[0-9]\+")
        if [ -n "$DEV" ]; then
            DEVICE="/dev/$DEV"
            echo "Detected new SD card: $DEVICE"
            break
        fi
    fi
done < <(udevadm monitor --udev --subsystem-match=block)

if [ -z "$DEVICE" ]; then
    echo "No device detected, exiting."
    exit 1
fi

echo "Using device: ${DEVICE}"

# Give the kernel a moment to create any nodes
sleep 2

# ---- Unmount any existing partitions on this device ------------------------
echo "Checking and unmounting any mounted partitions..."
for p in $(ls "${DEVICE}"p* 2>/dev/null || true); do
    if grep -q "^$p " /proc/mounts; then
        echo "  Unmounting $p"
        umount "$p" || echo "  Warning: could not unmount $p"
    fi
done

# ---- Wipe signatures and create ext4 on the WHOLE device ------------------
echo "Wiping existing filesystem/partition signatures on $DEVICE..."
wipefs -a "$DEVICE"

echo "Creating ext4 filesystem on $DEVICE with label '$LABEL'..."
mkfs.ext4 -F -L "$LABEL" "$DEVICE"

echo "Filesystem created."

# ---- Ensure mountpoint exists ---------------------------------------------
if [ ! -d "$MOUNTPOINT" ]; then
    echo "Creating mountpoint: $MOUNTPOINT"
    mkdir -p "$MOUNTPOINT"
fi

# ---- Add /etc/fstab entry (if not already present) ------------------------
echo "Updating /etc/fstab..."

if grep -q "LABEL=${LABEL} ${MOUNTPOINT} ext4" /etc/fstab; then
    echo "fstab entry already present."
else
    echo "$FSTAB_LINE" >> /etc/fstab
    echo "Added to /etc/fstab:"
    echo "  $FSTAB_LINE"
fi

# ---- Reload systemd units --------------------------------------------------
if command -v systemctl >/dev/null 2>&1; then
    echo "Reloading systemd daemon..."
    systemctl daemon-reload
fi

# ---- Mount the filesystem --------------------------------------------------
echo "Mounting ${MOUNTPOINT}..."
mount "$MOUNTPOINT"

echo "Mounted. Current filesystem usage:"
df -h "$MOUNTPOINT"

echo "Done. SD card is formatted as ext4 with label '${LABEL}' and mounted at: $MOUNTPOINT"
