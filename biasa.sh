#!/bin/bash
# Storage setup khusus foto & video
# Format ext4 (aman mati listrik)

set -e

echo "=== DETEKSI DISK ==="
lsblk
echo
read -p "Masukkan partisi HDD/SSD (contoh: sdb1): " DEV

DISK="/dev/$DEV"
BASE="/mnt/media"

# Unmount jika sedang ter-mount
if mount | grep -q "$DISK"; then
    echo "Partisi sedang ter-mount. Melakukan unmount..."
    umount $DISK
fi

mkdir -p $BASE

read -p "Format disk ke ext4? (y/n): " FORMAT
if [ "$FORMAT" = "y" ]; then
    echo "Memformat $DISK ke ext4..."
    mkfs.ext4 -F $DISK
fi

mount $DISK $BASE

# Folder media
mkdir -p $BASE/{photos,videos}

# Auto mount saat boot
UUID=$(blkid -s UUID -o value $DISK)

cat <<EOF >> /etc/fstab
UUID=$UUID  $BASE  ext4  defaults  0  2
EOF

echo
echo "=== SELESAI ==="
echo "Folder siap:"
echo "$BASE/photos"
echo "$BASE/videos"
echo
echo "Disk akan otomatis ter-mount saat reboot."
