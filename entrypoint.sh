#!/usr/bin/env bash
set -e

REPO="/home/${USER:-sergeik}/myenv"
if [ -f "$REPO/bootstrap.sh" ]; then
  bash "$REPO/bootstrap.sh" || true
fi

exec "$@"
