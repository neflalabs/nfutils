#!/usr/bin/env bash
# =========================================================
# NFUTILS INSTALLER / UNINSTALLER / UPDATER
# Auto setup Dev Utilities for Laravel + Docker
# Author: NeflaLabs
# =========================================================

set -e

NF_DIR="$HOME/bin"
NF_PATH="$NF_DIR/nfutils"
BASHRC="$HOME/.bashrc"
ZSHRC="$HOME/.zshrc"
ZSH_COMPLETION_DIR="$HOME/.zsh/completions"
ZSH_COMPLETION_PATH="$ZSH_COMPLETION_DIR/_nfutils"
NF_REPO_URL="https://raw.githubusercontent.com/neflalabs/nfutils/main/nfutils.sh"
NF_VERSION="v2025-11-08T04:15:09-g6330bc9"

bold() { echo -e "\033[1m$1\033[0m"; }
green() { echo -e "\033[32m$1\033[0m"; }
yellow() { echo -e "\033[33m$1\033[0m"; }
red() { echo -e "\033[31m$1\033[0m"; }


ensure_rc_file() {
  local file="$1"
  if [ ! -f "$file" ]; then
    touch "$file"
  fi
}

ensure_bashrc() { ensure_rc_file "$BASHRC"; }
ensure_zshrc() { ensure_rc_file "$ZSHRC"; }

cache_busted_url() {
  local base="$1"
  local sep="?"
  [[ "$base" == *\?* ]] && sep="&"
  printf "%s%scb=%s" "$base" "$sep" "$(date +%s%N)"
}

reload_current_shell_rc() {
  local rc=""
  if [ -n "${ZSH_VERSION:-}" ]; then
    rc="$ZSHRC"
  elif [ -n "${BASH_VERSION:-}" ]; then
    rc="$BASHRC"
  else
    case "$(basename "${SHELL:-}")" in
      zsh) rc="$ZSHRC" ;;
      bash) rc="$BASHRC" ;;
    esac
  fi
  if [ -n "$rc" ] && [ -f "$rc" ]; then
    # shellcheck disable=SC1090
    . "$rc"
  fi
}

ensure_spacing_before_append() {
  local file="$1"
  [ -s "$file" ] || return 0
  if [ "$(tail -c1 "$file" 2>/dev/null)" != $'\n' ]; then
    printf '\n' >> "$file"
  fi
  local last_line
  last_line=$(tail -n1 "$file")
  if [ -n "$last_line" ]; then
    printf '\n' >> "$file"
  fi
}

ensure_line_block_spacing() {
  local file="$1"
  local line="$2"
  [ -f "$file" ] || return 0
  local tmp
  tmp=$(mktemp)
  if awk -v target="$line" '
    BEGIN { prev_blank=1; changed=0 }
    {
      if ($0 == target) {
        if (!prev_blank) {
          print ""
          prev_blank=1
          changed=1
        }
        print $0
        prev_blank=0
      } else {
        print $0
        prev_blank = ($0 == "") ? 1 : 0
      }
    }
    END { exit(changed ? 0 : 1) }
  ' "$file" > "$tmp"; then
    mv "$tmp" "$file"
  else
    rm -f "$tmp"
  fi
}

append_unique_line() {
  local file="$1"
  local line="$2"
  local spacing="${3:-with_spacing}"
  ensure_rc_file "$file"
  if ! grep -Fxq "$line" "$file"; then
    if [ "$spacing" = "with_spacing" ]; then
      ensure_spacing_before_append "$file"
    fi
    printf '%s\n' "$line" >> "$file"
  fi
  if [ "$spacing" = "with_spacing" ]; then
    ensure_line_block_spacing "$file" "$line"
  fi
}

strip_line_from_file() {
  local file="$1"
  local substring="$2"
  [ -f "$file" ] || return 0
  local tmp
  tmp=$(mktemp)
  if grep -F -v "$substring" "$file" > "$tmp"; then
    mv "$tmp" "$file"
  else
    rm -f "$tmp"
    : > "$file"
  fi
}

