# nfutils

Small bash utility for Laravel + Docker workflows (works locally or in Codespaces). Designed for bash/zsh; avoids PowerShell.

---

### Features
- Install the `nfutils` CLI into `$HOME/bin` with bash/zsh auto-completion.
- Laravel helpers: `laravel create` to bootstrap a project in Docker, `laravel init` to install Sail and wire an alias `sail`.
- Composer passthrough that runs inside Docker.
- Cleanup commands: `destroyer` wipes the current directory; `nuke` stops Docker, removes containers/images/volumes/networks, then wipes the current directory (double confirmation).
- Self-manage: `nfutils update` and `nfutils uninstall`.

### Prerequisites
- Docker CLI and daemon running; Docker Compose plugin available.
- `bash` or `zsh` if you want completions.
- `python3` available (used to update `.env` and compose files during `laravel init`).

### Install
Download and run the installer:
```
curl -s https://raw.githubusercontent.com/neflalabs/nfutils/main/nfutils.sh | bash
```
Then reload your shell: `source ~/.zshrc` or `source ~/.bashrc`.

---

### Usage
```
nfutils laravel create <dir|.>                         - Create new Laravel project inside Docker
nfutils laravel init [-p PORT] [-db|--database DRIVER] - Install Laravel Sail + alias `sail`
nfutils composer <args>                                - Run Composer in Docker
nfutils destroyer                                      - Delete all files in current dir ⚠️
nfutils nuke                                           - ☢️ Stop Docker, remove containers/images/volumes/networks, delete current dir (2x confirm)
nfutils update                                         - Update nfutils from GitHub
nfutils uninstall                                      - Remove nfutils from your system
nfutils version / -v                                   - Show nfutils version + author/repo
nfutils help                                           - Show this help message
```

`laravel init` details:
- `-p/--port` sets `APP_PORT` in `.env`.
- `-db/--database mysql|pgsql|sqlite` updates `.env` DB_* values and toggles DB services in your compose file (`compose.yaml` preferred; falls back to compose.yml/docker-compose.*). The selected DB service is enabled; the others are commented out and removed from `depends_on`.
- Sail alias `sail` is added to your shell profile automatically.

After running `laravel init`, start containers with `sail up -d`.

---

### Updates & Status
`nfutils update` pulls the latest script from GitHub. Versioning uses a timestamp + git commit (e.g., `v2025-10-27T21:52:40-g25239fb`).

---

### Auto-completion
Installer adds completions:
- Bash: `~/.bash_completion.d/nfutils`
- Zsh: `~/.zsh/completions/_nfutils` (ensure `fpath` + `compinit` in `.zshrc`)

Reload your shell or `source` your rc file to activate completions. Sail alias lives in the nfutils completion block so `nfutils uninstall` cleans it up automatically.
