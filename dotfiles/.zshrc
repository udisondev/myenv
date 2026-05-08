# oh-my-zsh — Arch package puts it in /usr/share/oh-my-zsh,
# the official installer puts it in ~/.oh-my-zsh.
if [[ -d /usr/share/oh-my-zsh ]]; then
  export ZSH="/usr/share/oh-my-zsh"
else
  export ZSH="$HOME/.oh-my-zsh"
fi
ZSH_THEME="robbyrussell"
plugins=(git fzf extract history-substring-search)
[[ -f "$ZSH/oh-my-zsh.sh" ]] && source "$ZSH/oh-my-zsh.sh"

# History
export EDITOR="helix"
export HISTCONTROL=ignoreboth
export HISTORY_IGNORE="(\&|[bf]g|c|clear|history|exit|q|pwd|* --help)"

# Go
export GOPATH="$HOME/go"
export GOBIN="$GOPATH/bin"

# PATH
typeset -U path
path=(
  $GOBIN
  $HOME/bin
  $HOME/.npm-global/bin
  /usr/local/go/bin
  /usr/local/cargo/bin
  $path
)

# Aliases
alias hx=helix

# zoxide — smarter cd
eval "$(zoxide init zsh)"

# zellij — attach to most recent live session, or create a new one.
# Mimics `tmux attach` UX (zellij itself requires an explicit session name).
function zj() {
	local active
	active=$(zellij list-sessions --no-formatting 2>/dev/null \
	         | awk '!/EXITED/ {print $1}' | head -1)
	if [ -n "$active" ]; then
		zellij attach "$active"
	else
		zellij
	fi
}

# yazi — wrapper that cds to the directory you exited yazi in
function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d '' cwd < "$tmp"
	[ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
	rm -f -- "$tmp"
}

# zsh plugins — Arch puts them under /usr/share/zsh/plugins/<name>/<name>.zsh,
# Debian/Ubuntu under /usr/share/<name>/<name>.zsh.
for plugin in zsh-syntax-highlighting zsh-autosuggestions; do
  for plugin_path in \
    /usr/share/zsh/plugins/$plugin/$plugin.zsh \
    /usr/share/$plugin/$plugin.zsh; do
    [[ -f $plugin_path ]] && source $plugin_path && break
  done
done

# command-not-found handler — Arch (pkgfile) and Debian/Ubuntu have different files
[[ -f /usr/share/doc/pkgfile/command-not-found.zsh ]] && source /usr/share/doc/pkgfile/command-not-found.zsh
[[ -f /etc/zsh_command_not_found ]] && source /etc/zsh_command_not_found

# Drop SSH_AUTH_SOCK if it doesn't point at a real socket (compose may mount
# /dev/null when the host has no agent forwarding).
[[ -S "$SSH_AUTH_SOCK" ]] || unset SSH_AUTH_SOCK

# Cargo binaries
path=($HOME/.cargo/bin $path)

# Per-machine overrides: secrets, GOPROXY, ESP toolchain, work-specific git config, etc.
[[ -f $HOME/.zshrc.local ]] && source $HOME/.zshrc.local
