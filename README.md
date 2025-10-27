## nfutils

Script utilitas berbasis Shell bukan ~~Pertaminya~~ untuk membantu workflow pengembangan Laravel menggunakan Docker yang akan lebih baik menggunakan [CodeSpace](https://github.com/codespaces) sebagai lingkungan pengembangannya. tapi ngga pake CodeSpace juga gapapa. up to you la.

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
nfutils version        # Menampilkan versi saat ini
nfutils help           # Menampilkan daftar perintah
nfutils update         # Memeriksa dan memasang versi terbaru
nfutils uninstall      # Menghapus nfutils dari sistem
```

Contoh perintah lainnya:
```bash
nfutils lara-create nama-proyek       # membuat didalam direktori
nfutils lara-create .                 # membuat di current dir
nfutils lara-init                     # inisialisasi laravel sail
nfutils lara-init -p 8000             # inisialisasi sail dan set APP_PORT
nfutils sail                          # sail command.
sail                                  # sama aja, tapi langsung tanpa nfutils. ini bakal bisa dipake setelah lara-init
nfutils composer install              # composer images
nfutils dock-nuke                     # bahaya ini semua container, images, volume, network hilang.
nfutils destroyer                     # ini juga bahaya current dir bisa kosong!
```

### Pembaruan & Status
`nfutils` akan menarik skrip terbaru dari GitHub. Pastikan koneksi internet tersedia saat menjalankan `nfutils update`. Penomoran versi menggunakan stempel waktu + git commit contohnya `v2025-10-27T19:35:00-g4a9ea65`. script ini masih akan terus dikembangkan, dan masih belum tau kedepannya bakal seperti apa.

### Auto-completion
Installer otomatis menambahkan skrip komplesi:
- Bash: `~/.bash_completion.d/nfutils`.
- Zsh: `~/.zsh/completions/_nfutils` (sertakan `fpath` dan `compinit` di `.zshrc`).
Reload shell (atau `source` file rc) setelah instal supaya saran perintah aktif.

Saat menjalankan `nfutils lara-init`, alias `sail` otomatis ditambahkan ke profil shell sehingga kamu bisa menjalankan `sail up` langsung.

### Kontribusi
Silakan ajukan issue atau pull request di repositori GitHub untuk ide peningkatan atau laporan bug.

### Lisensi
Dirilis di bawah GNU General Public License versi 2 (lihat berkas `LICENSE`).
