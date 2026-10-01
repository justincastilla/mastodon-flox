#!/usr/bin/env bash
# Deploy the latest main to floxtodon.dev. Run as root on the server:
#   sudo bash /home/mastodon/live/deploy/deploy.sh
# Pulls the code, rebuilds frontend assets inside the production Flox
# environment, then restarts everything. Database migrations run
# automatically when the web service starts (rails db:prepare).
set -euo pipefail

APP_USER=mastodon
LIVE=/home/$APP_USER/live

sudo -u "$APP_USER" git -C "$LIVE" pull --ff-only
install -m 0644 "$LIVE/deploy/server/floxtodon.service" /etc/systemd/system/floxtodon.service
systemctl daemon-reload

# Install dependencies explicitly: while floxtodon.service is running, this
# `flox activate` attaches to its existing activation and skips the on-activate
# hook, so the hook's bundle/yarn install would not pick up new lockfiles.
echo "== installing dependencies and building assets (a few minutes on an e2-small)"
sudo -u "$APP_USER" bash -c "cd '$LIVE' && flox activate -d deploy/server -c 'cd \"\$MASTODON_ROOT\" && bundle install --quiet && yarn install --immutable && bundle exec rails assets:precompile'"

systemctl restart floxtodon.service
echo "Restarted. Follow logs: sudo -u $APP_USER flox services logs -d $LIVE/deploy/server --follow web"
