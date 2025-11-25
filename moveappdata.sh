#!/bin/bash

echo "=== Auto Move CasaOS AppData to External HDD ==="

# Detect HDD mount under /media/devmon
HDD_PATH=$(ls /media/devmon | head -n 1)

if [ -z "$HDD_PATH" ]; then
    echo "❌ Tidak menemukan HDD eksternal di /media/devmon"
    exit 1
fi

FULL_HDD_PATH="/media/devmon/$HDD_PATH"

echo "✔ HDD terdeteksi: $FULL_HDD_PATH"

# Buat folder tujuan
TARGET="$FULL_HDD_PATH/CasaOS/AppData"
mkdir -p "$TARGET"

echo "📁 Menyalin AppData ke HDD..."
rsync -avh /DATA/AppData/ "$TARGET/"

echo "📁 Membuat backup AppData lama..."
mv /DATA/AppData /DATA/AppData.backup

echo "🔗 Membuat symlink ke HDD..."
ln -s "$TARGET" /DATA/AppData

echo "🔁 Restart CasaOS..."
systemctl restart casaos

echo "=== SELESAI ==="
echo "✔ AppData sudah pindah ke: $TARGET"
