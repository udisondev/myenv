#!/usr/bin/env bash
# Idempotent bootstrap for the distrobox dev environment.
# Runs inside the container as the user (via distrobox init_hooks).

set -euo pipefail

REPO="$HOME/dev-env"
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

link "$DOTFILES/.zshrc"                   "$HOME/.zshrc"
link "$DOTFILES/.config/helix/config.toml"    "$HOME/.config/helix/config.toml"
link "$DOTFILES/.config/helix/languages.toml" "$HOME/.config/helix/languages.toml"
link "$DOTFILES/.config/zellij/config.kdl"    "$HOME/.config/zellij/config.kdl"
link "$DOTFILES/.config/glow/glow.yml"        "$HOME/.config/glow/glow.yml"
link "$DOTFILES/.config/ghostty/config"       "$HOME/.config/ghostty/config"

[ -f "$HOME/.zshrc.local" ] || cp "$DOTFILES/.zshrc.local.example" "$HOME/.zshrc.local"

if command -v rustup >/dev/null && ! command -v rustc >/dev/null; then
  rustup default stable
fi

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

if [ "$(getent passwd "$USER" | cut -d: -f7)" != "/usr/bin/zsh" ]; then
  sudo chsh -s /usr/bin/zsh "$USER" 2>/dev/null || true
fi
