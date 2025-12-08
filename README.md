# nfutils

Small bash utility for Laravel + Docker workflows (works locally or in Codespaces). Designed for bash/zsh; avoids PowerShell.

---

## Features

- Install the `nfutils` CLI into `$HOME/bin` with bash/zsh auto-completion
- Laravel helpers: `laravel create` to bootstrap a project in Docker, `laravel init` to install Sail and configure database
- Composer passthrough that runs inside Docker
- Cleanup commands: `destroyer` wipes the current directory; `nuke` stops Docker, removes containers/images/volumes/networks, then wipes the current directory (double confirmation)
- Self-manage: `nfutils update` and `nfutils uninstall`

---

## Prerequisites

- Docker CLI and daemon running; Docker Compose plugin available
- `bash` or `zsh` if you want completions
- `python3` available (used to update `.env` and compose files during `laravel init`)

---

## Install

Download and run the installer:

```bash
curl -fsSL https://raw.githubusercontent.com/neflalabs/nfutils/main/nfutils.sh | bash
```

Then reload your shell:

```bash
source ~/.zshrc   # for zsh
source ~/.bashrc  # for bash
```

---

## Usage

```
nfutils laravel create <dir|.>                         Create new Laravel project inside Docker
nfutils laravel init [-p PORT] [-db|--database DRIVER] Install Laravel Sail + alias `sail`
nfutils composer <args>                                Run Composer in Docker
nfutils destroyer                                      Delete all files in current dir ⚠️
nfutils nuke                                           ☢️ Full cleanup (2x confirm)
nfutils update                                         Update nfutils from GitHub
nfutils uninstall                                      Remove nfutils from your system
nfutils version | -v                                   Show version + author/repo
nfutils help                                           Show help message
```

### laravel init Options

| Option                   | Description                                        |
| ------------------------ | -------------------------------------------------- |
| `-p, --port PORT`        | Set `APP_PORT` in `.env` (e.g., `-p 8080`)         |
| `-db, --database DRIVER` | Set database driver: `mysql`, `pgsql`, or `sqlite` |

**What it does:**
- Updates `.env` with correct DB_* values
- Toggles DB services in compose file (`compose.yaml` preferred)
- Selected DB service is enabled; others are commented out
- Sail alias `sail` is added to your shell profile automatically

**Example:**

```bash
# Create new Laravel project
nfutils laravel create myapp
cd myapp

# Initialize with PostgreSQL on port 8080
nfutils laravel init -p 8080 -db pgsql

# Start containers
sail up -d
```

---

## Updates & Versioning

Run `nfutils update` to pull the latest script from GitHub.

Versioning uses timestamp + git commit format:
```
v2024-06-04T12:34:56Z-gabc1234
```

---

## Auto-completion

Installer automatically sets up completions:

| Shell | Location                       |
| ----- | ------------------------------ |
| Bash  | `~/.bash_completion.d/nfutils` |
| Zsh   | `~/.zsh/completions/_nfutils`  |

Reload your shell or `source` your rc file to activate completions.

> **Note:** The `sail` alias is managed within the nfutils completion block, so `nfutils uninstall` cleans it up automatically.

---

## For Developers

If you want to contribute or modify nfutils:

1. **Clone the repo:**
   ```bash
   git clone https://github.com/neflalabs/nfutils.git
   cd nfutils
   ```

2. **Source structure (not included in releases):**
   - `src/` - Source modules (installer, CLI components, completions)
   - `scripts/` - Build scripts

3. **Build the distribution script:**
   ```bash
   bash scripts/build.sh
   ```
   This concatenates all source modules into `nfutils.sh` with proper version stamping.

4. **Test locally:**
   ```bash
   ./nfutils.sh  # Run installer
   nfutils help  # Test installed CLI
   ```

---

## License

MIT License - see [LICENSE](LICENSE)

---

**Author:** [NeflaLabs](https://npx.my.id)  
**Repository:** https://github.com/neflalabs/nfutils
