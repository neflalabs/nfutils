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
NF_VERSION="v2025-10-27T03:58:19-g31c347c"

bold() { echo -e "\033[1m$1\033[0m"; }
green() { echo -e "\033[32m$1\033[0m"; }
yellow() { echo -e "\033[33m$1\033[0m"; }
red() { echo -e "\033[31m$1\033[0m"; }

warn_deprecated() {
  yellow "Deprecated: gunakan '$2' menggantikan '$1'"
}

ensure_rc_file() {
  local file="$1"
  if [ ! -f "$file" ]; then
    touch "$file"
  fi
}

ensure_bashrc() { ensure_rc_file "$BASHRC"; }
ensure_zshrc() { ensure_rc_file "$ZSHRC"; }

append_unique_line() {
  local file="$1"
  local line="$2"
  ensure_rc_file "$file"
  grep -Fxq "$line" "$file" || printf '%s\n' "$line" >> "$file"
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
  LATEST_VERSION=$(curl -s "$NF_REPO_URL" | grep 'NF_VERSION="v' | cut -d'"' -f2 | pick_latest_version)

  if [ -z "$LATEST_VERSION" ]; then
    echo "$(red "❌ Failed to check version (network or GitHub issue).")"
    exit 1
  fi

  if version_newer "$LATEST_VERSION" "$NF_VERSION"; then
    echo "$(yellow "📦 New version available:") $LATEST_VERSION (current: $NF_VERSION)"
    read -p "Update now? (y/N): " ans
    if [ "$ans" = "y" ]; then
      echo "$(yellow "⬇️ Downloading and installing new version...")"
      curl -s "$NF_REPO_URL" | bash
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

NF_VERSION="__NF_VERSION__"
NF_REPO_URL="__NF_REPO_URL__"

BASHRC="$HOME/.bashrc"
ZSHRC="$HOME/.zshrc"
ZSH_COMPLETION_DIR="$HOME/.zsh/completions"
ZSH_COMPLETION_PATH="$ZSH_COMPLETION_DIR/_nfutils"

bold() { echo -e "\033[1m$1\033[0m"; }
green() { echo -e "\033[32m$1\033[0m"; }
red() { echo -e "\033[31m$1\033[0m"; }
yellow() { echo -e "\033[33m$1\033[0m"; }

warn_deprecated() {
  yellow "Deprecated: gunakan '$2' menggantikan '$1'"
}

ensure_rc_file() {
  local file="$1"
  if [ ! -f "$file" ]; then
    touch "$file"
  fi
}

ensure_bashrc() { ensure_rc_file "$BASHRC"; }
ensure_zshrc() { ensure_rc_file "$ZSHRC"; }

append_unique_line() {
  local file="$1"
  local line="$2"
  ensure_rc_file "$file"
  grep -Fxq "$line" "$file" || printf '%s\n' "$line" >> "$file"
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
  bold "NFUTILS - Laravel & Docker Developer Helper ($NF_VERSION)"
  echo ""
  echo "Usage: nfutils <command> [options]"
  echo ""
  echo "Commands:"
  echo "  lara-create <project>      - Create new Laravel project"
  echo "  lara-init [-p PORT]        - Initialize Sail in existing project"
  echo "  composer <args>            - Run Composer in Docker"
  echo "  dock-kill                  - Stop all running containers"
  echo "  dock-rm                    - Remove all containers"
  echo "  dock-destroy               - Stop & remove all containers"
  echo "  dock-nuke                  - Destroy ALL containers, images, volumes, networks"
  echo "  destroyer                  - ⚠️ Delete all files in current dir"
  echo "  sail <args>                - Proxy to ./vendor/bin/sail"
  echo "  update                     - Update nfutils from GitHub"
  echo "  uninstall                  - Remove nfutils from your system"
  echo "  --version                  - Show nfutils version"
  echo ""
  echo "Compat:"
  echo "  laravel ..., docker ...    - Aliases untuk perintah lama (deprecated)"
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
  append_unique_line "$ZSHRC" "$alias_line"
  echo "$(green "✅ Alias 'sail' ditambahkan ke shell profile.")"
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

sail_cmd() {
  if [ ! -f "./vendor/bin/sail" ]; then
    echo "$(red "❌ Laravel Sail is not installed (vendor/bin/sail missing).")"
    echo "Run: nfutils lara-init"
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
  LATEST_VERSION=$(curl -s "$NF_REPO_URL" | grep 'NF_VERSION="v' | cut -d'"' -f2 | pick_latest_version)
  if [ -z "$LATEST_VERSION" ]; then
    echo "$(red "❌ Unable to check version.")"
    exit 1
  fi
  if version_newer "$LATEST_VERSION" "$NF_VERSION"; then
    echo "$(yellow "📦 New version available:") $LATEST_VERSION"
    curl -s "$NF_REPO_URL" | bash
    echo "$(green "✅ Updated to $LATEST_VERSION")"
    exit 0
  elif version_newer "$NF_VERSION" "$LATEST_VERSION"; then
    echo "$(green "✅ Anda sudah di depan (local $NF_VERSION, remote $LATEST_VERSION)")"
  else
    echo "$(green "✅ Already up-to-date ($NF_VERSION)")"
  fi
}

# --- Dispatcher ---
case "$1" in
  lara-create) shift; laravel_init "$@";;
  lara-init) shift; laravel_sail "$@";;
  laravel)
    shift
    case "${1:-}" in
      create)
        warn_deprecated "nfutils laravel create" "nfutils lara-create"
        shift
        laravel_init "$@"
        ;;
      init)
        warn_deprecated "nfutils laravel init" "nfutils lara-init"
        shift
        laravel_sail "$@"
        ;;
      sail)
        warn_deprecated "nfutils laravel sail" "nfutils lara-init"
        shift
        laravel_sail "$@"
        ;;
      *)
        show_help
        ;;
    esac;;
  composer) shift; composer_cmd "$@";;
  dock-kill) docker_kill;;
  dock-rm) docker_rm;;
  dock-destroy) docker_destroy;;
  dock-nuke) docker_nuke;;
  docker)
    shift
    case "${1:-}" in
      kill)
        warn_deprecated "nfutils docker kill" "nfutils dock-kill"
        docker_kill
        ;;
      rm)
        warn_deprecated "nfutils docker rm" "nfutils dock-rm"
        docker_rm
        ;;
      destroy)
        warn_deprecated "nfutils docker destroy" "nfutils dock-destroy"
        docker_destroy
        ;;
      nuke)
        warn_deprecated "nfutils docker nuke" "nfutils dock-nuke"
        docker_nuke
        ;;
      *)
        show_help
        ;;
    esac;;
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
append_unique_line "$BASHRC" 'export PATH="$HOME/bin:$PATH"'
if [ -n "$ZSHRC" ]; then
  ensure_zshrc
  append_unique_line "$ZSHRC" 'export PATH="$HOME/bin:$PATH"'
