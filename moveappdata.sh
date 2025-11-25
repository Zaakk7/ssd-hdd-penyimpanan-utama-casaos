#!/bin/bash

echo "=== Moving CasaOS AppData to HDD (/mnt/external) ==="

HDD_PATH="/mnt/external"

# Check HDD mount
if [ ! -d "$HDD_PATH" ]; then
    echo "❌ HDD tidak ditemukan di /mnt/external"
    exit 1
fi

echo "✔ HDD ditemukan: $HDD_PATH"

# Stop all casaos apps
echo "⏹ Menghentikan semua aplikasi..."
docker stop $(docker ps -aq)

# Create AppData on HDD
TARGET="$HDD_PATH/CasaOS/AppData"
mkdir -p "$TARGET"

echo "📁 Menyalin data..."
rsync -avh /DATA/AppData/ "$TARGET/"

echo "📁 Backup AppData lama..."
mv /DATA/AppData /DATA/AppData.backup

echo "🔗 Membuat symlink..."
ln -s "$TARGET" /DATA/AppData

echo "🔁 Restart CasaOS dan Docker..."
systemctl restart casaos
systemctl restart docker

echo "=== SELESAI ==="
echo "✔ AppData sekarang berada di: $TARGET"
