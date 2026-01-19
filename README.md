#!/bin/bash
# Storage setup
# Docker + CasaOS + CasaOS AppData
# Jalankan sebelum install Docker & CasaOS

set -e

echo "=== DETEKSI DISK ==="
lsblk
echo
read -p "Masukkan partisi SSD/HDD (contoh: sda1): " DEV

DISK="/dev/$DEV"
BASE="/mnt/storage"

# 1. Mount disk utama
mkdir -p $BASE

read -p "Format disk ke ext4? (y/n): " FORMAT
if [ "$FORMAT" = "y" ]; then
    mkfs.ext4 $DISK
fi

mount $DISK $BASE

# 2. Buat struktur folder
mkdir -p $BASE/{docker,casaos,appdata}

# 3. Buat mount point sistem
mkdir -p /var/lib/docker
mkdir -p /var/lib/casaos
mkdir -p /DATA/AppData

# 4. Bind mount
mount --bind $BASE/docker /var/lib/docker
mount --bind $BASE/casaos /var/lib/casaos
mount --bind $BASE/appdata /DATA/AppData

# 5. FSTAB
UUID=$(blkid -s UUID -o value $DISK)

cat <<EOF >> /etc/fstab
UUID=$UUID  $BASE  ext4  defaults  0  2
$BASE/docker   /var/lib/docker  none  bind  0  0
$BASE/casaos   /var/lib/casaos  none  bind  0  0
$BASE/appdata  /DATA/AppData    none  bind  0  0
EOF

echo
echo "=== SELESAI ==="
echo "Sekarang install:"
echo "1. Docker"
echo "2. CasaOS"
echo
echo "Semua data Docker & CasaOS langsung ke SSD/HDD."
