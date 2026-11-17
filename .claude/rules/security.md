---
paths:
  - "app/controllers/**"
  - "app/interactors/**"
  - "app/jobs/**"
  - "config/routes.rb"
  - "config/initializers/**"
---

# Security & authorization

- No Pundit/CanCan — authorization is hand-rolled:
  - Global `authorize_collection` (uses `collection.show_to?`) runs before every action with `@collection`
  - Each controller defines a private `authorized?` + `before_action` for edit/owner actions
  - Permission predicates: `admin?`, `like_owner?(obj)`, `can_transcribe?(work)`, `collaborator?(collection)`
- New actions: confirm which `before_action :authorized?` `only:/except:` lists cover them
- Auto-loaded objects (`load_objects_from_params`) come from user-controlled IDs — always verify the user
  may act on them; IDOR via swapped `page_id`/`work_id` is the main risk
- Re-check permissions in jobs/interactors that can be enqueued from multiple places (pattern: `GenerateJob`)
- Admin-only surfaces: `AdminController` subclasses; MissionControl at `/solid_queue` inherits `AdminController`
- Masquerade (`devise_masquerade`) lets admins act as users — log actions against the real actor where relevant
- API endpoints use `set_api_user` + `like_owner?` checks — don't bypass for convenience
- Strong params everywhere; never `permit!`
- User text (transcriptions, notes, articles) is untrusted: render through existing processors/sanitizers,
  avoid `html_safe`/`raw` on user content
- Spam/abuse: `Rack::Attack`, `SuspiciousBehaviors`, spammy-email TLD lists in `config/settings.yml`
- AI integrations: sanitize provider errors before storing/showing (`AiTranscription::Lib::ErrorMessageSanitizer`);
  never log or persist API keys
- Secrets come from ENV (`.env`, never commit); `config/initializers/{rack_attack,omniauth,01fromthepage}.rb` are
  protected linked files — propose changes, don't edit
- New Relic access: read-only only, per `doc/new_relic_agent_access.md`; never attempt mutations
