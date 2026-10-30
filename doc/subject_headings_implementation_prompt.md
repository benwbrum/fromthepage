# Implementation prompt: project owner subject heading configuration

Implement the project owner configuration phase of Subject Headings (LCSH)
metadata fields in FromThePage. The broader feature will eventually support
AI-created draft LCSH metadata, but a separate team owns subject assignment and
its integration with work metadata. Keep this phase limited to configuration,
inventory import/replacement, advisory authority checking, reports and notices.

## Inspect and follow existing patterns

Inspect the metadata field editor, `TranscriptionField`, project ownership
checks, existing CSV import patterns, Active Job/Solid Queue and mailers.
Summarize the relevant architecture before substantial changes. Reuse existing
frameworks and dependencies and keep other metadata datatypes compatible.

## Owner workflow

- Add **Subject Headings (LCSH)** to the metadata datatype selector and a
  **Configure Subject Headings** button for saved fields of that type.
- Provide an owner-authorized configuration modal and a downloadable example
  CSV with required `heading` and optional `uri` columns.
- Allow owners to upload an inventory and save subject-assignment instructions
  for the future drafting integration. Text guidance is sufficient for this
  phase; document attachment/extraction may remain deferred.
- Provide an unchecked **Check headings against Library of Congress
  authorities** checkbox. Import and store the inventory immediately; optional
  authority checking runs asynchronously.
- Show filename, imported row count, unique heading count, saved guidance,
  validation status/error, report download and a way to replace the CSV. Permit
  retry after a validation failure.

## Import and replacement

Use the existing CSV utility and CharlockHolmes encoding detection to accept
common CSV encodings, including legacy spreadsheet exports and Unicode BOMs.
Normalize text internally and keep encoding terminology out of the uploader
instructions. Support quoted commas, CRLF and blank rows. Require
`heading`; accept optional HTTP/HTTPS URIs in `uri`; ignore additional columns.
Reject malformed, empty or oversized inventories clearly. Preserve legacy and
local terms, punctuation and supplied identifiers apart from surrounding
whitespace cleanup. Never invent URIs or modernize terminology automatically.

Use deterministic, conservative deduplication: identical headings and a single
final-period difference may share an entry when their URIs agree. Keep
singular/plural forms, subdivisions and different URIs distinct. Preserve
source rows so counts and duplicate handling can be explained.

Store unique headings in a child table. Track source filename/rows and
validation/report state at inventory level. A replacement atomically replaces
the inventory while leaving existing work descriptions and AI records intact.
Bind validation jobs to a specific inventory/attempt so old jobs cannot write
status or reports onto a replacement.

## Advisory LC checking and report

Consult Library of Congress Linked Data Service documentation and primary
client evidence before implementing requests. If current documentation or a
live request is inaccessible, document the evidence used and the remaining
verification limitation. Use a small testable service with HTTP timeouts,
transient retries/backoff, caching and conservative request concurrency.

Distinguish service failure from no match. Search relevant subjects, names and
genre/form sources where practical. A constructed or local heading can remain
legitimate without a complete-string authority URI. Checking is advisory and
must never silently replace active headings or identifiers.

Generate a private downloadable CSV with exactly these columns:

```csv
heading,uri,suggested_heading,suggested_uri,result,rationale
```

Use classifications supported by lookup evidence and explain ambiguity. Protect
all report text against spreadsheet formula injection with reversible CSV
serialization. Add no decision/approval column. Only `heading` and `uri` control
the imported inventory. Reuploading an unedited report must preserve the
inventory; owners adopt suggestions by editing those two columns and reuploading.

Use existing mailer conventions to notify the project owner on completion or
failure. Link to the authorized configuration screen rather than a temporary
download URL. Avoid duplicate emails on normal job retries and preserve the
inventory when authority services or email delivery fail. Expire abandoned
validation claims safely, keep live deliveries exclusive, and leave revoked
requester attempts in a retryable failed state.

## Reserved handoff to the drafting team

Retain the nullable `ai_work_metadata.subject_heading_candidates` attribute
and JSON storage so the other team has a place to save its results. Do not
prescribe a candidate payload format. Configuration, replacement and validation
must not populate, consume or clear that attribute or create/change AI drafts.

Do not implement or change:

- Candidate retrieval, ranking, lexical/semantic search or LLM subject selection.
- AI subject-assignment prompts, response handling, generation jobs or creation
  logic. Add only the phase-boundary guard that omits this datatype from current
  AI prompts and discards unsolicited subject-field output until integration.
- Applying headings to work-level draft or saved metadata.
- Item-level searchable multiselects, heading search endpoints, selection
  persistence or text/URI snapshot handling for work descriptions.
- Subject-specific work rendering/exports, draft comparison/review controls or
  warnings on AI initiation screens.

Those features belong to the separate team. Saving owner instructions is
configuration only; this phase performs no LLM requests. Preserve existing
item-level Metadata Description and AI drafting behavior.

## Verification and deliverables

Follow repository test conventions and mock authority responses. Cover datatype
creation and configuration, owner/staff authorization, CSV parsing and limits,
approximately 3,000 headings, conservative deduplication, guidance persistence,
replacement, validation states/retries/failures, stale jobs, CSV round-trip
behavior, private reports and email delivery without normal retry duplicates.

Verify that replacement does not change existing work descriptions, draft
metadata or the separate team's candidate payloads. Test that reserved candidate
storage round-trips JSON and permits null. Exercise owner import/replacement
through the browser and run existing AI tests as regression checks.

Provide the code/migration summary, LC endpoints and references actually used,
matching and live-verification limitations, test results and owner-only manual
QA steps. Keep the final PR and documentation within this phase boundary.