strip_block_between_markers() {
  local file="$1"
  local start="$2"
  local end="$3"
  [ -f "$file" ] || return 0
  local tmp
  tmp=$(mktemp)
  awk -v start="$start" -v end="$end" '
    $0 == start {skip=1; next}
    $0 == end {skip=0; next}
    skip {next}
    {print}
  ' "$file" > "$tmp"
  mv "$tmp" "$file"
}

version_key() {
  local ver="$1"
  if [[ "$ver" =~ ^v([0-9]+)(\.[0-9]+){0,2}$ ]]; then
    local raw="${ver#v}"
    IFS='.' read -r major minor patch <<<"$raw"
    major=${major:-0}
    minor=${minor:-0}
    patch=${patch:-0}
    printf "0%04d%04d%04d" "$major" "$minor" "$patch"
  elif [[ "$ver" =~ ^v[0-9]{4}-[0-9]{2}-[0-9]{2}(T[0-9]{2}:[0-9]{2}:[0-9]{2})?-g[0-9a-fA-F]+$ ]]; then
    local raw="${ver#v}"
    raw=${raw//[-:T]/}
    printf "1%s" "$raw"
  else
    printf "9%s" "$ver"
  fi
}

version_newer() {
  [[ "$(version_key "$1")" > "$(version_key "$2")" ]]
}

pick_latest_version() {
  local latest="" line key
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    if [[ "$line" =~ ^v([0-9]+)(\.[0-9]+){0,2}$ || "$line" =~ ^v[0-9]{4}-[0-9]{2}-[0-9]{2}(T[0-9]{2}:[0-9]{2}:[0-9]{2})?-g[0-9a-fA-F]+$ ]]; then
      :
    else
      continue
    fi
    key=$(version_key "$line") || continue
    if [ -z "$latest" ] || version_newer "$line" "$latest"; then
      latest="$line"
    fi
  done
  if [ -n "$latest" ]; then
    echo "$latest"
  else
    echo "v0.0.1"
  fi
}

# ---------------------------------------------
# UNINSTALL FUNCTION
# ---------------------------------------------
uninstall_nfutils() {
  echo ""
  red "⚠️  Uninstalling nfutils from your system..."
  read -p "Are you sure you want to continue? (y/N): " ans
  [[ "$ans" == "y" ]] || { echo "Aborted."; exit 0; }

  if [ -f "$NF_PATH" ]; then
    rm -f "$NF_PATH"
    echo "$(green "✔ Removed:") $NF_PATH"
  else
    echo "$(yellow "ℹ nfutils not found in:") $NF_PATH"
  fi

  if [ -f "$BASHRC" ] && grep -q 'HOME/bin' "$BASHRC"; then
    strip_line_from_file "$BASHRC" "HOME/bin"
    echo "$(green "✔ Cleaned PATH entry from .bashrc")"
  fi
  if [ -f "$BASHRC" ]; then
    strip_line_from_file "$BASHRC" ".bash_completion.d/nfutils"
  fi

  if [ -f "$ZSHRC" ] && grep -q 'HOME/bin' "$ZSHRC"; then
    strip_line_from_file "$ZSHRC" "HOME/bin"
    echo "$(green "✔ Cleaned PATH entry from .zshrc")"
  fi
  strip_block_between_markers "$ZSHRC" "# nfutils zsh completion start" "# nfutils zsh completion end"
  rm -f "$ZSH_COMPLETION_PATH"

  echo "$(green "✅ nfutils uninstalled successfully!")"
  echo "You can reload your shell with: source ~/.bashrc"
  exit 0
}

# ---------------------------------------------
# UPDATE FUNCTION
# ---------------------------------------------
update_nfutils() {
  echo ""
  bold "🔍 Checking for updates..."
  local version_url
  version_url=$(cache_busted_url "$NF_REPO_URL")
  LATEST_VERSION=$(curl -s "$version_url" | grep 'NF_VERSION="v' | cut -d'"' -f2 | pick_latest_version)

  if [ -z "$LATEST_VERSION" ]; then
    echo "$(red "❌ Failed to check version (network or GitHub issue).")"
    exit 1
  fi

  if version_newer "$LATEST_VERSION" "$NF_VERSION"; then
    echo "$(yellow "📦 New version available:") $LATEST_VERSION (current: $NF_VERSION)"
    read -p "Update now? (y/N): " ans
    if [ "$ans" = "y" ]; then
      echo "$(yellow "⬇️ Downloading and installing new version...")"
      local install_url
      install_url=$(cache_busted_url "$NF_REPO_URL")
      curl -s "$install_url" | bash
      reload_current_shell_rc
      echo "$(green "✅ nfutils updated to $LATEST_VERSION")"
      exit 0
    else
      echo "Aborted."
    fi
  elif version_newer "$NF_VERSION" "$LATEST_VERSION"; then
    echo "$(green "✅ You are ahead (local $NF_VERSION, remote $LATEST_VERSION)")"
  else
    echo "$(green "✅ You are already using the latest version ($NF_VERSION)")"
  fi
  exit 0
}

# ---------------------------------------------
# HANDLE FLAGS
# ---------------------------------------------
if [[ "$1" == "uninstall" ]]; then
  uninstall_nfutils
elif [[ "$1" == "update" ]]; then
  update_nfutils
fi

# ---------------------------------------------
# INSTALL FUNCTION
# ---------------------------------------------
echo ""
bold "🧰 Installing nfutils $NF_VERSION ..."
mkdir -p "$NF_DIR"
cat > "$NF_PATH" <<'EOF'
#!/usr/bin/env bash
set -e

NF_VERSION="v2025-11-08T04:15:09-g6330bc9"
NF_REPO_URL="https://raw.githubusercontent.com/neflalabs/nfutils/main/nfutils.sh"

BASHRC="$HOME/.bashrc"
ZSHRC="$HOME/.zshrc"
ZSH_COMPLETION_DIR="$HOME/.zsh/completions"
ZSH_COMPLETION_PATH="$ZSH_COMPLETION_DIR/_nfutils"

bold() { echo -e "\033[1m$1\033[0m"; }
green() { echo -e "\033[32m$1\033[0m"; }
red() { echo -e "\033[31m$1\033[0m"; }
yellow() { echo -e "\033[33m$1\033[0m"; }

ensure_rc_file() {
  local file="$1"
  if [ ! -f "$file" ]; then
    touch "$file"
  fi
}

ensure_bashrc() { ensure_rc_file "$BASHRC"; }
ensure_zshrc() { ensure_rc_file "$ZSHRC"; }

cache_busted_url() {
  local base="$1"
  local sep="?"
  [[ "$base" == *\?* ]] && sep="&"
  printf "%s%scb=%s" "$base" "$sep" "$(date +%s%N)"
}

reload_current_shell_rc() {
  local rc=""
  if [ -n "${ZSH_VERSION:-}" ]; then
    rc="$ZSHRC"
  elif [ -n "${BASH_VERSION:-}" ]; then
    rc="$BASHRC"
  else
    case "$(basename "${SHELL:-}")" in
      zsh) rc="$ZSHRC" ;;
      bash) rc="$BASHRC" ;;
    esac
  fi
  if [ -n "$rc" ] && [ -f "$rc" ]; then
    # shellcheck disable=SC1090
    . "$rc"
  fi
}

