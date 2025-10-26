## nfutils

Script utilitas berbasis Shell bukan ~~Pertaminya~~ untuk membantu workflow pengembangan Laravel menggunakan Docker yang juga mengandalkan [CodeSpace](https://github.com/codespaces) sebagai lingkungan pengembangannya.

### Fitur Utama
- Instalasi skrip `nfutils` ke `$HOME/bin` dengan auto-completion [Tab] key.
- Manajemen proyek Laravel: inisialisasi proyek baru, setup Laravel Sail, dan shortcut perintah Sail.
- Shortcut perintah Composer di dalam container.
- Kumpulan perintah Docker (kill, rm, destroy, nuke) serta pembersihan direktori.
- Dukungan pembaruan dan pencopotan `nfutils` langsung dari CLI.

### Cara Instalasi
Download file nfutils.sh lalu...
```bash
bash nfutils.sh
```
Perintah di atas akan menyalin skrip ke `$HOME/bin/nfutils`, memperbarui PATH, dan mengaktifkan auto-completion bila tersedia.

Atau instal langsung dari GitHub:
```bash
curl -s https://raw.githubusercontent.com/neflalabs/nfutils/main/nfutils.sh | bash
```

### Cara Menggunakan
```bash
nfutils --version      # Menampilkan versi saat ini
nfutils help           # Menampilkan daftar perintah
nfutils update         # Memeriksa dan memasang versi terbaru
nfutils uninstall      # Menghapus nfutils dari sistem
```

Contoh perintah lainnya:
```bash
nfutils laravel create nama-proyek    # membuat didalam direktory
nfutils laravel create .              # membuat di current dir
nfutils laravel init                  # inisialisasi laravel sail
nfutils sail up                       # sail up / docker compose up
nfutils sail down                     # sama aja, buat down
nfutils composer install              # composer images
nfutils docker nuke                   # bahaya ini semua container, images, volume, network hilang.
nfutils destroyer                     # ini juga bahaya current dir bisa kosong!
```

### Pembaruan & Status
`nfutils` akan menarik skrip terbaru dari GitHub. Pastikan koneksi internet tersedia saat menjalankan `nfutils update`. Penomoran versi mengikuti pola semver dengan awalan `v`, contoh `v0.0.1`. script ini masih pengembangan, masih belum tau kedepannya bakal seperti apa.

### Kontribusi
Silakan ajukan issue atau pull request di repositori GitHub untuk ide peningkatan atau laporan bug.
