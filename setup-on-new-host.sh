#!/usr/bin/env bash
# Bootstrap dev-env on a fresh host (mac via colima/podman-machine, or any Linux).
#
# Prerequisites you provide manually (one-time per machine):
#   1. A working podman or docker (on macOS: `brew install colima podman`, then
#      `colima start --runtime docker` or `podman machine init && podman machine start`).
#   2. distrobox installed: see https://distrobox.it/#installation
#      (on macOS via brew: `brew install distrobox`; on Arch: `pacman -S distrobox`).
#
# Then clone this repo and run this script:
#   git clone <repo> ~/dev-env && cd ~/dev-env && ./setup-on-new-host.sh

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONTAINER_NAME="devenv"

if ! command -v distrobox >/dev/null; then
  echo "distrobox is not installed. See https://distrobox.it/#installation" >&2
  exit 1
fi

if ! command -v podman >/dev/null && ! command -v docker >/dev/null; then
  echo "Neither podman nor docker is installed/runnable." >&2
  exit 1
fi

echo "==> Host-side setup (ghostty config, ssh config skeleton)"
"$REPO_DIR/host-setup.sh"

echo ""
echo "==> Distrobox container"
if distrobox list 2>/dev/null | grep -q "^[^ ]* *| *$CONTAINER_NAME "; then
  echo "Container '$CONTAINER_NAME' already exists. Re-running bootstrap inside it..."
  distrobox enter "$CONTAINER_NAME" -- bash "/home/$USER/dev-env/bootstrap.sh"
else
  echo "Creating distrobox container '$CONTAINER_NAME'..."
  distrobox assemble create --file "$REPO_DIR/distrobox.ini"
fi

echo ""
echo "Done. Enter with:  distrobox enter $CONTAINER_NAME"
echo "Or set as default by exporting:  export DBX_CONTAINER_DEFAULT_NAME=$CONTAINER_NAME"
