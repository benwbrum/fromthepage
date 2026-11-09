---
paths:
  - "app/jobs/**"
  - "spec/jobs/**"
  - "config/queue.yml"
  - "config/recurring.yml"
---

# Background jobs (SolidQueue)

- Adapter: SolidQueue in dev/prod (same MariaDB DB — tables are in `db/schema.rb`); test env does not use it
- User-triggered jobs subclass `ApplicationJob`:
  - First argument MUST be a keyword Hash containing `user_id:` — a `before_perform` raises `ArgumentError` otherwise
  - It sets `Current.user`, so models/interactors inside the job see the acting user
  - Pass IDs, never AR objects: `perform_later(user_id: current_user.id, collection_id: @collection.id)`
- Scheduled/system jobs subclass `RecurringBaseJob` (no `user_id` requirement) and are registered in
  `config/recurring.yml` (production only); system jobs that need a user conventionally pass `user_id: 1`
- Retries: default `retry_on StandardError` with `Settings.active_job.attempts`
  - Jobs calling paid/external APIs (AI) override with `retry_on StandardError, attempts: 1` — keep that for new AI jobs
- Queues (`config/queue.yml`): `default`, `bulk_exports`, `ai_transcriptions`, `ai_work_metadata`,
  `active_storage_*`. Set `queue_as` explicitly; a new queue name must be added to a worker in `queue.yml`
  or it will never be processed
- Thin jobs: load records, check permissions, call an interactor, persist status/errors, re-raise on failure
  (pattern: `AiTranscription::GenerateJob`)
- Persist user-visible failures on the record (status `:error` + sanitized message) before re-raising
- Bulk work: a `Bulk*Job` that fans out one `perform_later` per item rather than looping heavy work in one job
- Layout: `app/jobs/<domain>/<name>_job.rb` → `Domain::NameJob`
- Specs: `include ActiveJob::TestHelper`; call `described_class.perform_now(user_id: ..., ...)`;
  assert fan-out with `expect(OtherJob).to receive(:perform_later).with(...)`
- Some legacy flows still run as rake tasks (`lib/tasks/*.rake`); prefer jobs for new background work
