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
NF_REPO_URL="https://raw.githubusercontent.com/neflalabs/nfutils/main/nfutils.sh"
NF_VERSION="v0.0.5"

bold() { echo -e "\033[1m$1\033[0m"; }
green() { echo -e "\033[32m$1\033[0m"; }
yellow() { echo -e "\033[33m$1\033[0m"; }
red() { echo -e "\033[31m$1\033[0m"; }

ensure_bashrc() {
  if [ ! -f "$BASHRC" ]; then
    touch "$BASHRC"
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

version_key() {
  local raw="${1#v}"
  IFS='.' read -r major minor patch <<<"$raw"
  major=${major:-0}
  minor=${minor:-0}
  patch=${patch:-0}
  printf "%04d%04d%04d" "$major" "$minor" "$patch"
}

version_newer() {
  [[ "$(version_key "$1")" > "$(version_key "$2")" ]]
}

pick_latest_version() {
  local latest="" line key
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    [[ "$line" =~ ^v[0-9]+(\.[0-9]+){0,2}$ ]] || continue
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
  LATEST_VERSION=$(curl -s "$NF_REPO_URL" | grep 'NF_VERSION="v' | cut -d'"' -f2 | pick_latest_version)

  if [ -z "$LATEST_VERSION" ]; then
    echo "$(red "❌ Failed to check version (network or GitHub issue).")"
    exit 1
  fi

  if [ "$LATEST_VERSION" != "$NF_VERSION" ]; then
    echo "$(yellow "📦 New version available:") $LATEST_VERSION (current: $NF_VERSION)"
    read -p "Update now? (y/N): " ans
    if [ "$ans" = "y" ]; then
      echo "$(yellow "⬇️ Downloading and installing new version...")"
      curl -s "$NF_REPO_URL" | bash
      echo "$(green "✅ nfutils updated to $LATEST_VERSION")"
    else
      echo "Aborted."
    fi
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

NF_VERSION="__NF_VERSION__"
NF_REPO_URL="__NF_REPO_URL__"

BASHRC="$HOME/.bashrc"

bold() { echo -e "\033[1m$1\033[0m"; }
green() { echo -e "\033[32m$1\033[0m"; }
red() { echo -e "\033[31m$1\033[0m"; }
yellow() { echo -e "\033[33m$1\033[0m"; }

ensure_bashrc() {
  if [ ! -f "$BASHRC" ]; then
    touch "$BASHRC"
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

version_key() {
  local raw="${1#v}"
  IFS='.' read -r major minor patch <<<"$raw"
  major=${major:-0}
  minor=${minor:-0}
  patch=${patch:-0}
  printf "%04d%04d%04d" "$major" "$minor" "$patch"
}

version_newer() {
  [[ "$(version_key "$1")" > "$(version_key "$2")" ]]
}

pick_latest_version() {
  local latest="" line key
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    [[ "$line" =~ ^v[0-9]+(\.[0-9]+){0,2}$ ]] || continue
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
  bold "NFUTILS - Laravel & Docker Developer Helper ($NF_VERSION)"
  echo ""
  echo "Usage: nfutils <command> [options]"
  echo ""
  echo "Commands:"
  echo "  laravel init <project>     - Create new Laravel project"
  echo "  laravel sail               - Initialize Sail in existing project"
  echo "  composer <args>            - Run Composer in Docker"
  echo "  docker kill                - Stop all running containers"
  echo "  docker rm                  - Remove all containers"
  echo "  docker destroy             - Stop & remove all containers"
  echo "  docker nuke                - Destroy ALL containers, images, volumes, networks"
  echo "  destroyer                  - ⚠️ Delete all files in current dir"
  echo "  sail <args>                - Proxy to ./vendor/bin/sail"
  echo "  update                     - Update nfutils from GitHub"
  echo "  uninstall                  - Remove nfutils from your system"
  echo "  --version                  - Show nfutils version"
  echo ""
}

# --- Laravel Tools ---
laravel_init() {
  docker run --rm -u "$(id -u):$(id -g)" \
    -v "$(pwd):/app" \
    -v composer_cache:/tmp/cache \
    -e COMPOSER_CACHE_DIR=/tmp/cache \
    composer create-project laravel/laravel "$@"
}

laravel_sail() {
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
  echo "Now you can run: ./vendor/bin/sail up"
}

sail_cmd() {
  if [ ! -f "./vendor/bin/sail" ]; then
    echo "$(red "❌ Laravel Sail is not installed (vendor/bin/sail missing).")"
    echo "Run: nfutils laravel sail"
    exit 1
  fi
  if [ ! -x "./vendor/bin/sail" ]; then
    chmod +x "./vendor/bin/sail"
  fi
  if [ $# -eq 0 ]; then
    ./vendor/bin/sail
  else
    ./vendor/bin/sail "$@"
  fi
}

# --- Composer in Docker ---
composer_cmd() {
  docker run --rm -u "$(id -u):$(id -g)" \
    -v "$(pwd):/app" \
    -v composer_cache:/tmp/cache \
    -e COMPOSER_CACHE_DIR=/tmp/cache \
    composer "$@"
}

# --- Docker Tools ---
docker_kill() { docker ps -q | xargs -r docker stop; }
docker_rm() { docker ps -a -q | xargs -r docker rm; }
docker_destroy() { docker ps -a -q | xargs -r docker stop && docker ps -a -q | xargs -r docker rm; }

docker_nuke() {
  echo "$(red "⚠️  This will delete ALL containers, images, volumes, and networks!")"
  read -p "Are you sure? (y/N): " ans
  [[ "$ans" == "y" ]] || { echo "Aborted."; exit 0; }
  docker ps -a -q | xargs -r docker stop
  docker ps -a -q | xargs -r docker rm
  docker images -q | xargs -r docker rmi
  docker volume ls -q | xargs -r docker volume rm
  docker network ls -q | grep -v "bridge\|host\|none" | xargs -r docker network rm
  echo "$(green "✅ Docker fully nuked.")"
}

destroyer() {
  read -p "⚠️  Delete ALL files in current directory? (y/N): " ans
  [[ "$ans" == "y" ]] || { echo "Aborted."; exit 0; }
  find . -mindepth 1 -delete
  echo "$(green "✅ Directory cleared.")"
}

# --- Self management ---
nfutils_uninstall() {
  echo "$(red "⚠️  This will remove nfutils from your system!")"
  read -p "Are you sure? (y/N): " ans
  [[ "$ans" == "y" ]] || { echo "Aborted."; exit 0; }
  rm -f "$HOME/bin/nfutils"
  if [ -f "$BASHRC" ]; then
    strip_line_from_file "$BASHRC" "HOME/bin"
  fi
  echo "$(green "✅ nfutils uninstalled.")"
}

nfutils_update() {
  echo "$(yellow "🔍 Checking for updates...")"
  LATEST_VERSION=$(curl -s "$NF_REPO_URL" | grep 'NF_VERSION="v' | cut -d'"' -f2 | pick_latest_version)
  if [ -z "$LATEST_VERSION" ]; then
    echo "$(red "❌ Unable to check version.")"
    exit 1
  fi
  if [ "$LATEST_VERSION" != "$NF_VERSION" ]; then
    echo "$(yellow "📦 New version available:") $LATEST_VERSION"
    curl -s "$NF_REPO_URL" | bash
    echo "$(green "✅ Updated to $LATEST_VERSION")"
  else
    echo "$(green "✅ Already up-to-date ($NF_VERSION)")"
  fi
}

# --- Dispatcher ---
case "$1" in
  laravel) shift; case "$1" in init) shift; laravel_init "$@";; sail) shift; laravel_sail "$@";; *) show_help;; esac;;
  composer) shift; composer_cmd "$@";;
  docker) shift; case "$1" in kill) docker_kill;; rm) docker_rm;; destroy) docker_destroy;; nuke) docker_nuke;; *) show_help;; esac;;
  destroyer) destroyer;;
  uninstall) nfutils_uninstall;;
  update) nfutils_update;;
  sail) shift; sail_cmd "$@";;
  --version|-v) echo "nfutils $NF_VERSION";;
  help|"") show_help;;
  *) echo "$(red "Unknown command: $1")"; show_help;;
