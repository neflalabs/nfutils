# nfutils

Script utilitas berbasis Shell bukan ~~Pertaminya~~ untuk membantu workflow pengembangan Laravel menggunakan Docker yang juga bisa menggunakan [CodeSpace](https://github.com/codespaces) sebagai lingkungan pengembangannya. tapi ngga pake CodeSpace juga gapapa. terserah kamu asal jangan make powershell.

---

### Fitur Utama
- Instalasi skrip `nfutils` ke `$HOME/bin` dengan auto-completion [Tab] key.
- Manajemen proyek Laravel: inisialisasi proyek baru, setup Laravel Sail, dan shortcut perintah Sail.
- Shortcut perintah Composer di dalam container.
- Kumpulan perintah Docker (kill, rm, destroy, nuke) serta pembersihan direktori.
- Dukungan pembaruan dan pencopotan `nfutils` langsung dari CLI.

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
nfutils lara-create <project>      - Create new nfutils Laravel project
nfutils lara-init [-p PORT]        - Initialize Sail in existing project
nfutils composer <args>            - Run Composer in Docker
nfutils dock-kill                  - Stop all running containers
nfutils dock-rm                    - Remove all containers
nfutils dock-destroy               - Stop & remove all containers ⚠️
nfutils dock-nuke                  - Destroy ALL containers, images,  volumes, networks ⚠️
nfutils destroyer                  - Delete all files in current dir ⚠️
nfutils sail <args>                - Command via proxy nfutils
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

Saat menjalankan `nfutils lara-init`, alias `sail` otomatis ditambahkan ke profil shell sehingga kamu bisa menjalankan `sail up` langsung.