ensure_spacing_before_append() {
  local file="$1"
  [ -s "$file" ] || return 0
  if [ "$(tail -c1 "$file" 2>/dev/null)" != $'\n' ]; then
    printf '\n' >> "$file"
  fi
  local last_line
  last_line=$(tail -n1 "$file")
  if [ -n "$last_line" ]; then
    printf '\n' >> "$file"
  fi
}

ensure_line_block_spacing() {
  local file="$1"
  local line="$2"
  [ -f "$file" ] || return 0
  local tmp
  tmp=$(mktemp)
  if awk -v target="$line" '
    BEGIN { prev_blank=1; changed=0 }
    {
      if ($0 == target) {
        if (!prev_blank) {
          print ""
          prev_blank=1
          changed=1
        }
        print $0
        prev_blank=0
      } else {
        print $0
        prev_blank = ($0 == "") ? 1 : 0
      }
    }
    END { exit(changed ? 0 : 1) }
  ' "$file" > "$tmp"; then
    mv "$tmp" "$file"
  else
    rm -f "$tmp"
  fi
}

append_unique_line() {
  local file="$1"
  local line="$2"
  local spacing="${3:-with_spacing}"
  ensure_rc_file "$file"
  if ! grep -Fxq "$line" "$file"; then
    if [ "$spacing" = "with_spacing" ]; then
      ensure_spacing_before_append "$file"
    fi
    printf '%s\n' "$line" >> "$file"
  fi
  if [ "$spacing" = "with_spacing" ]; then
    ensure_line_block_spacing "$file" "$line"
  fi
}

