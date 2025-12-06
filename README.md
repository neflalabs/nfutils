# nfutils

Script utilitas berbasis Shell bukan ~~Pertaminya~~ untuk membantu workflow pengembangan Laravel menggunakan Docker yang juga bisa menggunakan [CodeSpace](https://github.com/codespaces) sebagai lingkungan pengembangannya. tapi ngga pake CodeSpace juga gapapa. terserah kamu asal jangan make powershell.

---

### Fitur Utama
- Instalasi skrip `nfutils` ke `$HOME/bin` lengkap dengan auto-completion (bash & zsh).
- Manajemen proyek Laravel: `laravel create` untuk bootstrap proyek baru dan `laravel init` untuk setup Sail + alias `sail`.
- Shortcut perintah Composer di dalam container Docker secara transparan.
- Perintah pembersihan: `destroyer` untuk mengosongkan direktori saat ini, dan `nuke` (double-confirm) untuk mematikan Docker, menghapus container/image/volume/network, lalu menghapus isi direktori aktif.
- Dukungan pembaruan (`nfutils update`) dan pencopotan (`nfutils uninstall`) langsung dari CLI.

### Prasyarat
- Pastikan Docker terpasang dan daemon berjalan. `nfutils` akan menghentikan eksekusi dan menampilkan instruksi instalasi jika Docker/Compose belum tersedia

### Cara Instalasi
Download file `nfutils.sh` / atau kamu bisa copy ini :

```
curl -s https://raw.githubusercontent.com/neflalabs/nfutils/main/nfutils.sh | bash
```
---
### Cara Menggunakan
Pastikan setelah install baik download file ./nfutils.sh atau via curl sebaiknya kamu melakukan sourcing ke shell.rc kamu. dengan cara `source ~/.zshrc` atau `source ~/.bashrc`


```
nfutils laravel create <dir|.>                         - Create new Laravel project (di dalam Docker)
nfutils laravel init [-p PORT] [-db|--database DRIVER] - Install Laravel Sail + alias `sail`
nfutils composer <args>            - Run Composer in Docker
nfutils destroyer                  - Delete all files in current dir ⚠️
nfutils nuke                       - ☢️ Stop Docker, remove containers/images/volumes/networks, delete current dir (2x confirm)
sail <args>                        - directly add into rc files while doing lara-init
nfutils update                     - Update nfutils from GitHub
nfutils uninstall                  - Remove nfutils from your system
nfutils version / -v               - Show nfutils version
nfutils help                       - Show this help message
```
---

---

### Pembaruan & Status
`nfutils` akan menarik skrip terbaru dari GitHub. Pastikan koneksi internet tersedia saat menjalankan `nfutils update`. Penomoran versi menggunakan stempel waktu + git commit contohnya `v2025-10-27T21:52:40-g25239fb`. script ini masih akan terus dikembangkan, dan masih belum tau kedepannya bakal seperti apa.

---

### Auto-completion
Installer otomatis menambahkan pelengkap otomatis:
- Bash: `~/.bash_completion.d/nfutils`.
- Zsh: `~/.zsh/completions/_nfutils` (sertakan `fpath` dan `compinit` di `.zshrc`).
Reload shell (atau `source` file rc) setelah instal supaya saran perintah aktif.

Saat menjalankan `nfutils laravel init`, alias `sail` otomatis ditambahkan ke profil shell sehingga kamu bisa menjalankan `sail up` langsung. Alih-alih memenuhi `.zshrc`, alias Sail ditempatkan dalam blok completion nfutils sehingga `nfutils uninstall` bisa membersihkannya otomatis.
