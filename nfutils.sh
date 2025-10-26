#!/usr/bin/env bash
# =========================================================
# NFUTILS INSTALLER - Auto setup Dev Utilities CodeSpace
# Author: NeflaLabs
# Email:  neflaprojekt@gmail.com
# =========================================================

set -e

NF_DIR="$HOME/bin"
NF_PATH="$NF_DIR/nfutils"
BASHRC="$HOME/.bashrc"

bold() { echo -e "\033[1m$1\033[0m"; }
green() { echo -e "\033[32m$1\033[0m"; }
yellow() { echo -e "\033[33m$1\033[0m"; }
red() { echo -e "\033[31m$1\033[0m"; }

echo ""
bold "🧰 Installing nfutils..."
echo ""

# Create bin dir if not exists
mkdir -p "$NF_DIR"

# Write nfutils main script
cat > "$NF_PATH" <<'EOF'
#!/usr/bin/env bash
# ===========================================
# NFUTILS - Developer Utility Toolkit
# ===========================================

set -e

bold() { echo -e "\033[1m$1\033[0m"; }
green() { echo -e "\033[32m$1\033[0m"; }
yellow() { echo -e "\033[33m$1\033[0m"; }
red() { echo -e "\033[31m$1\033[0m"; }

show_help() {
  echo ""
  bold "NFUTILS - Laravel & Docker Developer Helper"
  echo ""
  echo "Usage: nfutils <command> [options]"
  echo ""
  echo "Commands:"
  echo "  $(green 'laravel init <project>')    - Create new Laravel project"
  echo "  $(green 'laravel sail')             - Initialize Sail in existing project"
  echo "  $(green 'composer <args>')          - Run Composer in Docker"
  echo "  $(green 'docker kill')              - Stop all running containers"
  echo "  $(green 'docker rm')                - Remove all containers"
  echo "  $(green 'docker destroy')           - Stop & remove all containers"
  echo "  $(green 'docker nuke')              - Destroy ALL (containers, images, volumes, networks)"
  echo "  $(red   'destroyer')                - ⚠️  Delete all files in current dir (safe version)"
  echo ""
}

laravel_init() {
  docker run --rm -u "$(id -u):$(id -g)" \
    -v "$(pwd):/app" \
    -v composer_cache:/tmp/cache \
    -e COMPOSER_CACHE_DIR=/tmp/cache \
    composer create-project laravel/laravel "$@"
}

laravel_sail() {
  docker run --rm -u "$(id -u):$(id -g)" \
    -v "$(pwd):/var/www/html" \
    -w /var/www/html \
    laravelsail/php84-composer:latest php artisan sail:install "$@"
}

composer_cmd() {
  docker run --rm -u "$(id -u):$(id -g)" \
    -v "$(pwd):/app" \
    -v composer_cache:/tmp/cache \
    -e COMPOSER_CACHE_DIR=/tmp/cache \
    composer "$@"
}

docker_kill() {
  docker ps -q | xargs -r docker stop
}

docker_rm() {
  docker ps -a -q | xargs -r docker rm
}

docker_destroy() {
  docker ps -a -q | xargs -r docker stop
  docker ps -a -q | xargs -r docker rm
}

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

case "$1" in
  laravel)
    shift
    case "$1" in
      init) shift; laravel_init "$@";;
      sail) shift; laravel_sail "$@";;
      *) show_help;;
    esac
    ;;
  composer)
    shift; composer_cmd "$@";;
  docker)
    shift
    case "$1" in
      kill) docker_kill;;
      rm) docker_rm;;
      destroy) docker_destroy;;
      nuke) docker_nuke;;
      *) show_help;;
    esac
    ;;
  destroyer)
    destroyer;;
  help|"")
    show_help;;
  *)
    echo "$(red "Unknown command: $1")"
    show_help;;
esac
EOF

chmod +x "$NF_PATH"

# Add to PATH if not already there
if ! echo "$PATH" | grep -q "$HOME/bin"; then
  echo 'export PATH="$HOME/bin:$PATH"' >> "$BASHRC"
fi

# Reload shell
if [ -n "$BASH_VERSION" ]; then
  source "$BASHRC"
fi

echo ""
green "✅ nfutils installed successfully!"
echo "You can now use it right away:"
echo ""
bold "Examples:"
echo "  nfutils laravel init myapp"
echo "  nfutils composer install"
echo "  nfutils docker nuke"
echo ""
