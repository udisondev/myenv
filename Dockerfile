FROM archlinux:latest

RUN pacman -Sy --noconfirm archlinux-keyring && \
    pacman -Syu --noconfirm && \
    pacman -S --needed --noconfirm \
        base-devel curl git openssh sudo \
        zsh zsh-syntax-highlighting zsh-autosuggestions zsh-history-substring-search \
        helix zellij yazi glow lazygit lazydocker btop github-cli \
        fzf ripgrep fd zoxide bat eza tig git-delta jq \
        go rustup nodejs npm \
        mosh man-db less which pkgfile ghostty-terminfo && \
    pacman -Scc --noconfirm

ARG USER=sergeik
ARG UID=1000
ARG GID=1000

RUN groupadd -g ${GID} ${USER} && \
    useradd -m -u ${UID} -g ${GID} -s /usr/bin/zsh -G wheel ${USER} && \
    echo "${USER} ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/${USER}

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

USER ${USER}
WORKDIR /home/${USER}

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["sleep", "infinity"]
