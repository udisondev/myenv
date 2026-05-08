# oh-my-zsh
export ZSH="/usr/share/oh-my-zsh"
ZSH_THEME="robbyrussell"
plugins=(git fzf extract)
source $ZSH/oh-my-zsh.sh

# History
export EDITOR="helix"
export HISTCONTROL=ignoreboth
export HISTORY_IGNORE="(\&|[bf]g|c|clear|history|exit|q|pwd|* --help)"

# PATH
typeset -U path
path=(
  $HOME/go/bin
  $HOME/bin
  $HOME/.npm-global/bin
  $path
)

# Aliases
alias hx=helix

# zoxide — smarter cd
eval "$(zoxide init zsh)"

# yazi — wrapper that cds to the directory you exited yazi in
function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d '' cwd < "$tmp"
	[ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
	rm -f -- "$tmp"
}

# Plugins from /usr/share/zsh/plugins
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh

# pkgfile "command not found" handler
[[ -f /usr/share/doc/pkgfile/command-not-found.zsh ]] && source /usr/share/doc/pkgfile/command-not-found.zsh

# Cargo binaries
path=($HOME/.cargo/bin $path)

# Per-machine overrides: secrets, GOPROXY, ESP toolchain, work-specific git config, etc.
[[ -f $HOME/.zshrc.local ]] && source $HOME/.zshrc.local
