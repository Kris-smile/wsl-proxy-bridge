#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SHELL_NAME="${1:-${SHELL##*/}}"

case "$SHELL_NAME" in
  bash) RC_FILE="$HOME/.bashrc" ;;
  zsh)  RC_FILE="$HOME/.zshrc" ;;
  *)
    printf 'Unsupported shell: %s\nUsage: bash install.sh [bash|zsh]\n' "$SHELL_NAME" >&2
    exit 2
    ;;
esac

CONFIG_DIR="$HOME/.config/wsl-proxy-bridge"
CONFIG_FILE="$CONFIG_DIR/proxy.sh"
START_MARKER='# >>> wsl-proxy-bridge >>>'
END_MARKER='# <<< wsl-proxy-bridge <<<'

mkdir -p "$CONFIG_DIR"

if [[ -f "$CONFIG_FILE" ]]; then
  backup="$CONFIG_FILE.bak.$(date +%Y%m%d%H%M%S)"
  cp -p "$CONFIG_FILE" "$backup"
  printf 'Existing script backed up to: %s\n' "$backup"
fi

install -m 600 "$ROOT_DIR/scripts/proxy.sh" "$CONFIG_FILE"
touch "$RC_FILE"

if grep -Fq "$START_MARKER" "$RC_FILE"; then
  printf 'A loader block already exists in %s; updated the installed script only.\n' "$RC_FILE"
else
  backup="$RC_FILE.bak.$(date +%Y%m%d%H%M%S)"
  cp -p "$RC_FILE" "$backup"
  cat >> "$RC_FILE" <<'BLOCK'

# >>> wsl-proxy-bridge >>>
if [ -r "$HOME/.config/wsl-proxy-bridge/proxy.sh" ]; then
    . "$HOME/.config/wsl-proxy-bridge/proxy.sh"
fi
# <<< wsl-proxy-bridge <<<
BLOCK
  printf 'Shell configuration backed up to: %s\n' "$backup"
fi

printf '\nInstalled for %s. Reload your shell configuration:\n' "$SHELL_NAME"
printf '  source %s\n' "$RC_FILE"
printf '\nCommands: pon, poff, pstatus, ptest\n'
printf 'Manual mode is enabled by default. Proxy port defaults to 7890.\n'
