#!/bin/bash
set -e

BASE="/mnt/casaos-storage"
BACKUP="/mnt/casaos-backup-$(date +%Y%m%d_%H%M%S)"

echo "=== DETEKSI STORAGE ==="
lsblk
echo
read -p "Masukkan partisi (contoh: sda1 / nvme0n1p1): " DEV
DISK="/dev/$DEV"

# Cek mount aktif
MOUNTED_AT=$(lsblk -no MOUNTPOINT "$DISK" | head -n1)

if [ -n "$MOUNTED_AT" ]; then
    echo "⚠ Disk sedang ter-mount di: $MOUNTED_AT"
    read -p "Unmount sekarang agar bisa diformat? (y/n): " UM
    if [ "$UM" = "y" ]; then
        umount -f "$DISK" || umount -l "$DISK"
        echo "✔ Disk berhasil di-unmount"
    else
        echo "Batal."
        exit 1
    fi
fi

# Cek filesystem
FS=$(blkid -o value -s TYPE "$DISK" || true)

if [ -z "$FS" ]; then
    echo "Disk belum ada filesystem."
else
    echo "Filesystem terdeteksi: $FS"
fi

read -p "Format disk ke EXT4? (y/n): " FORMAT
if [ "$FORMAT" = "y" ]; then
    mkfs.ext4 -F "$DISK"
    echo "✔ Format selesai"
fi

echo
echo "=== BACKUP DATA LAMA CASAOS ==="
mkdir -p "$BACKUP"

systemctl stop casaos || true

rsync -aAX /var/lib/casaos/ "$BACKUP/casaos/"
rsync -aAX /DATA/AppData/ "$BACKUP/appdata/"

echo "✔ Backup selesai di: $BACKUP"

# Mount disk baru
mkdir -p "$BASE"
mount "$DISK" "$BASE"

# Buat struktur folder
mkdir -p "$BASE/casaos"
mkdir -p "$BASE/appdata"

# Restore data
rsync -aAX "$BACKUP/casaos/" "$BASE/casaos/"
rsync -aAX "$BACKUP/appdata/" "$BASE/appdata/"

# Mount system paths
mkdir -p /var/lib/casaos /DATA/AppData

mount --bind "$BASE/casaos" /var/lib/casaos
mount --bind "$BASE/appdata" /DATA/AppData

# FSTAB
UUID=$(blkid -s UUID -o value "$DISK")

if ! grep -q "$UUID" /etc/fstab; then
cat <<EOF >> /etc/fstab

# CasaOS Storage
UUID=$UUID $BASE ext4 defaults,nofail 0 2
$BASE/casaos /var/lib/casaos none bind,nofail 0 0
$BASE/appdata /DATA/AppData none bind,nofail 0 0
EOF
fi

systemctl start casaos || true

echo
echo "=== SELESAI ==="
echo "Backup tersimpan di:"
echo "$BACKUP"
echo
echo "CasaOS sekarang menggunakan disk baru."
