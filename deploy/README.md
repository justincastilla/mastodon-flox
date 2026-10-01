# Deploying floxtodon.dev with Flox

This directory runs Mastodon in production on a single Google Cloud VM, using the
same Flox tooling as local development. There's no Docker, no nginx package and no
`apt-get install` of Ruby, Node or PostgreSQL. The VM gets Flox, and Flox provides
everything else.

```
deploy/
├── ops/            Flox environment for the operator's laptop (gcloud CLI)
├── server/         Flox environment that runs in production
│   ├── .flox/      postgres, redis, puma, sidekiq, streaming, caddy as Flox services
│   ├── Caddyfile   HTTPS (automatic Let's Encrypt) + routing, replaces dist/nginx.conf
│   └── floxtodon.service   systemd unit: one `flox activate --start-services`
├── provision.sh    one-time VM setup: swap, Flox, app user, checkout, systemd
├── configure.sh    one-time: writes .env.production with secrets generated on the VM
└── deploy.sh       every deploy: pull, build assets, restart
```

## How it runs

```
systemd ─▶ flox activate -d deploy/server --start-services
              ├── postgres   (unix socket, peer auth, data in /var/lib/floxtodon)
              ├── redis      (127.0.0.1, append-only file in /var/lib/floxtodon)
              ├── web        (rails db:prepare, then puma on 127.0.0.1:3000)
              ├── sidekiq    (5 threads)
              ├── streaming  (127.0.0.1:4000)
              └── caddy      (:80/:443 → streaming / static files / puma)
```

The production environment pins the same Ruby 4.0.6 and Node 24.19.0 as development.
Persistent state lives in `/var/lib/floxtodon`, outside the checkout. Secrets live in
`.env.production` (mode 600, git-ignored), which is generated on the server.

## GCP resources (project `floxtodon`, region `us-west1`)

| Resource       | Name                                                                        |
| -------------- | --------------------------------------------------------------------------- |
| VM             | `floxtodon`: e2-small, Debian 12, us-west1-c, 4 GB swap                     |
| Static IP      | `floxtodon-ip`                                                              |
| Cloud DNS zone | `floxtodon-dev` (the registrar, Porkbun, delegates to Google's nameservers) |
| Firewall       | `allow-http-https`: tcp 80/443 to instances tagged `web`                    |
| Media bucket   | `floxtodon-media`, uniform access, served through GCS's S3-compatible API   |

## First-time setup

Run these from the repo root on the operator's machine. `deploy/ops` provides `gcloud`.

```sh
flox activate -d deploy/ops
gcloud compute ssh floxtodon --zone us-west1-c -- 'sudo bash -s' < deploy/provision.sh
gcloud compute ssh floxtodon --zone us-west1-c -- 'sudo -u mastodon bash /home/mastodon/live/deploy/configure.sh'
```

Then fill in the values that only you should hold, directly on the server:

```sh
gcloud compute ssh floxtodon --zone us-west1-c
sudo -u mastodon nano /home/mastodon/live/.env.production   # SMTP_LOGIN, SMTP_PASSWORD (Mailjet)
```

Build the assets and start everything:

```sh
gcloud compute ssh floxtodon --zone us-west1-c -- 'sudo bash /home/mastodon/live/deploy/deploy.sh'
```

Create your admin account. The generated password is printed only to your terminal:

```sh
gcloud compute ssh floxtodon --zone us-west1-c -- \
  "sudo -u mastodon bash -c 'cd ~/live && flox activate -d deploy/server -c \"bin/tootctl accounts create USERNAME --email YOU@example.com --confirmed --approve --role Owner\"'"
```

## Day to day

```sh
# deploy the latest main
gcloud compute ssh floxtodon --zone us-west1-c -- 'sudo bash /home/mastodon/live/deploy/deploy.sh'

# service status and logs
gcloud compute ssh floxtodon --zone us-west1-c -- 'sudo -u mastodon flox services status -d /home/mastodon/live/deploy/server'
gcloud compute ssh floxtodon --zone us-west1-c -- 'sudo -u mastodon flox services logs -d /home/mastodon/live/deploy/server --follow web'
```

## Sizing

An e2-small has 2 GB RAM. The environment runs one Puma worker (`WEB_CONCURRENCY=1`)
and five Sidekiq threads, and `provision.sh` adds 4 GB of swap for asset builds. To
grow, stop the VM, change its machine type, then start it again. The disk, IP and data
are unaffected.