has_cmd() {
  command -v "$1" >/dev/null 2>&1
}

docker_install_hint() {
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    case "$ID" in
      ubuntu|debian)
        echo "  sudo apt-get update && sudo apt-get install docker.io docker-compose-plugin"
        ;;
      arch|manjaro)
        echo "  sudo pacman -S docker docker-compose"
        ;;
      fedora)
        echo "  sudo dnf install docker docker-compose-plugin"
        ;;
      centos|rhel)
        echo "  sudo yum install docker docker-compose-plugin"
        ;;
      opensuse*|sles)
        echo "  sudo zypper install docker docker-compose"
        ;;
      *)
        echo "  (lihat dokumentasi resmi Docker untuk distro $ID)"
        ;;
    esac
  else
    echo "  (lihat dokumentasi resmi Docker untuk instruksi instalasi)"
  fi
}

has_docker_compose() {
  docker compose version >/dev/null 2>&1 || docker-compose --version >/dev/null 2>&1
}

ensure_docker() {
  if ! has_cmd docker; then
    echo "$(red "❌ Docker CLI tidak ditemukan.")"
    echo "Install Docker menggunakan perintah seperti:"
    docker_install_hint
    echo "Dokumentasi: https://docs.docker.com/engine/install/"
    exit 1
  fi

  if ! docker info >/dev/null 2>&1; then
    echo "$(red "❌ Docker daemon tidak berjalan.")"
    echo "Pastikan layanan Docker aktif, contoh: sudo systemctl start docker"
    exit 1
  fi

  if ! has_docker_compose; then
    echo "$(red "❌ Docker Compose tidak tersedia.")"
    echo "Install plugin docker compose (docker compose) atau docker-compose CLI."
    exit 1
  fi

  if ! id -Gn "$USER" | tr ' ' '\n' | grep -qx docker; then
    echo "$(yellow "ℹ Tambahkan user ke grup docker agar tidak perlu sudo: sudo usermod -aG docker $USER")"
  fi
}

strip_line_from_file() {
  local file="$1"
  local substring="$2"
  [ -f "$file" ] || return 0
  local tmp
  tmp=$(mktemp)
  if grep -F -v "$substring" "$file" > "$tmp"; then
    mv "$tmp" "$file"
  else
    rm -f "$tmp"
    : > "$file"
  fi
}

strip_block_between_markers() {
  local file="$1"
  local start="$2"
  local end="$3"
  [ -f "$file" ] || return 0
  local tmp
  tmp=$(mktemp)
  awk -v start="$start" -v end="$end" '
    $0 == start {skip=1; next}
    $0 == end {skip=0; next}
    skip {next}
    {print}
  ' "$file" > "$tmp"
  mv "$tmp" "$file"
}

