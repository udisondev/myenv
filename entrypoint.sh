#!/usr/bin/env bash
set -e

# Seed authorized_keys from a host-mounted pubkey (compose mounts it RO at
# /etc/ssh/host_authorized_key). Idempotent — rewritten on every start.
if [ -f /etc/ssh/host_authorized_key ]; then
  install -d -m 700 "$HOME/.ssh"
  install -m 600 /etc/ssh/host_authorized_key "$HOME/.ssh/authorized_keys"
fi

# Start sshd if installed and host keys are present
if [ -x /usr/sbin/sshd ] && ls /etc/ssh/ssh_host_*_key >/dev/null 2>&1; then
  sudo /usr/sbin/sshd
fi

REPO="/home/${USER:-sergeik}/myenv"
if [ -f "$REPO/bootstrap.sh" ]; then
  bash "$REPO/bootstrap.sh" || true
fi

exec "$@"
