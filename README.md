> [!NOTE]
> Want to learn more about Mastodon?
> Click below to find out more in a video.

<p align="center">
  <a style="text-decoration:none" href="https://www.youtube.com/watch?v=IPSbNdBmWKE">
    <img alt="Mastodon hero image" src="./docs/hero-nodes.gif" />
  </a>
</p>

<p align="center">
  <a style="text-decoration:none" href="https://github.com/mastodon/mastodon/releases">
    <img src="https://img.shields.io/github/release/mastodon/mastodon.svg" alt="Release" /></a>
  <a style="text-decoration:none" href="https://github.com/mastodon/mastodon/actions/workflows/test-ruby.yml">
    <img src="https://github.com/mastodon/mastodon/actions/workflows/test-ruby.yml/badge.svg" alt="Ruby Testing" /></a>
  <a style="text-decoration:none" href="https://crowdin.com/project/mastodon">
    <img src="https://d322cqt584bo4o.cloudfront.net/mastodon/localized.svg" alt="Crowdin" /></a>
</p>

Mastodon is a **free, open-source social network server** based on [ActivityPub](https://www.w3.org/TR/activitypub/) where users can follow friends and discover new ones. On Mastodon, users can publish anything they want: links, pictures, text, and video. All Mastodon servers are interoperable as a federated network (users on one server can seamlessly communicate with users from another one, including non-Mastodon software that implements ActivityPub!)

## Navigation

- [Project homepage 🐘](https://joinmastodon.org)
- [Donate to support development 🎁](https://joinmastodon.org/sponsors#donate)
  - [View sponsors](https://joinmastodon.org/sponsors)
- [Blog 📰](https://blog.joinmastodon.org)
- [Documentation 📚](https://docs.joinmastodon.org)
- [Official container image 🚢](https://github.com/mastodon/mastodon/pkgs/container/mastodon)

## Features

<img src="./app/javascript/images/elephant_ui_working.svg?raw=true" align="right" width="30%" />

**Part of the Fediverse. Based on open standards, with no vendor lock-in.** - the network goes beyond just Mastodon; anything that implements ActivityPub is part of a broader social network known as [the Fediverse](https://jointhefediverse.net/). You can follow and interact with users on other servers (including those running different software), and they can follow you back.

**Real-time, chronological timeline updates** - updates of people you're following appear in real-time in the UI.

**Media attachments** - upload and view images and videos attached to the updates. Videos with no audio track are treated like animated GIFs; normal videos loop continuously.

**Safety and moderation tools** - Mastodon includes private posts, locked accounts, phrase filtering, muting, blocking, and many other features, along with a reporting and moderation system.

**OAuth2 and a straightforward REST API** - Mastodon acts as an OAuth2 provider, and third party apps can use the REST and Streaming APIs. This results in a [rich app ecosystem](https://joinmastodon.org/apps) with a variety of choices!

## Deployment

### Tech stack

- [Ruby on Rails](https://github.com/rails/rails) powers the REST API and other web pages.
- [PostgreSQL](https://www.postgresql.org/) is the main database.
- [Redis](https://redis.io/) and [Sidekiq](https://sidekiq.org/) are used for caching and queueing.
- [Node.js](https://nodejs.org/) powers the streaming API.
- [React.js](https://reactjs.org/) and [Redux](https://redux.js.org/) are used for the dynamic parts of the interface.
- [BrowserStack](https://www.browserstack.com/) supports testing on real devices and browsers. (This project is tested with BrowserStack)
- [Chromatic](https://www.chromatic.com/) provides visual regression testing. (This project is tested with Chromatic)

### Requirements

- **Ruby** 3.3+
- **PostgreSQL** 14+
- **Redis** 7.0+
- **Node.js** 22+
- **FFmpeg** 5.1+

This repository includes deployment configurations for **Docker and docker-compose**, as well as for other environments like Heroku and Scalingo. For Helm charts, reference the [mastodon/chart repository](https://github.com/mastodon/chart). A [**standalone** installation guide](https://docs.joinmastodon.org/admin/install/) is available in the main documentation.

## Developing with Flox

[![Flox Environment](https://github.com/justincastilla/mastodon-flox/actions/workflows/flox.yml/badge.svg)](https://github.com/justincastilla/mastodon-flox/actions/workflows/flox.yml)

This fork adds a [Flox](https://flox.dev) environment that sets up Mastodon's whole development stack with one command: Ruby, Node, PostgreSQL, Redis, the native media libraries, and every app process. You don't need Docker, a dev container, rbenv/nvm, Homebrew, or `apt-get`.

### Quick start

1. [Install Flox](https://flox.dev/docs/install-flox/install).
2. Clone the repo and start everything:

   ```sh
   git clone https://github.com/justincastilla/mastodon-flox.git
   cd mastodon-flox
   flox activate --start-services
   ```

3. Open <http://localhost:3000> and log in as `admin@localhost` with password `mastodonadmin`. This is the development seed account.

The first activation installs gems and node packages and creates a local PostgreSQL cluster. It takes a few minutes. After that, activation is close to instant.

### What you get

| Component                                     | Version               | Pinned by                                     |
| --------------------------------------------- | --------------------- | --------------------------------------------- |
| Ruby                                          | 4.0.6                 | `.ruby-version`                               |
| Node.js                                       | 24.19.0               | `.nvmrc`                                      |
| Yarn                                          | 4.18.1                | `packageManager` in `package.json` (corepack) |
| PostgreSQL                                    | 14                    | `docker-compose.yml`                          |
| Redis                                         | 8 (see note below)    | `docker-compose.yml`                          |
| libvips, FFmpeg, ICU, libidn, OpenSSL, `file` | from the Flox catalog | `Dockerfile`, `Aptfile`, `Gemfile`            |

Flox installs system-level tools. Bundler and Yarn still own the Ruby and JavaScript dependencies. The environment's activation hook runs `bundle install` and `yarn install` for you, and only when the lockfiles change.

### Services

`flox activate --start-services` (or `flox services start` inside an activated shell) runs the same processes as `Procfile.dev`, plus the datastores:

| Service     | What it runs                                             | Address                  |
| ----------- | -------------------------------------------------------- | ------------------------ |
| `postgres`  | PostgreSQL 14, unix socket only                          | `/tmp/mastodon-postgres` |
| `redis`     | Redis                                                    | `localhost:6379`         |
| `web`       | Puma (Rails). Runs `rails db:prepare` first, then serves | <http://localhost:3000>  |
| `sidekiq`   | Background jobs                                          | —                        |
| `streaming` | Node streaming API                                       | `localhost:4000`         |
| `vite`      | Frontend dev server with hot reload                      | `localhost:3036`         |

Database setup is automatic. On first start, `web` runs `bin/rails db:prepare`, which creates the database, loads the schema and seeds the admin account. On later starts it only applies pending migrations. `sidekiq` and `streaming` wait until the schema exists before they start.

Useful commands:

```sh
flox services status          # what's running
flox services logs web -f     # follow one service's logs
flox services restart web     # restart after changing config
flox services stop            # stop everything
```

All state lives in `.flox/cache/`, which git ignores: the PostgreSQL data, the gems and the corepack cache. To start over from an empty database, stop the services and delete `.flox/cache/postgres`.

### Platform support

| Platform                      | Supported |
| ----------------------------- | --------- |
| Linux x86_64                  | ✅        |
| Linux aarch64                 | ✅        |
| macOS Apple Silicon (aarch64) | ✅        |
| macOS Intel (x86_64)          | ❌        |

**Intel Macs are excluded on purpose.** The Flox catalog has no `x86_64-darwin` builds of `ruby_4_0`, `nodejs_24` at the pinned version, or several of the native libraries (vips, ffmpeg, icu, libidn, openssl, file). The manifest's `options.systems` therefore leaves that platform out, and activation would fail there anyway. On an Intel Mac, use the Docker or dev container setup instead.

CI checks all three supported platforms on every push. The [Flox Environment workflow](.github/workflows/flox.yml) builds the environment from scratch, boots every service and health-checks web and streaming.

### Notes and known differences

- **Redis 8 in development, Redis 7 in production.** `docker-compose.yml` uses `redis:7-alpine`, but the environment runs the catalog's Redis 8. Pinning 7.x left the package group unresolvable alongside the other pins. Mastodon requires Redis 7.0 or newer, and Redis 8 is backward compatible with the 7.x commands it relies on, so this is fine for development. If you add Redis-specific code, test it against 7 as well.
- **macOS and `LD_LIBRARY_PATH`.** macOS System Integrity Protection strips `DYLD_*` variables from scripts launched through `/usr/bin/env`, like `bin/rails` and `bin/dev`. The hook sets `LD_LIBRARY_PATH` so `ruby-vips` can still find libvips through ffi.
- **Optional services are not included.** Elasticsearch (full-text search) and LibreTranslate (translations) live in `.devcontainer/compose.yaml` and stay optional. Run them with Docker if you need those features.
- The environment is defined in [`.flox/env/manifest.toml`](.flox/env/manifest.toml). Every package has a comment recording why it is there and where its version comes from.

## Contributing

Mastodon is **free, open-source software** licensed under **AGPLv3**. We welcome contributions and help from anyone who wants to improve the project.

You should read the overall [CONTRIBUTING](https://github.com/mastodon/.github/blob/main/CONTRIBUTING.md) guide, which covers our development processes.

You should also read and understand the [CODE OF CONDUCT](https://github.com/mastodon/.github/blob/main/CODE_OF_CONDUCT.md) that enables us to maintain a welcoming and inclusive community. Collaboration begins with mutual respect and understanding.

You can learn about setting up a development environment in the [DEVELOPMENT](docs/DEVELOPMENT.md) documentation.

If you would like to help with translations 🌐 you can do so on [Crowdin](https://crowdin.com/project/mastodon).

## LICENSE

Copyright (c) 2016-2026 Eugen Rochko (+ [`mastodon authors`](AUTHORS.md))

Licensed under GNU Affero General Public License as stated in the [LICENSE](LICENSE):

```text
Copyright (c) 2016-2026 Eugen Rochko & other Mastodon contributors

This program is free software: you can redistribute it and/or modify it under
the terms of the GNU Affero General Public License as published by the Free
Software Foundation, either version 3 of the License, or (at your option) any
later version.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
details.

You should have received a copy of the GNU Affero General Public License along
with this program. If not, see https://www.gnu.org/licenses/
```
