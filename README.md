## nfutils

Script utilitas berbasis Shell untuk membantu workflow pengembangan Laravel + Docker dengan codespace space sebai lingkungan pengembangannya.

### Fitur Utama
- Instalasi skrip `nfutils` ke `$HOME/bin` lengkap dengan auto-completion [Tab] key.
- Manajemen proyek Laravel: inisialisasi proyek baru, setup Laravel Sail, dan shortcut perintah Sail.
- Shortcut perintah Composer di dalam container.
- Kumpulan perintah Docker (kill, rm, destroy, nuke) serta pembersihan direktori.
- Dukungan pembaruan dan pencopotan `nfutils` langsung dari CLI.

### Cara Instalasi
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
nfutils laravel init nama-proyek    # Bisa menggunakan . untuk direktori yang diinginkan
nfutils laravel sail                
nfutils sail up
nfutils sail down
nfutils composer install
nfutils docker nuke
nfutils destroyer
```

### Pembaruan
`nfutils` akan menarik skrip terbaru dari GitHub. Pastikan koneksi internet tersedia saat menjalankan `nfutils update`. Penomoran versi mengikuti pola semver dengan awalan `v`, dimulai dari `v0.0.1`.

### Kontribusi
Silakan ajukan issue atau pull request di repositori GitHub untuk ide peningkatan atau laporan bug.
