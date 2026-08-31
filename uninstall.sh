#!/bin/bash

set -Eeuo pipefail

repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
config_home=${XDG_CONFIG_HOME:-$HOME/.config}
state_home=${XDG_STATE_HOME:-$HOME/.local/state}
state_dir="$state_home/new-charter-omarchy"
original_dir="$state_dir/original"
backup_root="$state_dir/backups"
reset_system=false

usage() {
  cat <<'EOF'
Usage: ./uninstall.sh [options]

Options:
  --system  Also reset Plymouth/SDDM and restore the Limine banner
  --help    Show this help
EOF
}

while (( $# )); do
  case "$1" in
    --system) reset_system=true ;;
    --help|-h) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

if [[ ! -d $original_dir ]]; then
  echo "No New Charter installation state found at $state_dir" >&2
  exit 1
fi

mkdir -p "$backup_root"
run_backup=$(mktemp -d "$backup_root/uninstall-$(date +%Y%m%d-%H%M%S).XXXXXX")

restore() {
  local key=$1 target=$2 parent
  parent=${target%/*}
  mkdir -p "$parent"

  if [[ -e $target ]]; then
    mv -- "$target" "$run_backup/$key.current"
  fi

  if [[ -e $original_dir/$key ]]; then
    cp -a -- "$original_dir/$key" "$target"
  elif [[ ! -e $original_dir/$key.missing ]]; then
    echo "No original-state record for $target; leaving it absent." >&2
  fi
}

current_theme=$(omarchy theme current 2>/dev/null || true)
if [[ $current_theme == "New Charter" ]]; then
  previous_theme=$(cat "$original_dir/previous-theme.txt" 2>/dev/null || true)
  if [[ -n $previous_theme && $previous_theme != "New Charter" ]]; then
    omarchy theme set "$previous_theme" || omarchy theme set "Tokyo Night"
  else
    omarchy theme set "Tokyo Night"
  fi
fi

restore theme "$config_home/omarchy/themes/new-charter"
restore about "$config_home/omarchy/branding/about.txt"
restore screensaver "$config_home/omarchy/branding/screensaver.txt"
restore menu "$config_home/omarchy/extensions/omarchy-menu.jsonc"
restore fastfetch "$config_home/fastfetch/config.jsonc"
restore vscode-template "$config_home/omarchy/themed/vscode-theme.json.tpl"
restore claude-template "$config_home/omarchy/themed/claude.json.tpl"
restore uwsm-default "$config_home/uwsm/default"
restore show-logo "$HOME/.local/bin/omarchy-show-logo"
restore presentation "$HOME/.local/bin/omarchy-launch-floating-terminal-with-presentation"

if $reset_system; then
  if [[ -t 0 ]]; then
    omarchy plymouth reset
    sudo "$repo_dir/scripts/brand-limine" restore
  else
    echo "Skipping system reset because no interactive terminal is available."
    echo "Run these commands from a terminal to finish:"
    echo "  omarchy plymouth reset"
    echo "  sudo $repo_dir/scripts/brand-limine restore"
  fi
fi

echo
echo "New Charter user branding removed and original files restored."
echo "Pre-uninstall files: $run_backup"