version_key() {
  local ver="$1"
  if [[ "$ver" =~ ^v([0-9]+)(\.[0-9]+){0,2}$ ]]; then
    local raw="${ver#v}"
    IFS='.' read -r major minor patch <<<"$raw"
    major=${major:-0}
    minor=${minor:-0}
    patch=${patch:-0}
    printf "0%04d%04d%04d" "$major" "$minor" "$patch"
  elif [[ "$ver" =~ ^v[0-9]{4}-[0-9]{2}-[0-9]{2}(T[0-9]{2}:[0-9]{2}:[0-9]{2})?-g[0-9a-fA-F]+$ ]]; then
    local raw="${ver#v}"
    raw=${raw//[-:T]/}
    printf "1%s" "$raw"
  else
    printf "9%s" "$ver"
  fi
}

version_newer() {
  [[ "$(version_key "$1")" > "$(version_key "$2")" ]]
}

pick_latest_version() {
  local latest="" line key
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    if [[ "$line" =~ ^v([0-9]+)(\.[0-9]+){0,2}$ || "$line" =~ ^v[0-9]{4}-[0-9]{2}-[0-9]{2}(T[0-9]{2}:[0-9]{2}:[0-9]{2})?-g[0-9a-fA-F]+$ ]]; then
      :
    else
      continue
    fi
    key=$(version_key "$line") || continue
    if [ -z "$latest" ] || version_newer "$line" "$latest"; then
      latest="$line"
    fi
  done
  if [ -n "$latest" ]; then
    echo "$latest"
  else
    echo "v0.0.1"
  fi
}

show_help() {
  echo ""
  bold "NFUTILS - Laravel inside Docker Script Helper ($NF_VERSION)"
  echo "by NeflaLabs - https://npx.my.id"
  echo ""
  echo "Usage: nfutils <command> [options]"
  echo ""
  echo "Commands:"
  echo "  laravel create <dir|.>     - Create new Laravel project"
  echo "  laravel init [-p PORT]     - Initialize Sail in existing project"
  echo "  composer <args>            - Run Composer in Docker"
  echo "  destroyer                  - ⚠️ Delete all files in current dir"
  echo "  nuke                       - ☢️  Stop Docker, remove containers/images, wipe folder"
  echo "  update                     - Update nfutils from GitHub"
  echo "  uninstall                  - Remove nfutils from your system"
  echo "  version / -v               - Show nfutils version"
  echo ""
}
# --- Laravel Tools ---
laravel_create() {
  ensure_docker
  local target="${1:-}"
  if [ -z "$target" ]; then
    echo "$(red "❌ Project directory is required (use '.' for current directory).")"
    laravel_show_usage
    exit 1
  fi
  shift || true
  docker run --rm -u "$(id -u):$(id -g)" \
    -v "$(pwd):/app" \
    -v composer_cache:/tmp/cache \
    -e COMPOSER_CACHE_DIR=/tmp/cache \
    composer create-project laravel/laravel "$target" "$@"
}

laravel_sail() {
  ensure_docker

  local port=""
  local sail_args=()
  while [ $# -gt 0 ]; do
    case "$1" in
      -p|--port)
        if [[ -n "${2:-}" && "$2" =~ ^[0-9]+$ ]]; then
          port="$2"
          shift 2
          continue
        else
          echo "$(red "❌ Invalid port value for -p/--port.")"
          exit 1
        fi
        ;;
      --port=*)
        local value="${1#--port=}"
        if [[ "$value" =~ ^[0-9]+$ ]]; then
          port="$value"
          shift
          continue
        else
          echo "$(red "❌ Invalid port value for --port.")"
          exit 1
        fi
        ;;
      --)
        shift
        sail_args+=("$@")
        break
        ;;
      *)
        sail_args+=("$1")
        shift
        ;;
    esac
  done
  set -- "${sail_args[@]}"

  if [ ! -f "artisan" ]; then
    echo "$(red "❌ This is not a Laravel project (artisan not found).")"
    exit 1
  fi
  echo "$(yellow "🚀 Initializing Laravel Sail...")"
  if ! grep -q "laravel/sail" composer.json 2>/dev/null; then
    echo "$(yellow "🧩 Installing laravel/sail via composer...")"
    docker run --rm -u "$(id -u):$(id -g)" \
      -v "$(pwd):/app" \
      -v composer_cache:/tmp/cache \
      -e COMPOSER_CACHE_DIR=/tmp/cache \
      composer require laravel/sail --dev
  fi
  docker run --rm -u "$(id -u):$(id -g)" \
    -v "$(pwd):/var/www/html" \
    -w /var/www/html \
    laravelsail/php84-composer:latest php artisan sail:install "$@"
  echo "$(green "✅ Laravel Sail installed successfully!")"
  local alias_line="alias sail='sh \$([ -f sail ] && echo sail || echo vendor/bin/sail)'"
  append_unique_line "$BASHRC" "$alias_line"
  echo "$(green "✅ Alias 'sail' tersedia di shell profile (bash & zsh).")"
  if [ -f ".env" ]; then
    python3 - <<'PY_ENV'
