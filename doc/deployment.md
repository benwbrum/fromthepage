# Deployment

How code gets from a feature branch to fromthepage.com, and what that means for changes you make.
Sources: `Capfile`, `config/deploy.rb`, `config/deploy/*.rb`, `.github/workflows/ci.yml`, and branch history.

## Branches

| Branch | Role |
|---|---|
| `development` | Integration branch. Every feature/fix PR targets it. CI runs here. |
| `fromthepage.com` | **Production deploy branch.** `config/deploy/production.rb` deploys whatever is on it. |
| `staging`, `master` | Stale since 2020. `staging.rb` points at `fromthepage.com-rails6` and `nybg.rb` at `master`; neither reflects current code. Don't use them without checking with a maintainer first. |

Promotion is a PR from `development` into `fromthepage.com` (titles like "dev to deployment", or a GitHub
"Merge pull request … from benwbrum/development"). Code doesn't go directly onto `fromthepage.com`, so anything
merged into `development` ships in the next promotion along with everything else waiting there.

## Release flow

1. Feature branch `<issue>-description` → PR into `development` → CI (4 rspec shards, rubocop on PRs,
   SolidQueue boot check, linked-file check on pushes) → merge.
2. A maintainer opens a promotion PR from `development` into `fromthepage.com` and merges it.
3. A maintainer with SSH access as the `fromthepage` user runs `bundle exec cap production deploy` from a local checkout.
   No CI job deploys automatically.

## What `cap production deploy` does

Capistrano 3 (`capistrano`, `capistrano-bundler`, `capistrano-rails`, `rvm1-capistrano3`; Ruby from `.ruby-version`).
Releases live under `/home/fromthepage/deployment`:

```
deployment/
  releases/<timestamp>/   one directory per deploy; the last 20 are kept (keep_releases)
  current -> releases/…   symlink the app server serves from
  shared/                 linked files and dirs, which persist across releases
```

In order:

1. **Check:** linked files must already exist in `shared/`, or the deploy aborts.
2. **Update:** `fromthepage.com` is checked out into a new release dir, and `shared/` files and dirs are symlinked in.
3. **Build:** in the new release, with `RAILS_ENV=production` and the shared `.env` loaded:
   - `bundle install`
   - `npm ci --omit=dev`, needed by Grover/Puppeteer for PDF export
   - `rake assets:precompile`
   - `rake db:migrate`
4. **Publish:** `current` is switched to the new release.
5. **Restart:**
   - `touch tmp/restart.txt` restarts the app. It runs under Phusion Passenger behind nginx (and Cloudflare);
     Puma is in the Gemfile but isn't the production server.
   - `sudo systemctl restart solid_queue` restarts job workers.
   - A `clear_cache` hook runs after that, but it's currently empty.

`bundle exec cap production deploy:rollback` points `current` back at the previous release and restarts it. It does
**not** roll back migrations or anything in `shared/`.

## Linked (shared) files and dirs

These are not taken from git on the server. Each one is a symlink into `shared/`, maintained by hand on each server:

- **Files** (`linked_files`): `.env`, `config.ru`, `config/database.yml`, `config/environments/production.rb`,
  `config/initializers/01fromthepage.rb`, `config/initializers/rack_attack.rb`, `config/initializers/omniauth.rb`,
  `config/newrelic.yml`, `public/robots.txt`
- **Dirs** (`linked_dirs`): `log`, `tmp`, `public/uploads`, `public/text`, `public/images/{working,uploaded,fordham,zebrapedia}`

Implications:

- Changes in git to a linked file never reach production. That's why CI fails a push that touches one: the change
  has to be coordinated with whoever maintains the server copy. `.env` is gitignored, so CI doesn't check it.
- Adding a new linked file or dir takes three changes: create it in `shared/` on every server first, then add it
  to `linked_files` in `config/deploy.rb` and to the CI list in `.github/workflows/ci.yml`. Otherwise the deploy check fails.
- Anything the app writes under `public/` **outside** a linked dir lives inside one release. It's gone after the
  next deploy and deleted once the release falls out of the last 20. Write durable files to a linked dir or Active Storage.

## Writing deploy-safe changes

- **New ENV variable:** add it to `.env.example`. A maintainer must add it to the shared `.env` on each server
  **before** the deploy that reads it. Asset precompile and migrations run with that `.env`, so a missing
  required var fails the deploy rather than the first request.
- **Migrations:** they run before the restart, so the old code briefly runs against the new schema, and after a
  `deploy:rollback` the old code keeps running against it. Prefer additive migrations (add column, then backfill,
  then switch reads; remove the column in a later release). Note anything destructive in the PR.
- **Jobs:** SolidQueue workers restart after the app, and jobs queued by the old code are run by the new code.
  Keep `perform` signatures backward-compatible for one release, or drain the queue first.
- **Deleted files come back on rollback.** Rolling back to a release from before a file was deleted restores it.
  This matters when you remove an initializer that overrides config (for example one that sets a secret or a
  security setting): the old behaviour returns with it.
- **Secrets** belong in the shared `.env` (or Rails credentials), never in git. Rotating `SECRET_KEY_BASE`
  invalidates every signed or encrypted value derived from it: sessions (everyone is logged out),
  remember-me cookies, Devise reset and confirmation tokens, and Active Storage signed ids and URLs.
  Do it during a quiet window.
- **Node and system dependencies** (Puppeteer, ImageMagick, Ghostscript) are installed on the server outside
  Capistrano, apart from `npm ci`. Call out version bumps in the PR so a maintainer can check the host.

## PR checklist for deploy-affecting changes

Add a **Deployment notes** section to the PR description when any of these apply:

- [ ] New or changed ENV vars, and which servers need them
- [ ] Linked file or dir added or changed (and the CI list updated)
- [ ] Migrations that are destructive, slow on large tables, or not rollback-safe
- [ ] Job argument changes, or a queue drain needed
- [ ] Server package or system dependency changes
- [ ] Expected user-visible side effects (forced logout, cache misses, downtime)

## Known stale bits in the Capistrano config

- `config/deploy.rb` sets a default `:branch` of `ui-design` and has a "valid only for Capistrano 3.1" comment.
  Each stage file overrides the branch, and the locked Capistrano version is 3.20.
- `staging.rb` and `nybg.rb` reference branches that no longer track current code (see Branches above).
