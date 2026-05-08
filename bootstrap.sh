#!/usr/bin/env bash
# Idempotent first-boot setup, executed by entrypoint.sh on container start.
# Symlinks dotfiles, seeds ~/.zshrc.local, installs Go-based tools.

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
    mv "$dst" "$dst.pre-myenv.$(date +%s)"
  fi
  ln -sfn "$src" "$dst"
}

link "$DOTFILES/.zshrc"                       "$HOME/.zshrc"
link "$DOTFILES/.config/helix/config.toml"    "$HOME/.config/helix/config.toml"
link "$DOTFILES/.config/helix/languages.toml" "$HOME/.config/helix/languages.toml"
link "$DOTFILES/.config/zellij/config.kdl"    "$HOME/.config/zellij/config.kdl"
link "$DOTFILES/.config/glow/glow.yml"        "$HOME/.config/glow/glow.yml"
link "$DOTFILES/.ssh/config.example"          "$HOME/.ssh/config.example"

if [ -d "$REPO/oh-my-zsh" ]; then
  link "$REPO/oh-my-zsh" "$HOME/.oh-my-zsh"
fi

[ -f "$HOME/.zshrc.local" ] || cp "$DOTFILES/.zshrc.local.example" "$HOME/.zshrc.local"

if command -v go >/dev/null; then
  GO_TOOLS=(
    golang.org/x/tools/gopls@latest
    mvdan.cc/gofumpt@latest
    github.com/go-delve/delve/cmd/dlv@latest
    golang.org/x/vuln/cmd/govulncheck@latest
    github.com/a-h/templ/cmd/templ@latest
    github.com/go-task/task/v3/cmd/task@latest
    golang.org/x/perf/cmd/benchstat@latest
  )
  for t in "${GO_TOOLS[@]}"; do
    name="${t##*/}"; name="${name%@*}"
    command -v "$name" >/dev/null || go install "$t"
  done
fi