from pathlib import Path

env_path = Path('.env')
lines = env_path.read_text().splitlines()
out = []
inserted_mysql = False

for line in lines:
    if line.startswith('MYSQL_EXTRA_OPTIONS='):
        if not inserted_mysql:
            out.append('MYSQL_EXTRA_OPTIONS=null')
            inserted_mysql = True
        continue
    out.append(line)
    if line.startswith('APP_FAKER_LOCALE=') and not inserted_mysql:
        out.append('MYSQL_EXTRA_OPTIONS=null')
        inserted_mysql = True

if not inserted_mysql:
    out.append('MYSQL_EXTRA_OPTIONS=null')

env_path.write_text("\n".join(out) + "\n")
PY_ENV
  fi

  if [ -n "$port" ] && [ -f ".env" ]; then
    python3 - "$port" <<'PY'
import sys
from pathlib import Path

port = sys.argv[1]
env_path = Path(".env")
if not env_path.exists():
    raise SystemExit(0)
lines = env_path.read_text().splitlines()
out = []
inserted = False
for line in lines:
    if line.startswith("APP_PORT="):
        if not inserted:
            out.append(f"APP_PORT={port}")
            inserted = True
        else:
            continue
    else:
        out.append(line)
    if line.startswith("APP_URL=") and not inserted:
        out.append(f"APP_PORT={port}")
        inserted = True
if not inserted:
    out.append(f"APP_PORT={port}")
env_path.write_text("\n".join(out) + "\n")
PY
    echo "$(green "✅ APP_PORT=$port ditulis ke .env")"
  elif [ -n "$port" ]; then
    echo "$(yellow "ℹ .env tidak ditemukan, APP_PORT tidak diubah.")"
  fi
  echo "Now you can run: sail up"
}

laravel_show_usage() {
  echo "Usage:"
  echo "  nfutils laravel create <directory|.>"
  echo "  nfutils laravel init [-p PORT] [sail options]"
}

laravel_cmd() {
  local subcommand="${1:-}"
  shift || true

  case "$subcommand" in
    create)
      local target="${1:-}"
      if [ -z "$target" ]; then
        echo "$(red "❌ Project directory is required for 'laravel create'.")"
        laravel_show_usage
        exit 1
      fi
      laravel_create "$@"
      ;;
    init)
      laravel_sail "$@"
      ;;
    ""|-h|--help|help)
      laravel_show_usage
      ;;
    *)
      echo "$(red "❌ Unknown laravel subcommand: $subcommand")"
      laravel_show_usage
      exit 1
      ;;
  esac
}
# --- Dangerous Operations ---
destroyer() {
  read -p "⚠️  Delete ALL files in current directory? (y/N): " ans
  [[ "$ans" == "y" ]] || { echo "Aborted."; exit 0; }
  find . -mindepth 1 -delete
  echo "$(green "✅ Directory cleared.")"
}