fi

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
  local cur prev opts
  COMPREPLY=()
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD-1]}"

  # subcommands
  opts="help --version update uninstall destroyer composer sail lara-create lara-init dock-kill dock-rm dock-destroy dock-nuke laravel docker"

  case "${prev}" in
    docker)
      COMPREPLY=( $(compgen -W "kill rm destroy nuke" -- ${cur}) )
      return 0
      ;;
    laravel)
      COMPREPLY=( $(compgen -W "create init" -- ${cur}) )
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

cat > "$ZSH_COMPLETION_PATH" <<'EOZ'
#compdef nfutils

_nfutils() {
  local curcontext="$curcontext" state line
  typeset -A opt_args

  local -a top_commands
  top_commands=(help --version update uninstall destroyer composer sail lara-create lara-init dock-kill dock-rm dock-destroy dock-nuke laravel docker)

  _arguments -C \
    '1:command:->command' \
    '*::args:->args'

  case $state in
    command)
      _describe -t commands 'nfutils commands' top_commands
      return
      ;;
    args)
      case ${words[2]} in
        docker)
          local -a docker_sub
          docker_sub=(kill rm destroy nuke)
          _describe -t docker_subcommands 'docker subcommands' docker_sub
          ;;
        laravel)
          local -a laravel_sub
          laravel_sub=(create init)
          _describe -t laravel_subcommands 'laravel subcommands' laravel_sub
          ;;
        sail)
          local -a sail_sub
          sail_sub=(up down restart stop build ps)
          _describe -t sail_subcommands 'sail subcommands' sail_sub
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
  cat >> "$ZSHRC" <<'EOZ'
# nfutils zsh completion start
fpath=("$HOME/.zsh/completions" $fpath)
autoload -Uz compinit && compinit
# nfutils zsh completion end
EOZ
fi
