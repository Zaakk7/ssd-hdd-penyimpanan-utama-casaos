# Migrasi Storage CasaOS ke SSD/HDD Eksternal

Tutorial ini menjelaskan cara memindahkan penyimpanan utama Docker & CasaOS ke SSD atau HDD eksternal agar:
- Lebih cepat
- Tidak membebani SD Card/eMMC
- Aman untuk jangka panjang

---

## 📦 Fitur Script
- Otomatis mendeteksi perangkat storage
- Opsional format EXT4
- Memindahkan:
  - `/var/lib/docker`
  - `/var/lib/casaos`
- Menambahkan otomatis ke `/etc/fstab`
- Membuat backup data lama
- Mendukung SSD dan HDD

---

## 🧰 Cara Pakai

1. Download script:

```bash
wget https://raw.githubusercontent.com/username/repo/main/migrate-storage.sh
chmod +x migrate-storage.sh