nuke_everything() {
  echo "$(red "☢️  WARNING: This will stop Docker, remove containers/images, and delete EVERYTHING in $(pwd)")"
  read -p "Type 'nuke' to continue: " first
  [[ "$first" == "nuke" ]] || { echo "Aborted."; exit 1; }
  read -p "This action is irreversible. Type 'DELETE' to proceed: " second
  [[ "$second" == "DELETE" ]] || { echo "Aborted."; exit 1; }

  ensure_docker

  echo "$(yellow "🛑 Stopping running containers...")"
  docker ps -q | xargs -r docker stop >/dev/null 2>&1 || true

  echo "$(yellow "🧹 Removing containers...")"
  docker ps -aq | xargs -r docker rm >/dev/null 2>&1 || true

  echo "$(yellow "🧽 Removing images...")"
  docker images -q | xargs -r docker rmi -f >/dev/null 2>&1 || true

  echo "$(yellow "🗂  Removing volumes...")"
  docker volume ls -q | xargs -r docker volume rm >/dev/null 2>&1 || true

  echo "$(yellow "🌐 Removing custom networks...")"
  docker network ls -q | grep -Ev '^(bridge|host|none)$' | xargs -r docker network rm >/dev/null 2>&1 || true

  echo "$(yellow "🧨 Deleting current directory contents...")"
  find . -mindepth 1 -delete

  echo "$(green "✅ nfutils nuke completed. Directory wiped clean.")"
}
# --- Composer in Docker ---
composer_cmd() {
  ensure_docker
  docker run --rm -u "$(id -u):$(id -g)" \
    -v "$(pwd):/app" \
    -v composer_cache:/tmp/cache \
    -e COMPOSER_CACHE_DIR=/tmp/cache \
    composer "$@"
}

# --- Self management ---
nfutils_uninstall() {
  echo "$(red "⚠️  This will remove nfutils from your system!")"
  read -p "Are you sure? (y/N): " ans
  [[ "$ans" == "y" ]] || { echo "Aborted."; exit 0; }
  rm -f "$HOME/bin/nfutils"
  if [ -f "$BASHRC" ]; then
    strip_line_from_file "$BASHRC" "HOME/bin"
    strip_line_from_file "$BASHRC" ".bash_completion.d/nfutils"
  fi
  if [ -f "$ZSHRC" ]; then
    strip_line_from_file "$ZSHRC" "HOME/bin"
    strip_block_between_markers "$ZSHRC" "# nfutils zsh completion start" "# nfutils zsh completion end"
  fi
  rm -f "$ZSH_COMPLETION_PATH"
  echo "$(green "✅ nfutils uninstalled.")"
}

nfutils_update() {
  echo "$(yellow "🔍 Checking for updates...")"
  local version_url
  version_url=$(cache_busted_url "$NF_REPO_URL")
  LATEST_VERSION=$(curl -s "$version_url" | grep 'NF_VERSION="v' | cut -d'"' -f2 | pick_latest_version)
  if [ -z "$LATEST_VERSION" ]; then
    echo "$(red "❌ Unable to check version.")"
    exit 1
  fi
  if version_newer "$LATEST_VERSION" "$NF_VERSION"; then
    echo "$(yellow "📦 New version available:") $LATEST_VERSION"
    local install_url
    install_url=$(cache_busted_url "$NF_REPO_URL")
    curl -s "$install_url" | bash
    reload_current_shell_rc
    echo "$(green "✅ Updated to $LATEST_VERSION")"
    exit 0
  elif version_newer "$NF_VERSION" "$LATEST_VERSION"; then
    echo "$(green "✅ Anda sudah di depan (local $NF_VERSION, remote $LATEST_VERSION)")"
  else
    echo "$(green "✅ Already up-to-date ($NF_VERSION)")"
  fi
}
case "$1" in
  laravel) shift; laravel_cmd "$@";;
  composer) shift; composer_cmd "$@";;
  destroyer) destroyer;;
  nuke) nuke_everything;;
  uninstall) nfutils_uninstall;;
  update) nfutils_update;;
  version|-v) echo "nfutils $NF_VERSION";;
  "") show_help;;
  *) echo "$(red "Unknown command: $1")"; show_help;;
esac
EOF
tmp_file=$(mktemp)
sed "s|v2025-11-08T04:15:09-g6330bc9|$NF_VERSION|g; s|https://raw.githubusercontent.com/neflalabs/nfutils/main/nfutils.sh|$NF_REPO_URL|g" "$NF_PATH" > "$tmp_file"
mv "$tmp_file" "$NF_PATH"

chmod +x "$NF_PATH"

