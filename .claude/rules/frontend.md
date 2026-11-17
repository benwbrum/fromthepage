---
paths:
  - "app/javascript/**"
  - "app/views/**"
  - "app/assets/**"
  - "app/helpers/**"
  - "config/importmap.rb"
---

# Frontend (Importmap, Stimulus, Turbo, Slim)

- No JS bundler: Importmap only (`config/importmap.rb`). New dirs under `app/javascript` need a `pin_all_from`
- `Turbo.session.drive = false` — Turbo Drive is OFF globally
  - Full page loads are the default; don't rely on `turbo:load` navigation semantics
  - Turbo is used for Frames and Streams only (`*.turbo_stream.erb`, `respond_to { |f| f.turbo_stream }`)
- Stimulus controllers in `app/javascript/controllers/*_controller.js`, auto-registered; reusable non-controller
  code goes in `app/javascript/libs/<name>/`; custom Turbo Stream actions in `app/javascript/actions/`
- jQuery and jQuery plugins (select2, litebox, timeago, handsontable) are still in use — wrap them in a Stimulus
  controller (see `select2_controller.js`, `timeago_controller.js`) rather than inline `<script>`
- Use `@rails/request.js` for fetch calls (sends CSRF token)
- Views: Slim is the default (~350 slim vs ~130 erb); write new templates in Slim
- View components are plain helpers in `app/helpers/components/` — reuse before adding markup
- All user-facing strings via `t('...')` with keys in `config/locales/<area>/`; i18n spec enforces no missing/unused keys
- Accessibility work is ongoing (footer, subject links) — keep labels, alt text, and keyboard access intact
- Sprockets/sassc handles CSS in `app/assets/stylesheets`
