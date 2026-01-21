#!/bin/bash
set -e

echo "=== MIGRASI STORAGE DOCKER & CASAOS ==="

read -p "Masukkan partisi disk baru (contoh: sdb1): " DEV
DISK="/dev/$DEV"
BASE="/mnt/storage"

systemctl stop docker

# Unmount jika ter-mount
if mount | grep -q "$DISK"; then
    umount $DISK
fi

mkdir -p $BASE

read -p "Format disk ke ext4? (y/n): " FORMAT
if [ "$FORMAT" = "y" ]; then
    mkfs.ext4 -F $DISK
fi

mount $DISK $BASE

mkdir -p $BASE/{docker,casaos,appdata,photos}

echo "Copy data Docker..."
rsync -aHAX /var/lib/docker/ $BASE/docker/

echo "Copy data CasaOS..."
rsync -aHAX /var/lib/casaos/ $BASE/casaos/

if [ -d /DATA/AppData ]; then
  echo "Copy data AppData..."
  rsync -aHAX /DATA/AppData/ $BASE/appdata/
fi

mv /var/lib/docker /var/lib/docker.bak
mv /var/lib/casaos /var/lib/casaos.bak
mv /DATA/AppData /DATA/AppData.bak 2>/dev/null || true

mkdir -p /var/lib/docker /var/lib/casaos /DATA/AppData

mount --bind $BASE/docker /var/lib/docker
mount --bind $BASE/casaos /var/lib/casaos
mount --bind $BASE/appdata /DATA/AppData

UUID=$(blkid -s UUID -o value $DISK)

cat <<EOF >> /etc/fstab
UUID=$UUID  $BASE  ext4  defaults  0  2
$BASE/docker   /var/lib/docker  none  bind  0  0
$BASE/casaos   /var/lib/casaos  none  bind  0  0
$BASE/appdata  /DATA/AppData    none  bind  0  0
EOF

systemctl start docker

echo "=== MIGRASI SELESAI ==="
echo "Backup lama ada di:"
echo "/var/lib/docker.bak"
echo "/var/lib/casaos.bak"
echo "/DATA/AppData.bak"
