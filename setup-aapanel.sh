#!/bin/bash
# ALL-IN-ONE storage setup
# aaPanel + Docker + CasaOS + CasaOS AppData
# WAJIB dijalankan sebelum install apa pun

set -e

echo "=== DETEKSI DISK ==="
lsblk
echo
read -p "Masukkan partisi SSD/HDD (contoh: sda1): " DEV

DISK="/dev/$DEV"
BASE="/mnt/storage"

### ================= PROTEKSI DISK SISTEM =================
ROOT_DISK=$(findmnt / -o SOURCE -n)

if [[ "$DISK" == "$ROOT_DISK"* ]]; then
    echo "❌ ERROR: Tidak boleh menggunakan disk sistem ($ROOT_DISK)"
    exit 1
fi

### ================= UNMOUNT JIKA MASIH MOUNTED =================
if mount | grep -q "$DISK"; then
    echo "⚠️  Disk masih mounted, melakukan unmount..."
    umount "$DISK" || {
        echo "❌ Gagal unmount $DISK"
        exit 1
    }
fi

### ================= FORMAT =================
mkdir -p "$BASE"

read -p "Format disk ke ext4? (y/n): " FORMAT
if [ "$FORMAT" = "y" ]; then
    echo "⚠️  MEMFORMAT $DISK ..."
    mkfs.ext4 "$DISK"
fi

### ================= MOUNT =================
mount "$DISK" "$BASE"

### ================= STRUKTUR FOLDER =================
mkdir -p "$BASE"/{www,docker,casaos,appdata}

### ================= MOUNT POINT SISTEM =================
mkdir -p /www
mkdir -p /var/lib/docker
mkdir -p /var/lib/casaos
mkdir -p /DATA/AppData

### ================= BIND MOUNT =================
mount --bind "$BASE/www" /www
mount --bind "$BASE/docker" /var/lib/docker
mount --bind "$BASE/casaos" /var/lib/casaos
mount --bind "$BASE/appdata" /DATA/AppData

### ================= FSTAB =================
UUID=$(blkid -s UUID -o value "$DISK")

grep -q "$UUID" /etc/fstab || cat <<EOF >> /etc/fstab
UUID=$UUID  $BASE  ext4  defaults  0  2
$BASE/www      /www             none  bind  0  0
$BASE/docker   /var/lib/docker  none  bind  0  0
$BASE/casaos   /var/lib/casaos  none  bind  0  0
$BASE/appdata  /DATA/AppData    none  bind  0  0
EOF

echo
echo "=== SELESAI ==="
echo "Sekarang install:"
echo "1. aaPanel"
echo "2. Docker"
echo "3. CasaOS"
echo
echo "✅ Semua data langsung ke SSD/HDD"
