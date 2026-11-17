---
paths:
  - "spec/**"
---

# Testing (RSpec)

- Everything requires `spec_helper` (no `rails_helper`); spec type inferred from directory
- Prefer: `spec/requests` for controllers, `spec/interactors`, `spec/jobs`, `spec/models`;
  `spec/features` (Capybara + Selenium/Chromium) only for real JS/UI flows — they're slow
- Database state is NOT reset between examples:
  - `use_transactional_fixtures = false` and DatabaseCleaner is only started manually in a few feature specs
  - Fixtures are loaded once into the test DB via `rake db:fixtures:load FIXTURES_PATH=spec/fixtures`,
    not per example — re-run that rake task after rebuilding the DB
  - So: never assume empty tables or exact global counts; scope assertions to records you created
  - Use `create(:unique_user, ...)` / unique attributes to avoid uniqueness collisions across examples
- Fixture users (logins as constants in `spec_helper`): `ADMIN`="julia", `OWNER`="margaret", `USER`="eleanor",
  `NEW_OWNER`="harry", `REST_USER`="george", `INACTIVE`="ron". Many specs use `User.first` as an owner
- Destructive feature specs are prefixed `zz_` so they run last — keep that convention for specs that delete
  fixture data
- Auth in request/feature specs: `login_as user` (Warden helpers)
- `before(:suite)` runs `rake assets:precompile` and resets counter caches — first run is slow, expected
- HTTP:
  - WebMock allows real connections by default; VCR cassettes in `spec/http-mocks` (no unknown requests inside a cassette)
  - Wrap any external API call (IIIF, ContentDM, Gemini/Claude, Transkribus) in `VCR.use_cassette` or stub it
- Elasticsearch: run specs with `ELASTIC_ENABLED=false` unless testing search; `Chewy.strategy(:urgent)` is set per example
- Test images live in `test_data/images/pages/` — use with `Rack::Test::UploadedFile`
- `with_model` is available for testing concerns against throwaway tables
- Editor helpers in `spec_helper`: `fill_in_editor_field(text)` (handles CodeMirror), `select2_select(id:, value:)`,
  `wait_for_upload_processing`
- `spec/i18n_spec.rb` fails on missing/unused locale keys — adding or removing view text means updating `config/locales/*`
- Never commit Pry breakpoints — CI greps every file outside `.github/` for them (see CLAUDE.md)
