#!/bin/bash

set -Eeuo pipefail

repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
config_home=${XDG_CONFIG_HOME:-$HOME/.config}
state_home=${XDG_STATE_HOME:-$HOME/.local/state}
state_dir="$state_home/new-charter-omarchy"
original_dir="$state_dir/original"
backup_root="$state_dir/backups"
user_only=false
activate=true

usage() {
  cat <<'EOF'
Usage: ./install.sh [options]

Options:
  --user-only    Skip Plymouth, SDDM, and Limine branding
  --no-activate  Install files without selecting the New Charter theme
  --help         Show this help
EOF
}

while (( $# )); do
  case "$1" in
    --user-only) user_only=true ;;
    --no-activate) activate=false ;;
    --help|-h) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

command -v omarchy >/dev/null || {
  echo "This installer requires an Omarchy system." >&2
  exit 1
}
command -v python3 >/dev/null || {
  echo "This installer requires python3 to merge menu configuration safely." >&2
  exit 1
}

mkdir -p "$original_dir" "$backup_root"
run_backup=$(mktemp -d "$backup_root/install-$(date +%Y%m%d-%H%M%S).XXXXXX")

backup_once() {
  local target=$1 key=$2
  if [[ -e $original_dir/$key || -e $original_dir/$key.missing ]]; then
    return
  fi
  if [[ -e $target ]]; then
    cp -a -- "$target" "$original_dir/$key"
  else
    touch "$original_dir/$key.missing"
  fi
}

snapshot() {
  local target=$1 key=$2
  if [[ -e $target ]]; then
    cp -a -- "$target" "$run_backup/$key"
  fi
}

install_file() {
  local source=$1 target=$2 mode=$3 key=$4
  backup_once "$target" "$key"
  snapshot "$target" "$key"
  install -D -m "$mode" -- "$source" "$target"
}

install_directory() {
  local source=$1 target=$2 key=$3 parent staging
  parent=${target%/*}
  mkdir -p "$parent"
  backup_once "$target" "$key"
  staging=$(mktemp -d "$parent/.new-charter-theme.XXXXXX")
  cp -a -- "$source/." "$staging/"
  if [[ -e $target ]]; then
    mv -- "$target" "$run_backup/$key"
  fi
  mv -- "$staging" "$target"
}

theme_target="$config_home/omarchy/themes/new-charter"
about_target="$config_home/omarchy/branding/about.txt"
screensaver_target="$config_home/omarchy/branding/screensaver.txt"
menu_target="$config_home/omarchy/extensions/omarchy-menu.jsonc"
fastfetch_target="$config_home/fastfetch/config.jsonc"
vscode_template_target="$config_home/omarchy/themed/vscode-theme.json.tpl"
claude_template_target="$config_home/omarchy/themed/claude.json.tpl"
uwsm_target="$config_home/uwsm/default"
show_logo_target="$HOME/.local/bin/omarchy-show-logo"
presentation_target="$HOME/.local/bin/omarchy-launch-floating-terminal-with-presentation"

if [[ ! -e $original_dir/previous-theme.txt ]]; then
  previous_theme=$(omarchy theme current 2>/dev/null || true)
  [[ ${previous_theme,,} == unknown ]] && previous_theme=
  printf '%s\n' "$previous_theme" >"$original_dir/previous-theme.txt"
fi

install_directory "$repo_dir/theme" "$theme_target" theme
install_file "$repo_dir/branding/about.txt" "$about_target" 0644 about
install_file "$repo_dir/branding/screensaver.txt" "$screensaver_target" 0644 screensaver
install_file "$repo_dir/fastfetch/config.jsonc" "$fastfetch_target" 0644 fastfetch
install_file "$repo_dir/templates/vscode-theme.json.tpl" "$vscode_template_target" 0644 vscode-template
install_file "$repo_dir/templates/claude.json.tpl" "$claude_template_target" 0644 claude-template
install_file "$repo_dir/bin/omarchy-show-logo" "$show_logo_target" 0755 show-logo
install_file "$repo_dir/bin/omarchy-launch-floating-terminal-with-presentation" "$presentation_target" 0755 presentation

backup_once "$menu_target" menu
snapshot "$menu_target" menu
python3 "$repo_dir/scripts/merge-menu.py" "$menu_target" "$repo_dir/menu/overrides.json"

backup_once "$uwsm_target" uwsm-default
snapshot "$uwsm_target" uwsm-default
mkdir -p "${uwsm_target%/*}"
uwsm_tmp=$(mktemp)
if [[ -f $uwsm_target ]]; then
  awk '
    $0 == "# BEGIN NEW CHARTER OMARCHY" { skip=1; next }
    $0 == "# END NEW CHARTER OMARCHY" { skip=0; next }
    $0 == "# BEGIN TOASTY SYSTEMS OMARCHY" { skip=1; next }
    $0 == "# END TOASTY SYSTEMS OMARCHY" { skip=0; next }
    $0 == "# BEGIN OMARCHY BRAND PACK PATH" { skip=1; next }
    $0 == "# END OMARCHY BRAND PACK PATH" { skip=0; next }
    !skip { print }
  ' "$uwsm_target" >"$uwsm_tmp"
fi
cat >>"$uwsm_tmp" <<'EOF'

# BEGIN OMARCHY BRAND PACK PATH
case ":$PATH:" in
  *":$HOME/.local/bin:"*) ;;
  *) export PATH="$HOME/.local/bin:$PATH" ;;
esac
# END OMARCHY BRAND PACK PATH
EOF
install -m 0644 "$uwsm_tmp" "$uwsm_target"
rm -f -- "$uwsm_tmp"

if $activate; then
  omarchy theme set "New Charter"
fi

if ! $user_only; then
  if [[ -t 0 ]]; then
    omarchy plymouth set by theme new-charter
    sudo "$repo_dir/scripts/brand-limine" install
  else
    echo "Skipping boot/login branding because no interactive terminal is available."
    echo "Run these commands from a terminal to finish:"
    echo "  omarchy plymouth set by theme new-charter"
    echo "  sudo $repo_dir/scripts/brand-limine install"
  fi
fi

echo
echo "New Charter for Omarchy installed successfully."
echo "Backups for this run: $run_backup"
echo "Log out and back in once after the first installation."
