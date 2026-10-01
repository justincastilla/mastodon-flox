#!/usr/bin/env bash
# One-time (and re-runnable) setup of a fresh Debian 12 VM for floxtodon.dev.
# Run as root on the server:  sudo bash deploy/provision.sh
# Installs Flox, creates the `mastodon` user, checks out the repo and installs
# the systemd unit. Everything Mastodon needs beyond that comes from Flox.
set -euo pipefail

REPO_URL="${REPO_URL:-https://github.com/justincastilla/mastodon-flox.git}"
APP_USER=mastodon
APP_HOME=/home/$APP_USER
DATA_DIR=/var/lib/floxtodon

echo "== swap (4G) — an e2-small has 2 GB RAM; asset builds need more"
if ! swapon --show | grep -q /swapfile; then
  fallocate -l 4G /swapfile
  chmod 600 /swapfile
  mkswap /swapfile >/dev/null
  swapon /swapfile
  grep -q '^/swapfile' /etc/fstab || echo '/swapfile none swap sw 0 0' >> /etc/fstab
fi

echo "== let unprivileged processes (caddy) bind 80/443"
echo 'net.ipv4.ip_unprivileged_port_start=80' > /etc/sysctl.d/60-floxtodon.conf
sysctl -q --system

echo "== base packages"
apt-get update -qq
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq git curl ca-certificates >/dev/null

echo "== Flox"
if ! command -v flox >/dev/null; then
  arch="$(uname -m)"
  curl -fsSL -o /tmp/flox.deb "https://downloads.flox.dev/by-env/stable/deb/flox.${arch}-linux.deb"
  DEBIAN_FRONTEND=noninteractive apt-get install -y -qq /tmp/flox.deb >/dev/null
  rm -f /tmp/flox.deb
fi
flox --version

echo "== app user and data directory"
id "$APP_USER" >/dev/null 2>&1 || useradd --create-home --shell /bin/bash "$APP_USER"
install -d -o "$APP_USER" -g "$APP_USER" -m 0700 "$DATA_DIR"

echo "== code"
if [ -d "$APP_HOME/live/.git" ]; then
  sudo -u "$APP_USER" git -C "$APP_HOME/live" pull --ff-only
else
  sudo -u "$APP_USER" git clone "$REPO_URL" "$APP_HOME/live"
fi

echo "== systemd unit"
install -m 0644 "$APP_HOME/live/deploy/server/floxtodon.service" /etc/systemd/system/floxtodon.service
systemctl daemon-reload
systemctl enable floxtodon.service >/dev/null

echo "Provisioned. Next: sudo -u $APP_USER bash $APP_HOME/live/deploy/configure.sh"
