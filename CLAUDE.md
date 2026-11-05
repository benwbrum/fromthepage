# FromThePage — Claude guide

Rails 7.2 / Ruby 3.3.5 crowdsourced transcription platform. MariaDB (mysql2), Elasticsearch via Chewy,
SolidQueue for jobs, Importmap + Stimulus + Turbo (Drive disabled), Slim views. Main branch: `development`.

Scoped rules live in `.claude/rules/` and load when you touch matching paths:
`interactors.md`, `jobs.md`, `testing.md`, `database.md`, `frontend.md`, `security.md`.

## Commands (non-obvious only)

- Test DB rebuild (needed after schema changes or polluted data):
  - `RAILS_ENV=test ELASTIC_ENABLED=false bin/rake db:drop db:create db:migrate`
  - `RAILS_ENV=test ELASTIC_ENABLED=false bin/rake db:fixtures:load FIXTURES_PATH=spec/fixtures`
- Run a spec: `RAILS_ENV=test ELASTIC_SUFFIX=test ELASTIC_ENABLED=false bundle exec rspec spec/path_spec.rb:LINE`
  - AI specs also need `GEMINI_API_KEY` set to any non-empty value (CI uses `redacted`)
  - Add `COVERAGE=true` to generate `coverage/lcov.info`
- Reproduce a CI shard locally: `CI_NODE_INDEX=0 CI_NODE_TOTAL=4 bin/ci` (round-robin split of sorted spec files)
- Feature (JS) specs need Chromium; headless boxes use `xvfb-run -a`
- Elasticsearch (only when `ELASTIC_ENABLED=true`):
  - `bin/rake fromthepage:es:setup:init` → `fromthepage:es:data:build` → `fromthepage:es:data:reindex`
  - `ELASTIC_SUFFIX` namespaces indices per env — always set it so test/dev don't share indices
- Job workers: `bin/jobs` or `bundle exec rails solid_queue:start`; dashboard at `/solid_queue` (admin-only, MissionControl)
- Before committing: `bundle exec rubocop -A` (CI rubocop job runs on PRs only)
- i18n is enforced by `spec/i18n_spec.rb` — use `i18n-tasks missing` / `i18n-tasks unused` to fix failures

## Domain model & roles

- Hierarchy: User (owner) → Collection → Work → Page → PageVersion; Articles = subjects linked from pages
- DocumentSet = curated subset of works across a collection; many routes accept it in place of a collection
- Deeds = activity log records (transcribe, review, index…) driving stats and notifications
- Roles:
  - Transcriber — works in public collections
  - Project Owner — creates collections/uploads; Trial owners are flagged with extra upload limits
  - Staff — added as owner on a collection; can create collections under the original owner's account
  - Admin — system-wide settings, can masquerade as any user (`devise_masquerade`)
- Use `user.like_owner?(obj)` for "owner-ish" checks (covers owners + staff); `user.can_transcribe?(work)` for edit rights
- Collection visibility: `collection.show_to?(user)` (restricted flag, blocks, collaborators)

## Request lifecycle (ApplicationController)

- `load_objects_from_params` auto-loads `@collection/@work/@page/@article/...` from `*_id` params
  - Order matters: specific → general; `collection_id` wins last. Don't re-find these in actions
  - IDs may be friendly slugs (`Work.friendly.find`, `set_friendly_collection`)
- `authorize_collection` runs on every request with `@collection`; controllers add their own `authorized?` filter
- `Current.user` / `Current.session` are set per request (and per job — see `jobs.md`); models may read them
- Routes are slug-scoped (`/:user_slug/:collection_id/...`); prefer named route helpers over hand-built paths

## Architecture rules

- Business logic with side effects → interactor in `app/interactors/<domain>/<verb>.rb` (see `interactors.md`)
  - Controllers: `result = Domain::Verb.new(...).call`, then branch on `result.success?`
- Anything slow, external, or bulk → ActiveJob on SolidQueue in `app/jobs/<domain>/` (see `jobs.md`)
- Domain helpers shared by interactors go in `app/interactors/<domain>/lib/` — not top-level `lib/`
- Top-level `lib/` holds integrations (IIIF, Transkribus, Gemini/OpenAI, ContentDM, exporters) and rake tasks
- AI transcription engines live in `app/interactors/ai_transcription/lib/{gemini,claude}` behind `base_transcribe_handler.rb`
- Config values go in `config/settings.yml` + `config/settings/<env>.yml`, read via `Settings.foo.bar` (config gem)
  - Global constants (e.g. `ELASTIC_ENABLED`, `SMTP_ENABLED`) come from `config/initializers/01fromthepage.rb`
- Search indexing is model-driven: `update_index('works', if: -> { ELASTIC_ENABLED ... })` — keep the guard
- Forums are the Thredded engine; `Thredded::Engine.routes.default_url_options` is set per request
- Text pipeline: `source_text` → `XmlSourceProcessor` → `xml_text`; never render `source_text` as HTML directly

## Protected ("linked") files — do not edit without explicit approval

- CI fails on push if any of these change (they're symlinked/overridden on production servers):
  - `config.ru`, `config/database.yml`, `config/environments/production.rb`
  - `config/initializers/01fromthepage.rb`, `config/initializers/rack_attack.rb`, `config/initializers/omniauth.rb`
  - `config/newrelic.yml`, `public/robots.txt`

## CI gotchas

- CI greps the whole repo for `binding.pry` and fails — remove debuggers before pushing
- 4 parallel shards; flaky failures often come from spec order/data leakage (see `testing.md`)
- A separate job boots SolidQueue workers in test env for 5s — `config/queue.yml` and job class loading must stay valid
- Coveralls runs on PRs; new lines should be covered by specs

## Workflow expectations

- Branch naming: `feature/<issue-number>-brief-description`
- For issue work: plan first (code changes, impacts, tests, perf, security, back-compat, source link e.g. Featurebase) and get approval before implementing
- Include specs covering every new line; improving coverage of adjacent code is welcome
- Untracked scratch files in repo root (`*.txt`, `test.rb`, `html.html`, `bin/run_specs`) are personal — never commit them
