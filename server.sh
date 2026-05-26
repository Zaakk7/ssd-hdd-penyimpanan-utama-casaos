#!/bin/bash
set -e

# Pastikan dijalankan sebagai root
if [ "$EUID" -ne 0 ]; then
  echo "Error: Harap jalankan script ini sebagai root (gunakan sudo)!"
  exit 1
fi

echo "=== MIGRASI STORAGE DOCKER & CASAOS (BIND MODE) ==="

read -p "Masukkan partisi disk baru (contoh: sdb1): " DEV
DISK="/dev/$DEV"
BASE="/mnt/storage"

# Validasi apakah partisi yang dimasukkan benar-benar ada
if [ ! -b "$DISK" ]; then
    echo "Error: Partisi $DISK tidak ditemukan!"
    exit 1
fi

echo "Stopping services..."
systemctl stop casaos || true
systemctl stop docker || true
systemctl stop docker.socket || true # Docker socket juga wajib dimatikan

# Unmount jika ter-mount
if findmnt -rn -S "$DISK" >/dev/null; then
    echo "Unmounting existing mount..."
    umount "$DISK"
fi

mkdir -p "$BASE"

read -p "Format disk ke ext4? DATA DI DISK AKAN HILANG! (y/n): " FORMAT
if [ "$FORMAT" = "y" ]; then
    mkfs.ext4 -F "$DISK"
fi

mount "$DISK" "$BASE"

# Buat folder struktur di SSD
mkdir -p "$BASE/docker" "$BASE/casaos" "$BASE/appdata"

echo "Copy data Docker..."
if [ -d /var/lib/docker ]; then
    rsync -aHAX /var/lib/docker/ "$BASE/docker/"
fi

echo "Copy data CasaOS..."
if [ -d /var/lib/casaos ]; then
    rsync -aHAX /var/lib/casaos/ "$BASE/casaos/"
fi

echo "Copy data AppData..."
if [ -d /DATA/AppData ]; then
    rsync -aHAX /DATA/AppData/ "$BASE/appdata/"
fi

echo "Backup old data..."
[ -d /var/lib/docker ] && mv /var/lib/docker /var/lib/docker.bak
[ -d /var/lib/casaos ] && mv /var/lib/casaos /var/lib/casaos.bak
[ -d /DATA/AppData ] && mv /DATA/AppData /DATA/AppData.bak

# Buat ulang folder kosong untuk titik mount
mkdir -p /var/lib/docker
mkdir -p /var/lib/casaos
mkdir -p /DATA/AppData

# Lakukan Bind Mount langsung
mount --bind "$BASE/docker" /var/lib/docker
mount --bind "$BASE/casaos" /var/lib/casaos
mount --bind "$BASE/appdata" /DATA/AppData

# Ambil UUID
UUID=$(blkid -s UUID -o value "$DISK")

if [ -z "$UUID" ]; then
    echo "Error: Gagal mengambil UUID dari $DISK"
    exit 1
fi

echo "Menulis ke /etc/fstab..."
# Menggunakan format standar tab/spasi yang bersih untuk menghindari error boot
grep -q "$UUID" /etc/fstab || echo "UUID=$UUID $BASE ext4 defaults,noatime,nodiratime,nofail 0 2" >> /etc/fstab
grep -q "$BASE/docker" /etc/fstab || echo "$BASE/docker /var/lib/docker none bind 0 0" >> /etc/fstab
grep -q "$BASE/casaos" /etc/fstab || echo "$BASE/casaos /var/lib/casaos none bind 0 0" >> /etc/fstab
grep -q "$BASE/appdata" /etc/fstab || echo "$BASE/appdata /DATA/AppData none bind 0 0" >> /etc/fstab

echo "Starting services..."
systemctl start docker
systemctl start casaos

echo "=== MIGRASI SELESAI ==="
echo "Backup lama ada di:"
echo "- /var/lib/docker.bak"
echo "- /var/lib/casaos.bak"
echo "- /DATA/AppData.bak"
echo "------------------------------------------------"
echo "Sangat disarankan untuk REBOOT STB Anda sekarang!"
