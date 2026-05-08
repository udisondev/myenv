#!/usr/bin/env bash
# Idempotent host-side setup. Runs ON the host (mac or Linux), not inside distrobox.
# Installs only what the host itself needs: ghostty config and an ssh config skeleton.
# Everything else (helix, zellij, zsh stack, Go, Rust) lives inside the container
# and is set up by bootstrap.sh.

set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$REPO/dotfiles"

link() {
  local src="$1" dst="$2"
  mkdir -p "$(dirname "$dst")"
  if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
    return
  fi
  if [ -e "$dst" ] && [ ! -L "$dst" ]; then
    mv "$dst" "$dst.pre-devenv.$(date +%s)"
  fi
  ln -sfn "$src" "$dst"
}

link "$DOTFILES/.config/ghostty/config" "$HOME/.config/ghostty/config"

if [ ! -f "$HOME/.ssh/config" ]; then
  mkdir -p "$HOME/.ssh"
  chmod 700 "$HOME/.ssh"
  cp "$DOTFILES/.ssh/config.example" "$HOME/.ssh/config"
  chmod 600 "$HOME/.ssh/config"
  echo "Seeded ~/.ssh/config from template — edit it with your real hosts."
fi