ensure_bashrc
append_unique_line "$BASHRC" 'export PATH="$HOME/bin:$PATH"'
ensure_zshrc
append_unique_line "$ZSHRC" 'export PATH="$HOME/bin:$PATH"'

echo ""
green "✅ nfutils $NF_VERSION installed successfully!"
echo "👉 Try: nfutils --version"
echo "👉 Or run: nfutils update"
echo ""

# ------------------------------------------------------------
# Enable shell completions for nfutils
# ------------------------------------------------------------
NF_COMPLETION="$HOME/.bash_completion.d/nfutils"

mkdir -p "$(dirname "$NF_COMPLETION")"
mkdir -p "$ZSH_COMPLETION_DIR"

cat > "$NF_COMPLETION" <<'EOC'
# nfutils bash completion
_nfutils_completions() {
  local cur prev cmd subcmd
  COMPREPLY=()
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD-1]}"
  cmd="${COMP_WORDS[1]:-}"

  local top_commands="laravel composer destroyer nuke update uninstall version help"
  local laravel_subcommands="create init help"

  if [ $COMP_CWORD -eq 1 ]; then
    COMPREPLY=( $(compgen -W "${top_commands}" -- "${cur}") )
    return 0
  fi

  case "${cmd}" in
    laravel)
      if [ $COMP_CWORD -eq 2 ]; then
        COMPREPLY=( $(compgen -W "${laravel_subcommands}" -- "${cur}") )
        return 0
      fi
      subcmd="${COMP_WORDS[2]:-}"
      case "${subcmd}" in
        create)
          if [ $COMP_CWORD -eq 3 ]; then
            local dirs=()
            if [[ "." == "${cur}"* ]]; then
              dirs+=(".")
            fi
            while IFS= read -r line; do
              dirs+=("$line")
            done < <(compgen -d -- "${cur}")
            COMPREPLY=("${dirs[@]}")
            if type compopt >/dev/null 2>&1; then
              compopt -o dirnames 2>/dev/null
            fi
          fi
          return 0
          ;;
        init)
          if [[ "$prev" == "-p" || "$prev" == "--port" ]]; then
            COMPREPLY=()
            return 0
          fi
          if [ $COMP_CWORD -eq 3 ]; then
            COMPREPLY=( $(compgen -W "-p --port" -- "${cur}") )
            return 0
          fi
          return 0
          ;;
      esac
      return 0
      ;;
  esac

  COMPREPLY=()
}
complete -F _nfutils_completions nfutils

EOC

cat > "$ZSH_COMPLETION_PATH" <<'EOZ'
#compdef nfutils

_nfutils() {
  local -a top_commands laravel_sub
  top_commands=(laravel composer destroyer nuke update uninstall version help)
  laravel_sub=(create init help)

  if (( CURRENT == 2 )); then
    _describe -t commands 'nfutils commands' top_commands
    return
  fi

  case ${words[2]} in
    laravel)
      if (( CURRENT == 3 )); then
        _describe -t laravel_subcommands 'laravel subcommands' laravel_sub
        return
      fi
      case ${words[3]} in
        create)
          _files -/
          ;;
        init|'')
          _values 'laravel init options' \
            '-p[set custom Sail port]' \
            '--port=[set custom Sail port]'
          ;;
      esac
      ;;
  esac
}

_nfutils "$@"

EOZ

# aktifkan langsung
if [ -f "$NF_COMPLETION" ]; then
  ensure_bashrc
  append_unique_line "$BASHRC" "source $NF_COMPLETION"
  source "$NF_COMPLETION"
fi

if [ -f "$ZSH_COMPLETION_PATH" ]; then
  ensure_zshrc
  strip_block_between_markers "$ZSHRC" "# nfutils zsh completion start" "# nfutils zsh completion end"
  ensure_spacing_before_append "$ZSHRC"
  cat >> "$ZSHRC" <<'EOZ'
# nfutils zsh completion start
alias sail='sh $([ -f sail ] && echo sail || echo vendor/bin/sail)'
fpath=("$HOME/.zsh/completions" $fpath)
autoload -Uz compinit && compinit
# nfutils zsh completion end
EOZ
fi