esac
EOF

tmp_file=$(mktemp)
sed "s|__NF_VERSION__|$NF_VERSION|g; s|__NF_REPO_URL__|$NF_REPO_URL|g" "$NF_PATH" > "$tmp_file"
mv "$tmp_file" "$NF_PATH"

chmod +x "$NF_PATH"

ensure_bashrc

if ! grep -q "$HOME/bin" "$BASHRC"; then
  echo 'export PATH="$HOME/bin:$PATH"' >> "$BASHRC"
fi

echo ""
green "✅ nfutils $NF_VERSION installed successfully!"
echo "👉 Try: nfutils --version"
echo "👉 Or run: nfutils update"
echo ""

# ------------------------------------------------------------
# Enable bash auto-completion for nfutils
# ------------------------------------------------------------
NF_COMPLETION="$HOME/.bash_completion.d/nfutils"

mkdir -p "$(dirname "$NF_COMPLETION")"

cat > "$NF_COMPLETION" <<'EOC'
# nfutils bash completion
_nfutils_completions() {
  local cur prev opts
  COMPREPLY=()
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD-1]}"

  # subcommands
  opts="help --version update uninstall destroyer composer docker laravel sail"

  case "${prev}" in
    docker)
      COMPREPLY=( $(compgen -W "kill rm destroy nuke" -- ${cur}) )
      return 0
      ;;
    laravel)
      COMPREPLY=( $(compgen -W "init sail" -- ${cur}) )
      return 0
      ;;
    sail)
      COMPREPLY=( $(compgen -W "up down restart stop build ps" -- ${cur}) )
      return 0
      ;;
    *)
      COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
      return 0
      ;;
  esac
}
complete -F _nfutils_completions nfutils
EOC

# aktifkan langsung
if [ -f "$NF_COMPLETION" ]; then
  # pastikan di-load otomatis
  ensure_bashrc
  if ! grep -q "$NF_COMPLETION" "$BASHRC"; then
    echo "source $NF_COMPLETION" >> "$BASHRC"
  fi
  source "$NF_COMPLETION"
fi
