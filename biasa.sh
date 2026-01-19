#!/bin/bash
# Storage setup khusus foto & video
# Format ext4 (aman untuk server / mati listrik)

set -e

echo "=== DETEKSI DISK ==="
lsblk
echo
read -p "Masukkan partisi HDD/SSD (contoh: sdb1): " DEV

DISK="/dev/$DEV"
BASE="/mnt/media"

mkdir -p $BASE

read -p "Format disk ke ext4? (y/n): " FORMAT
if [ "$FORMAT" = "y" ]; then
    mkfs.ext4 $DISK
fi

mount $DISK $BASE

# Folder khusus
mkdir -p $BASE/{photos,videos}

# Auto mount saat boot
UUID=$(blkid -s UUID -o value $DISK)

cat <<EOF >> /etc/fstab
UUID=$UUID  $BASE  ext4  defaults  0  2
EOF

echo
echo "=== SELESAI ==="
echo "Folder siap:"
echo "$BASE/photos  -> foto"
echo "$BASE/videos  -> video"
echo
echo "Bisa dishare ke Windows via Samba / CasaOS / FTP"
