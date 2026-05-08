FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8

# --- Base build/runtime utilities + universe-apt tools that ship as-is ---
RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential curl git openssh-client sudo ca-certificates locales \
        less man-db gnupg wget xz-utils tar ncurses-bin pkg-config unzip \
        fzf ripgrep fd-find bat zoxide tig jq btop mosh \
        zsh zsh-syntax-highlighting zsh-autosuggestions zsh-history-substring-search \
 && locale-gen en_US.UTF-8 \
 && ln -s /usr/bin/fdfind /usr/local/bin/fd \
 && ln -s /usr/bin/batcat /usr/local/bin/bat \
 && rm -rf /var/lib/apt/lists/*

# --- github-cli (gh) — official apt repo, multi-arch ---
RUN mkdir -p -m 755 /etc/apt/keyrings \
 && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
        -o /etc/apt/keyrings/githubcli-archive-keyring.gpg \
 && chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
 && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
        > /etc/apt/sources.list.d/github-cli.list \
 && apt-get update && apt-get install -y --no-install-recommends gh \
 && rm -rf /var/lib/apt/lists/*

# --- glow (charmbracelet apt repo, multi-arch) ---
RUN curl -fsSL https://repo.charm.sh/apt/gpg.key | gpg --dearmor -o /etc/apt/keyrings/charm.gpg \
 && echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" \
        > /etc/apt/sources.list.d/charm.list \
 && apt-get update && apt-get install -y --no-install-recommends glow \
 && rm -rf /var/lib/apt/lists/*

# --- eza (gierens.de apt repo, multi-arch) ---
RUN curl -fsSL https://raw.githubusercontent.com/eza-community/eza/main/deb.asc \
        | gpg --dearmor -o /etc/apt/keyrings/gierens.gpg \
 && echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" \
        > /etc/apt/sources.list.d/gierens.list \
 && chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list \
 && apt-get update && apt-get install -y --no-install-recommends eza \
 && rm -rf /var/lib/apt/lists/*

# --- nodejs (NodeSource LTS, multi-arch) ---
RUN curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - \
 && apt-get install -y --no-install-recommends nodejs \
 && rm -rf /var/lib/apt/lists/*

# --- claude code (via npm) ---
RUN npm install -g @anthropic-ai/claude-code \
 && npm cache clean --force

# --- git-delta (.deb from upstream releases) ---
ARG DELTA_VERSION=0.19.2
RUN arch=$(dpkg --print-architecture) \
 && curl -fsSL -o /tmp/delta.deb \
        "https://github.com/dandavison/delta/releases/download/${DELTA_VERSION}/git-delta_${DELTA_VERSION}_${arch}.deb" \
 && dpkg -i /tmp/delta.deb && rm /tmp/delta.deb

# --- helix (upstream tarball; PPA is amd64-only, tarball is multi-arch) ---
ARG HELIX_VERSION=25.07.1
RUN arch=$(uname -m) \
 && curl -fsSL -o /tmp/helix.tar.xz \
        "https://github.com/helix-editor/helix/releases/download/${HELIX_VERSION}/helix-${HELIX_VERSION}-${arch}-linux.tar.xz" \
 && tar -xJf /tmp/helix.tar.xz -C /tmp \
 && mv /tmp/helix-${HELIX_VERSION}-${arch}-linux/hx /usr/local/bin/hx \
 && mkdir -p /usr/local/share/helix \
 && mv /tmp/helix-${HELIX_VERSION}-${arch}-linux/runtime /usr/local/share/helix/runtime \
 && rm -rf /tmp/helix*
ENV HELIX_RUNTIME=/usr/local/share/helix/runtime

# --- zellij ---
ARG ZELLIJ_VERSION=v0.44.2
RUN case "$(uname -m)" in x86_64) a=x86_64;; aarch64) a=aarch64;; esac \
 && curl -fsSL -o /tmp/zellij.tar.gz \
        "https://github.com/zellij-org/zellij/releases/download/${ZELLIJ_VERSION}/zellij-${a}-unknown-linux-musl.tar.gz" \
 && tar -xzf /tmp/zellij.tar.gz -C /usr/local/bin zellij \
 && rm /tmp/zellij.tar.gz

# --- lazygit ---
ARG LAZYGIT_VERSION=0.61.1
RUN case "$(uname -m)" in x86_64) a=x86_64;; aarch64) a=arm64;; esac \
 && curl -fsSL -o /tmp/lg.tar.gz \
        "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_linux_${a}.tar.gz" \
 && tar -xzf /tmp/lg.tar.gz -C /usr/local/bin lazygit \
 && rm /tmp/lg.tar.gz

# --- lazydocker ---
ARG LAZYDOCKER_VERSION=0.25.2
RUN case "$(uname -m)" in x86_64) a=x86_64;; aarch64) a=arm64;; esac \
 && curl -fsSL -o /tmp/ld.tar.gz \
        "https://github.com/jesseduffield/lazydocker/releases/download/v${LAZYDOCKER_VERSION}/lazydocker_${LAZYDOCKER_VERSION}_Linux_${a}.tar.gz" \
 && tar -xzf /tmp/ld.tar.gz -C /usr/local/bin lazydocker \
 && rm /tmp/ld.tar.gz

# --- yazi ---
ARG YAZI_VERSION=26.5.6
RUN case "$(uname -m)" in x86_64) a=x86_64;; aarch64) a=aarch64;; esac \
 && curl -fsSL -o /tmp/yazi.zip \
        "https://github.com/sxyazi/yazi/releases/download/v${YAZI_VERSION}/yazi-${a}-unknown-linux-musl.zip" \
 && unzip /tmp/yazi.zip -d /tmp/yazi-extract \
 && mv /tmp/yazi-extract/*/yazi /tmp/yazi-extract/*/ya /usr/local/bin/ \
 && rm -rf /tmp/yazi*

# --- go (upstream tarball) ---
ARG GO_VERSION=1.26.3
RUN case "$(dpkg --print-architecture)" in amd64) a=amd64;; arm64) a=arm64;; esac \
 && curl -fsSL -o /tmp/go.tar.gz "https://go.dev/dl/go${GO_VERSION}.linux-${a}.tar.gz" \
 && rm -rf /usr/local/go && tar -C /usr/local -xzf /tmp/go.tar.gz \
 && rm /tmp/go.tar.gz
ENV PATH=/usr/local/go/bin:$PATH

# --- rustup (system-wide so any user can use it) ---
ENV RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    PATH=/usr/local/cargo/bin:$PATH
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \
        | sh -s -- -y --default-toolchain stable --profile minimal --no-modify-path \
 && chmod -R a+rwX /usr/local/rustup /usr/local/cargo

# --- xterm-ghostty terminfo (entry only; not in noble's ncurses-term yet) ---
RUN curl -fsSL -o /tmp/ghostty.terminfo \
        https://raw.githubusercontent.com/ghostty-org/ghostty/main/src/terminfo/ghostty.terminfo \
 && tic -x -o /etc/terminfo /tmp/ghostty.terminfo \
 && rm /tmp/ghostty.terminfo

# --- user setup ---
ARG USER=sergeik
ARG UID=1000
ARG GID=1000
RUN groupadd -g ${GID} ${USER} \
 && useradd -m -u ${UID} -g ${GID} -s /usr/bin/zsh -G sudo ${USER} \
 && echo "${USER} ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/${USER}

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

USER ${USER}
WORKDIR /home/${USER}

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["sleep", "infinity"]
