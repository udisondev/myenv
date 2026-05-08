# myenv

Переносимая dev-среда на базе [distrobox](https://distrobox.it/): один и тот же
helix, zellij, zsh, Go и Rust разворачиваются изолированным контейнером на любом
маке или Linux-хосте. Хост-конфиги не трогаются — контейнер работает в
собственном `~/.distrobox-homes/devenv`.

## Что внутри

```
.
├── distrobox.ini             # Arch-base + список pacman-пакетов
├── bootstrap.sh              # внутри контейнера: симлинки + go install
├── host-setup.sh             # на хосте: ghostty config + skeleton ~/.ssh/config
├── setup-on-new-host.sh      # вызывает оба, делает distrobox assemble create
├── oh-my-zsh/                # git submodule, чтобы не качать его при bootstrap
└── dotfiles/
    ├── .zshrc                # без секретов, без GOPROXY — только общая часть
    ├── .zshrc.local.example  # шаблон для per-machine оверрайдов
    ├── .ssh/config.example   # ForwardAgent + RemoteCommand-распихивание
    └── .config/
        ├── ghostty/config    # шрифт + ssh-terminfo integration (только на хосте)
        ├── helix/            # config.toml + languages.toml (только в контейнере)
        ├── zellij/config.kdl
        └── glow/glow.yml
```

## Развёртывание на новой машине

### 1. Поставить рантайм и distrobox (один раз на хост)

**macOS:**

```sh
brew install colima podman distrobox
brew install --cask ghostty
podman machine init
podman machine start
```

**Arch / CachyOS:**

```sh
sudo pacman -S podman distrobox ghostty
```

**Debian / Ubuntu:**

```sh
sudo apt install podman uidmap
curl -s https://raw.githubusercontent.com/89luca89/distrobox/main/install | sudo sh
# ghostty: смотри https://ghostty.org/download
```

### 2. Клонировать репо и запустить setup

```sh
git clone --recurse-submodules git@github.com:udisondev/myenv.git ~/dev-env
cd ~/dev-env && ./setup-on-new-host.sh
```

`--recurse-submodules` нужен для oh-my-zsh. Если забыл — `setup-on-new-host.sh`
сам запустит `git submodule update --init --recursive`.

Что делает скрипт:

1. Хост-фаза (`host-setup.sh`): симлинк на ghostty config, копия `~/.ssh/config`
   из шаблона если его ещё нет.
2. Контейнер (`distrobox assemble create`): pull `archlinux:latest`, установка
   ~30 пакетов через pacman, запуск `bootstrap.sh` внутри: симлинки на helix /
   zellij / zsh, `go install` нужных Go-инструментов, смена shell на zsh.

Первый прогон занимает 5–10 минут (pull образа + пакеты + Go-зависимости).

### 3. Войти в среду и вписать локальные секреты

```sh
distrobox enter devenv
hx ~/.zshrc.local      # переменные специфичные именно для этой машины
```

В `~/.zshrc.local` обычно идут: токены, корпоративные `GOPROXY`, опциональные
toolchain'ы (ESP32 и т.п.). Файл уже создан из шаблона при первом bootstrap'е.

### 4. (Опционально, только Hyprland) повесить ghostty на Super+Q

В `~/.config/hypr/hyprland.conf`:

```
$terminal = ghostty
```

и убедиться, что есть `bind = $mainMod, Q, exec, $terminal`. Перезагрузить:
`hyprctl reload`.

## Как пользоваться каждый день

```sh
distrobox enter devenv     # попасть в среду
zj                         # zellij: подключиться к последней живой сессии
                           # или создать новую
exit                       # выйти из контейнера, хост-shell не тронут
```

## Обновление с upstream

```sh
cd ~/dev-env
git pull
git submodule update --init --recursive   # если поменялся pinned commit oh-my-zsh
distrobox enter devenv -- bash ~/dev-env/bootstrap.sh   # переприменить bootstrap
```

Если поменялись `additional_packages` в `distrobox.ini` — пересоздать контейнер:

```sh
distrobox rm devenv --force
podman unshare rm -rf ~/.distrobox-homes/devenv
./setup-on-new-host.sh
```

## Что не входит в репо

`*.local`, `~/.ssh/id_*`, `~/.ssh/known_hosts*`, реальный `~/.ssh/config` — всё
это per-machine и в `.gitignore`. Шаблоны лежат как `*.example`, реальные файлы
создаются на каждой машине отдельно.

## Известные ограничения

- На Linux-хосте поверх дефолтного bind-mount'а `/home/$USER` репо доступен в
  контейнере по тому же абсолютному пути. На macOS это работает так же через
  podman-machine, но если у тебя какие-то нестандартные пути — придётся
  поправить `home=` в `distrobox.ini`.
- `additional_volumes` distrobox-assemble не парсит список через `;` — поэтому
  явных volume mount'ов в конфиге нет, всё работает через дефолтное
  монтирование `/home`.
- Ghostty-эмулятор живёт на хосте, не в контейнере: внутри distrobox только
  пакет `ghostty-terminfo` (записи `xterm-ghostty`).
