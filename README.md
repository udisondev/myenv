# myenv

Переносимая dev-среда: один и тот же helix, zellij, zsh, Go и Rust в Docker-контейнере. Работает на macOS, Linux и Windows (WSL2) одинаково — везде, где запускается Docker.

## Что внутри

```
.
├── Dockerfile              # ubuntu:24.04 (multi-arch) + apt + upstream tarballs
├── compose.yml             # запуск контейнера + volumes
├── entrypoint.sh           # вызывает bootstrap.sh при старте
├── bootstrap.sh            # симлинки + go install (идемпотентный)
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

# .env — чтобы UID/GID контейнера совпали с хостом (на маке UID обычно 501)
printf "HOST_UID=%s\nHOST_GID=%s\nUSER=%s\n" "$(id -u)" "$(id -g)" "$(id -un)" > .env

docker compose up -d --build
```

Первая сборка — 10–15 минут (helix компилируется из исходников, плюс go-инструменты на первом старте). После — секунды на старт.

### 3. Войти в среду

```sh
docker exec -it devenv zsh
```

При первом входе ты в zsh с oh-my-zsh, готовыми helix/zellij/yazi и всеми твоими биндингами. Конфиги — симлинки на `dotfiles/` из репо: правишь файл на хосте, в контейнере применяется сразу.

### 4. Локальные секреты

```sh
hx ~/.zshrc.local   # внутри контейнера
```

`~/.zshrc.local` уже создан из шаблона. Туда — машинно-специфичные `GOPROXY`, токены, опциональные toolchain'ы. В репо не попадает.

## Каждодневное использование

Удобный alias на хост-стороне:

```sh
echo 'alias dev="docker exec -it devenv zsh"' >> ~/.zshrc
```

Дальше:

```sh
dev               # попасть в среду
zj                # zellij: подключиться к последней живой сессии или создать новую
exit              # выйти из контейнера, хост-shell не тронут
```

Контейнер `devenv` сам перезапускается при ребуте хоста (`restart: unless-stopped`).

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

## Что не входит в репо

`*.local`, `~/.ssh/id_*`, реальный `~/.ssh/config`, `~/.zshrc.local` — всё в `.gitignore`. На каждой машине эти файлы создаются отдельно: `~/.zshrc.local` сидится из шаблона при первом bootstrap, остальное — руками.

## Полный сброс

```sh
docker compose down -v          # снести контейнер и devenv-home volume
docker compose up -d --build    # поднять заново
```
