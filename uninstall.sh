#!/usr/bin/env bash
set -euo pipefail

SHELL_NAME="${1:-${SHELL##*/}}"
case "$SHELL_NAME" in
  bash) RC_FILE="$HOME/.bashrc" ;;
  zsh)  RC_FILE="$HOME/.zshrc" ;;
  *)
    printf 'Unsupported shell: %s\nUsage: bash uninstall.sh [bash|zsh]\n' "$SHELL_NAME" >&2
    exit 2
    ;;
esac

START_MARKER='# >>> wsl-proxy-bridge >>>'
END_MARKER='# <<< wsl-proxy-bridge <<<'
CONFIG_DIR="$HOME/.config/wsl-proxy-bridge"

if [[ -f "$RC_FILE" ]] && grep -Fq "$START_MARKER" "$RC_FILE"; then
  backup="$RC_FILE.bak.$(date +%Y%m%d%H%M%S)"
  cp -p "$RC_FILE" "$backup"
  tmp_file="$(mktemp)"
  awk -v start="$START_MARKER" -v end="$END_MARKER" '
    $0 == start { skipping = 1; next }
    $0 == end { skipping = 0; next }
    !skipping { print }
  ' "$RC_FILE" > "$tmp_file"
  cat "$tmp_file" > "$RC_FILE"
  rm -f "$tmp_file"
  printf 'Removed loader block from %s (backup: %s).\n' "$RC_FILE" "$backup"
else
  printf 'No wsl-proxy-bridge loader block found in %s.\n' "$RC_FILE"
fi

if [[ -d "$CONFIG_DIR" ]]; then
  rm -rf -- "$CONFIG_DIR"
  printf 'Removed %s\n' "$CONFIG_DIR"
fi

printf 'Reload %s to remove the commands from the current session.\n' "$RC_FILE"
