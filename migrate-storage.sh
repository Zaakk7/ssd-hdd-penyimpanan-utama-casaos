#!/bin/bash
# Script: migrate-storage.sh
# Fungsi: Memindahkan Docker & CasaOS storage ke SSD/HDD eksternal
# Untuk Linux/Debian/Armbian

set -e

echo "=== Deteksi storage eksternal ==="
lsblk
echo
read -p "Masukkan device SSD/HDD (contoh: sda1): " DEV

TARGET="/dev/$DEV"
MOUNT_POINT="/mnt/external"

echo "=== Membuat mount point ==="
mkdir -p $MOUNT_POINT

echo "=== Format drive (ext4) ==="
read -p "Format drive ke ext4? (y/n): " FM
if [ "$FM" = "y" ]; then
    mkfs.ext4 $TARGET
fi

echo "=== Mount drive ==="
mount $TARGET $MOUNT_POINT

echo "=== Stop Docker ==="
systemctl stop docker

echo "=== Migrasi Docker data ==="
rsync -aP /var/lib/docker/ $MOUNT_POINT/docker/
mv /var/lib/docker /var/lib/docker.bak
ln -s $MOUNT_POINT/docker /var/lib/docker

echo "=== Migrasi CasaOS data ==="
rsync -aP /var/lib/casaos/ $MOUNT_POINT/casaos/
mv /var/lib/casaos /var/lib/casaos.bak
ln -s $MOUNT_POINT/casaos /var/lib/casaos

echo "=== Tambahkan ke /etc/fstab ==="
UUID=$(blkid -s UUID -o value $TARGET)
echo "UUID=$UUID  $MOUNT_POINT  ext4  defaults  0  2" >> /etc/fstab

echo "=== Start Docker ==="
systemctl start docker

echo
echo "=== Migrasi selesai! ==="
echo "Data Docker & CasaOS sekarang tersimpan di SSD/HDD eksternal."
