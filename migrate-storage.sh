#!/bin/bash
# CasaOS Storage Setup Only
# Mount SSD/HDD untuk:
#  - /var/lib/casaos
#  - /DATA/AppData
# Aman untuk disk yang sudah ter-mount

set -e

echo "=== DETEKSI DISK ==="
lsblk
echo
read -p "Masukkan partisi SSD/HDD (contoh: sda1): " DEV

DISK="/dev/$DEV"
BASE="/mnt/casaos-storage"

# Cek filesystem
FS_TYPE=$(blkid -o value -s TYPE "$DISK" || true)

if [ -z "$FS_TYPE" ]; then
    echo "⚠ Disk belum ada filesystem."
    read -p "Format ke ext4? (y/n): " FORMAT
    if [ "$FORMAT" = "y" ]; then
        mkfs.ext4 "$DISK"
    else
        echo "Batal. Disk belum siap."
        exit 1
    fi
else
    echo "✔ Filesystem terdeteksi: $FS_TYPE"
fi

# Buat mount point utama
mkdir -p "$BASE"

# Cek apakah sudah ter-mount
if mountpoint -q "$BASE"; then
    echo "✔ Disk sudah ter-mount di $BASE"
else
    echo "Mounting disk..."
    mount "$DISK" "$BASE"
fi

# Buat struktur folder
mkdir -p "$BASE/casaos"
mkdir -p "$BASE/appdata"

# Mount point sistem
mkdir -p /var/lib/casaos
mkdir -p /DATA/AppData

# Bind mount (cek dulu agar tidak double mount)
bind_mount() {
    SRC=$1
    DST=$2

    if mountpoint -q "$DST"; then
        echo "✔ $DST sudah ter-mount"
    else
        mount --bind "$SRC" "$DST"
        echo "✔ Bind mount $SRC -> $DST"
    fi
}

bind_mount "$BASE/casaos" /var/lib/casaos
bind_mount "$BASE/appdata" /DATA/AppData

# Ambil UUID
UUID=$(blkid -s UUID -o value "$DISK")

# Tambah ke fstab jika belum ada
if ! grep -q "$UUID" /etc/fstab; then
cat <<EOF >> /etc/fstab

# CasaOS Storage
UUID=$UUID  $BASE  ext4  defaults,nofail  0  2
$BASE/casaos   /var/lib/casaos   none  bind,nofail  0  0
$BASE/appdata  /DATA/AppData     none  bind,nofail  0  0
EOF
fi

echo
echo "=== SELESAI ==="
echo "Mount storage CasaOS:"
echo " - /var/lib/casaos"
echo " - /DATA/AppData"
echo
echo "Sekarang bisa install CasaOS."
