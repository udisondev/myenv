# myenv

Переносимая dev-среда: один и тот же helix, zellij, zsh, Go и Rust в Docker-контейнере. Работает на macOS, Linux и Windows (WSL2) одинаково — везде, где запускается Docker.

## Что внутри

```
.
├── Dockerfile              # ubuntu:24.04 (multi-arch) + apt + upstream tarballs
├── compose.yml             # запуск контейнера + volumes + sshd-порт
├── entrypoint.sh           # поднимает sshd, вызывает bootstrap.sh
├── bootstrap.sh            # симлинки + go install (идемпотентный)
├── terminfo/               # снапшот xterm-ghostty terminfo
├── oh-my-zsh/              # git submodule
└── dotfiles/
    ├── .zshrc
    ├── .zshrc.local.example
    ├── .ssh/config.example
    └── .config/
        ├── ghostty/config  # для хост-системы (контейнер ghostty не нужен)
        ├── helix/
        ├── zellij/
        └── glow/
```

## Установка

### 1. Поставить Docker

| ОС | Команда |
|---|---|
| macOS | `brew install --cask orbstack` (рекомендую) или Docker Desktop |
| Arch / CachyOS | `sudo pacman -S docker docker-compose` + `sudo systemctl enable --now docker` + `sudo usermod -aG docker $USER` |
| Debian / Ubuntu | `sudo apt install docker.io docker-compose-plugin` + добавить себя в группу `docker` |

После установки на Linux нужно перелогиниться, чтобы группа `docker` применилась.

### 2. Клонировать репо, подготовить `.env`, поднять контейнер

```sh
git clone --recurse-submodules git@github.com:udisondev/myenv.git
cd myenv

# .env — чтобы UID/GID контейнера совпали с хостом (на маке UID обычно 501).
# Если pubkey не id_ed25519.pub, доппишите SSH_PUBKEY=...
printf "HOST_UID=%s\nHOST_GID=%s\nUSER=%s\n" "$(id -u)" "$(id -g)" "$(id -un)" > .env

docker compose up -d --build
```

Первая сборка — 5–7 минут (всё ставится из бинарных релизов, без cargo-сборки). Следующие — секунды.

### 3. Прописать SSH-хост и войти

В `~/.ssh/config` на хосте:

```
Host devenv
  HostName 127.0.0.1
  Port 2222
  User <your-user>     # то же, что в .env
  ForwardAgent yes
```

Дальше:

```sh
ssh devenv
```

Внутри — zsh с oh-my-zsh, helix/zellij/yazi и твоими биндингами. Конфиги — симлинки на `dotfiles/` из репо: правишь файл на хосте, в контейнере применяется сразу. Через ssh с Ghostty terminfo `xterm-ghostty` уже запечён в образе, поэтому никакого двоения букв и сломанного backspace.

### 4. Локальные секреты

```sh
hx ~/.zshrc.local   # внутри контейнера
```

`~/.zshrc.local` уже создан из шаблона. Туда — машинно-специфичные `GOPROXY`, токены, опциональные toolchain'ы. В репо не попадает.

## Каждодневное использование

```sh
ssh devenv        # попасть в среду (через хост-овский ssh-agent)
zj                # zellij: подключиться к последней живой сессии или создать новую
exit              # выйти из контейнера, хост-shell не тронут
```

Контейнер `devenv` сам перезапускается при ребуте хоста (`restart: unless-stopped`).

После каждого `--build` host keys внутри образа перегенерируются; ssh ругнётся на mismatch — почистить запись:

```sh
ssh-keygen -R '[127.0.0.1]:2222'
```

(или один раз добавить в `Host devenv` блок `StrictHostKeyChecking accept-new` — для loopback'а это безопасно).

## Обновление

```sh
cd ~/myenv
git pull
git submodule update --init --recursive
docker compose up -d --build      # пересобрать с актуальными пакетами
docker exec devenv bash /home/$USER/myenv/bootstrap.sh   # пере-применить bootstrap
```

## Volumes — что куда смонтировано

- `.` (репо) → `/home/$USER/myenv` (read-only): bootstrap читает отсюда конфиги.
- `~/Projects` → `/home/$USER/Projects` (rw): рабочие проекты, шарятся с хостом.
- `devenv-home` (named volume) → `/home/$USER`: где живёт `~/.config`, `~/.zshrc.local`, `~/go/bin`. Сохраняется между перезапусками контейнера.
- `$SSH_AUTH_SOCK` → `/ssh-agent`: проброс ssh-агента хоста, `git push` работает прямо из контейнера без копирования ключей.
- `$SSH_PUBKEY` (по умолчанию `~/.ssh/id_ed25519.pub`) → `/etc/ssh/host_authorized_key` (ro): pubkey хоста, entrypoint кладёт его в `~/.ssh/authorized_keys` для входа по `ssh devenv`.

## Порты

- `127.0.0.1:2222` → `22` (sshd внутри). Слушает только loopback, наружу не торчит.

## Что не входит в репо

`*.local`, `~/.ssh/id_*`, реальный `~/.ssh/config`, `~/.zshrc.local` — всё в `.gitignore`. На каждой машине эти файлы создаются отдельно: `~/.zshrc.local` сидится из шаблона при первом bootstrap, остальное — руками.

## Полный сброс

```sh
docker compose down -v          # снести контейнер и devenv-home volume
docker compose up -d --build    # поднять заново
```
