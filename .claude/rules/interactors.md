---
paths:
  - "app/interactors/**"
  - "spec/interactors/**"
  - "app/controllers/**"
---

# Interactors

- Subclass `ApplicationInteractor`, NOT `include Interactor` — the gem is only used for `Interactor::Context`
- Contract:
  - Define keyword args in `initialize`, assign ivars, then call `super` last
  - Put the work in `perform` (not `call`); `call` wraps `perform` and returns `self`
  - Expose outputs via `attr_accessor` (e.g. `attr_accessor :page`) so callers use `result.page`
- Error handling is implicit:
  - `call` rescues any `StandardError` → `success? == false`, exception in `full_errors`
  - So fail by `raise` (or `create!`/`update!`); never return error booleans
  - Callers MUST check `result.success?` — a failed interactor never raises
  - In jobs, re-raise `result.full_errors` if you want SolidQueue retries
- Naming: `app/interactors/<Domain>/<Verb>.rb` → `Domain::Verb` (`Page::Rotate`, `Work::Metadata::ImportCsv`)
  - Bulk variants: `BulkCreate`, `BulkRetry`; generation split as `Create` (DB record) vs `Generate` (external call)
- Permission checks belong inside the interactor when it can be invoked from multiple entry points
  (see `AiTranscription::Create#check_user_permission`); don't rely solely on the controller
- Single entry points: some records MUST only be created via their interactor (documented in the class comment,
  e.g. `AiTranscription::Create`). Respect these; don't `Model.create` directly elsewhere
- Shared helpers: `app/interactors/<domain>/lib/*.rb` as modules (`AiTranscription::Lib::Common`)
- Document required params in a header comment block (`@params name: required`) like existing interactors
- Wrap multi-record writes in `ActiveRecord::Base.transaction` — the rescue in `call` does not roll back for you
- Specs: `described_class.new(...).call`, assert `result.success?` and output attributes; also cover the failure path
  and assert `result.full_errors.message`
