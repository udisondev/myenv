FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8

# noble's minimized base image strips /usr/share/{doc,man,locale} via dpkg
# excludes — this hides things like fzf's key-bindings.zsh and breaks `man`.
# Drop the exclude so packages install with their normal payload.
RUN rm -f /etc/dpkg/dpkg.cfg.d/excludes

# --- Base build/runtime utilities + universe-apt tools that ship as-is ---
RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential curl git openssh-client openssh-server sudo ca-certificates locales \
        less man-db gnupg wget xz-utils tar ncurses-bin pkg-config unzip \
        fzf ripgrep fd-find bat zoxide tig jq btop mosh \
        zsh zsh-syntax-highlighting zsh-autosuggestions \
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

# --- glow (.deb from upstream releases) ---
ARG GLOW_VERSION=2.1.1
RUN arch=$(dpkg --print-architecture) \
 && curl -fsSL -o /tmp/glow.deb \
        "https://github.com/charmbracelet/glow/releases/download/v${GLOW_VERSION}/glow_${GLOW_VERSION}_${arch}.deb" \
 && dpkg -i /tmp/glow.deb && rm /tmp/glow.deb

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
 && rustup component add rust-analyzer rustfmt clippy \
 && chmod -R a+rwX /usr/local/rustup /usr/local/cargo

# Make /usr/local/{go,cargo}/bin available to login shells (ssh/sudo/etc).
# Dockerfile's `ENV PATH=...` only reaches `docker exec`; sshd uses PAM and
# reads /etc/profile, which sources /etc/profile.d/*.sh.
RUN printf 'export PATH="/usr/local/cargo/bin:/usr/local/go/bin:$PATH"\n' \
        > /etc/profile.d/dev-paths.sh \
 && chmod 644 /etc/profile.d/dev-paths.sh

# --- helix (prebuilt tarball; binary is `hx`, symlink `helix` -> `hx` so both names work) ---
ARG HELIX_VERSION=25.07.1
RUN case "$(uname -m)" in x86_64) a=x86_64;; aarch64) a=aarch64;; esac \
 && curl -fsSL -o /tmp/helix.tar.xz \
        "https://github.com/helix-editor/helix/releases/download/${HELIX_VERSION}/helix-${HELIX_VERSION}-${a}-linux.tar.xz" \
 && mkdir -p /tmp/helix-extract /usr/local/share/helix \
 && tar -xJf /tmp/helix.tar.xz -C /tmp/helix-extract \
 && mv /tmp/helix-extract/*/hx /usr/local/bin/hx \
 && mv /tmp/helix-extract/*/runtime /usr/local/share/helix/runtime \
 && ln -s /usr/local/bin/hx /usr/local/bin/helix \
 && rm -rf /tmp/helix*
ENV HELIX_RUNTIME=/usr/local/share/helix/runtime

# --- xterm-ghostty terminfo (committed source; upstream removed the static
#     file in favor of a Zig generator, so we ship our own snapshot) ---
COPY terminfo/xterm-ghostty.src /tmp/xterm-ghostty.src
RUN tic -x -o /etc/terminfo /tmp/xterm-ghostty.src \
 && rm /tmp/xterm-ghostty.src

# --- sshd: pubkey-only, no root, no password; host keys baked at build time ---
RUN sed -i \
        -e 's/^#*\s*PasswordAuthentication.*/PasswordAuthentication no/' \
        -e 's/^#*\s*PermitRootLogin.*/PermitRootLogin no/' \
        -e 's/^#*\s*PubkeyAuthentication.*/PubkeyAuthentication yes/' \
        /etc/ssh/sshd_config \
 && ssh-keygen -A \
 && mkdir -p /run/sshd

# --- user setup ---
ARG USER=sergeik
ARG UID=1000
ARG GID=1000
RUN userdel -r ubuntu 2>/dev/null || true \
 && groupadd -g ${GID} ${USER} \
 && useradd -m -u ${UID} -g ${GID} -s /usr/bin/zsh -G sudo ${USER} \
 && echo "${USER} ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/${USER}

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

USER ${USER}
WORKDIR /home/${USER}

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["sleep", "infinity"]
