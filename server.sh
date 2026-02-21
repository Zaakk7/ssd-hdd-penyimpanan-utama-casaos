#!/bin/bash
set -e

echo "=== MIGRASI STORAGE DOCKER & CASAOS (BIND MODE) ==="

read -p "Masukkan partisi disk baru (contoh: sdb1): " DEV
DISK="/dev/$DEV"
BASE="/mnt/storage"

echo "Stopping services..."
systemctl stop casaos || true
systemctl stop docker || true

# Unmount jika ter-mount
if findmnt -rn -S $DISK >/dev/null; then
    echo "Unmounting existing mount..."
    umount $DISK
fi

mkdir -p $BASE

read -p "Format disk ke ext4? (y/n): " FORMAT
if [ "$FORMAT" = "y" ]; then
    mkfs.ext4 -F $DISK
fi

mount $DISK $BASE

mkdir -p $BASE/{docker,casaos,appdata}

echo "Copy data Docker..."
rsync -aHAX /var/lib/docker/ $BASE/docker/

echo "Copy data CasaOS..."
rsync -aHAX /var/lib/casaos/ $BASE/casaos/

if [ -d /DATA/AppData ]; then
  echo "Copy data AppData..."
  rsync -aHAX /DATA/AppData/ $BASE/appdata/
fi

echo "Backup old data..."
mv /var/lib/docker /var/lib/docker.bak
mv /var/lib/casaos /var/lib/casaos.bak
mv /DATA/AppData /DATA/AppData.bak 2>/dev/null || true

mkdir -p /var/lib/docker /var/lib/casaos /DATA/AppData

mount --bind $BASE/docker /var/lib/docker
mount --bind $BASE/casaos /var/lib/casaos
mount --bind $BASE/appdata /DATA/AppData

UUID=$(blkid -s UUID -o value $DISK)

# Tambah fstab jika belum ada
grep -q "$UUID" /etc/fstab || echo "UUID=$UUID  $BASE  ext4  defaults,noatime,nodiratime,nofail  0  2" >> /etc/fstab
grep -q "$BASE/docker" /etc/fstab || echo "$BASE/docker   /var/lib/docker  none  bind  0  0" >> /etc/fstab
grep -q "$BASE/casaos" /etc/fstab || echo "$BASE/casaos   /var/lib/casaos  none  bind  0  0" >> /etc/fstab
grep -q "$BASE/appdata" /etc/fstab || echo "$BASE/appdata  /DATA/AppData  none  bind  0  0" >> /etc/fstab

echo "Starting services..."
systemctl start docker
systemctl start casaos

echo "=== MIGRASI SELESAI ==="
echo "Backup lama ada di:"
echo "/var/lib/docker.bak"
echo "/var/lib/casaos.bak"
echo "/DATA/AppData.bak"
echo "Reboot sangat disarankan."
