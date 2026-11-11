# Project owner subject heading configuration

## Scope and team boundary

This phase lets project owners configure a Subject Headings metadata
field, optionally validate a CSV for duplicates and against LC authority records,
review the validation report, upload and replace the CSV inventory, save
subject-assignment guidance, and receive email notifications.
The [implementation prompt](subject_headings_implementation_prompt.md) defines
this owner configuration scope.

The metadata field preview and manual work metadata form use the existing
searchable Select2 multi-select, populated from the uploaded unique headings.
Owners see a localized unique-heading count beside Configure Subject Headings. Manual
selections use the existing metadata array storage; saved headings remain
visible and selected even after a replacement file removes them. Replacement
itself never rewrites item descriptions.

Candidate retrieval/ranking, LLM subject assignment and applying headings to
AI draft metadata remain owned by the separate drafting team. Until that
integration is ready, AI prompts omit subject-heading fields and response
validation discards unsolicited values for those fields. Existing exports and
AI generation/review behavior are unchanged.

The nullable `ai_work_metadata.subject_heading_candidates` attribute and its
JSON serialization remain available for that team's results. This phase neither
populates nor consumes it, prescribes its payload format, nor clears it when an
owner replaces an inventory. Field guidance is stored as configuration for the
separate integration; no LLM request is made by configuration or validation.

## Architecture and deployment

Metadata fields remain `TranscriptionField` records (`field_type: metadata`,
`input_type: subject_headings`). Migration `20261030000000_add_subject_headings`
adds `subject_heading_inventories`, `subject_headings`, field instructions, and
the reserved candidate attribute on `ai_work_metadata`. Migration
`20261111000000_create_subject_heading_validations` moves validation state off
the inventory into `subject_heading_validations`. Run `rails db:migrate`
and restart the web application and Solid Queue. `config/queue.yml` includes
a dedicated `subject_headings` worker with one thread/process to keep authority
requests sequential.

An inventory stores the saved file's source rows (including duplicates) and
filename; child rows hold unique headings and optional URIs. A separate
validation record (one per field) stores the validated file's name, row count,
unique rows, status, attempt token, progress (`processed_count`/`total_count`),
report CSV, error, completion time, and notification time. Validation never
creates or changes an inventory, and configuring a file never clears the last
validation. Reports are private database text with
a 16 MB limit, served through owner-authorized controller actions; no public
report files or temporary attachment URLs are used. Configuration, template,
import, report and retry endpoints all require owner-like or admin access.

Replacing an import atomically replaces its heading rows. It does not modify work descriptions, AI metadata, or candidate storage.
This intentionally does not keep vocabulary history.

`SubjectHeadings::Import`, `AuthorityLookup`, and `Report` handle inventory
configuration and advisory checks. `SubjectHeadings::ValidateJob` uses the
existing ApplicationJob user context, retries and mailer infrastructure. Jobs
are bound to a validation ID and attempt token. Claiming queued work
is atomic, and final writes check the token. Starting a new validation replaces
the old record, so older jobs cannot attach results to it. Normal retries skip already delivered notifications;
failed email delivery can retry without repeating authority queries. As with
SMTP generally, a process crash after server acceptance but before committing
the delivery stamp can still cause a duplicate notification.

Running claims expire after ten minutes without a heartbeat. Redelivery or an
owner retry can recover an expired attempt; each row refreshes the lease, and
final writes require the exact lease timestamp and attempt token. A requester
who has lost access leaves a retryable failed state without authority requests.

## Validate and configure

When the input type is Subject Headings, the field row's options cell shows two
buttons. The first reflects validation state:

* **Validate Subject Headings**: no validation yet (shown even with no saved file).
* **Validating… N%** with a small progress bar (disabled) while the job is queued
  or running. The row polls for updates every five seconds and switches to
  Review Validation when the job finishes; reloading the page shows the same state.
* **Review Validation** plus a badge counting possible matches and lookup errors.

The second is always **Configure Subject Headings**.

**Validate Subject Headings** uploads a CSV, merges duplicates, and starts a
background check. It never saves headings. **Review Subject Heading Validation**
shows exact matches, possible matches to review and lookup errors, downloads the
report and, when there are lookup errors, offers **Retry Lookup Errors**. A retry
rechecks only `lookup_error` and `not_checked` rows of the stored report, with
no reupload; other rows keep their results and order. A validation that failed
without a report offers **Try Validation Again**, which rechecks the whole file.
**Validate Another File** starts a new validation and replaces the old one.

**Configure Subject Headings** is the only step that saves headings: upload the
raw CSV or the edited validation report, and optionally the subject assignment
guidelines. Saving without a file only saves guidelines. The modals link to each
other (Configure ↔ Validate, Review → Configure / Validate) inside the same LiteBox.

## CSV contract

Upload CSV with `heading` and optional `uri` headers. As with metadata and
subject/article imports, the shared CSV utility uses CharlockHolmes to detect
text encoding. UTF-8 (with or without BOM), detected legacy encodings such as
Windows-1252, and UTF-16/32 CSVs are converted to UTF-8 internally. Native Excel
workbooks are not CSV files; export them as CSV before uploading.
Other column values never determine the active vocabulary. HTTP/HTTPS URIs are
supported; bare LCCNs and other identifiers are not interpreted. Limits are
5 MB for ordinary CSVs and active heading/URI text, 16 MB for report uploads,
10,000 nonblank rows, and 1,000 characters per heading/URI. Report informational
columns do not count toward the active vocabulary budget. Surrounding
whitespace is removed. Malformed CSV, empty inventories, unreadable text, null
bytes, and missing required columns are rejected without replacing a valid
existing inventory.

Exact duplicate headings, or headings differing only in one final period,
share an inventory entry when their URIs are identical. The first spelling wins.
Case, singular/plural, subdivisions and differing URIs remain distinct. Source
rows retain all spellings so report rows and import counts can be explained.

Reports contain exactly:

```csv
heading,uri,suggested_heading,suggested_uri,result,rationale,authority_type,subject_candidates,genre_form_candidates,name_candidates
```

They use UTF-8 BOM, CRLF, standard CSV quoting and apostrophe-prefix escaping for
spreadsheet formula text. An already apostrophe-prefixed formula receives
another apostrophe. When the six report headers are present, import reverses
one such escape in `heading`/`uri`; suggestion, result and rationale values are
ignored. An unedited report therefore preserves the uploaded vocabulary.
Owners adopt suggestions by editing `heading` and `uri` and uploading the report
in Configure Subject Headings. Spreadsheet applications can alter cell types or
apostrophes during save; review import counts and retain the source CSV.

## LC service evidence and limits

Documentation reference: [LC Linked Data Service technology center](https://id.loc.gov/techcenter/)
and [searching documentation](https://id.loc.gov/techcenter/searching.html).
The documentation site returned HTTP 403 from this implementation environment,
so its current text and a live request could not be verified. The request and
response contract was instead corroborated against LC's own published client:
[bfelookups.js](https://github.com/lcnetdev/bfe/blob/master/src/bfelookups.js) and
[lcshared_suggest2.js](https://github.com/lcnetdev/bfe/blob/master/src/lookups/lcshared_suggest2.js).
This limitation should be resolved with a live smoke check before production
rollout; automated tests use representative mocked responses.

The service makes HTTPS GET requests to:

* `https://id.loc.gov/authorities/subjects/suggest2/`
* `https://id.loc.gov/authorities/names/suggest2/`
* `https://id.loc.gov/authorities/genreForms/suggest2/`

Matching first verifies supplied LC authority URIs through their expanded
MADS/RDF JSON-LD records. Other HTTP/HTTPS identifiers remain local data and
are never fetched. Without an identifier match, Suggest2 left-anchored searches
run across subjects, names and genre/forms (`q`, `count=20`,
`searchtype=leftanchored`). Exact authorized labels take precedence over
conservative spacing/terminal-period normalization and explicit MADS `hasVariant`
/ `variantLabel` evidence. Formatting retries search the normalized string;
original uploaded columns remain intact. Broader keyword searches run last.
`suggestLabel` is a discovery hint, never sufficient variant evidence.

Potential exact/formatting candidates are checked against their authority records.
If those do not match, remaining left-anchored candidates are checked for explicit
variants before keyword fallback.
Suggestion hits missing an `aLabel` are resolved from the record rather than
rejected solely for the missing label. Invalid record URIs or malformed responses
remain lookup errors. Authority requests use only whitelisted LC authority paths,
never redirects or arbitrary uploaded URLs. Record and lookup caches use a new
version to avoid reusing the old keyword-only evidence.

The report adds `authority_type` (Subject, Name, Genre/form) based on verified
records. Multiple verified equivalent records produce `multiple_authority_matches`,
with alternatives grouped into `subject_candidates`, `genre_form_candidates` and `name_candidates` and a blank `suggested_uri`; unrelated keyword candidates
produce `possible_match` without replacement suggestions. A constructed heading
with no standalone match remains `no_match_found`, with a specific explanation.
No absence of a match implies an invalid heading. Uploaded identifiers are
preserved as data and never fetched. No authentication credential is assumed or
added. No advertised service rate limit is assumed: the application throttles
uncached requests to at most four per second, sequentially. It uses 5-second
connect/write and 10-second read timeouts, up to three attempts with exponential
backoff on timeouts, HTTP 429 and server failures, and seven-day Rails caching
of successful lookups. Configure a persistent Rails cache in production for
cross-job reuse. Errors are never cached as no-match results. Backoff starts at
30 seconds for HTTP 429/503 and 2 seconds for other transient failures, doubling
on the second retry. A valid `Retry-After` (seconds or HTTP date) takes precedence
when longer; there is no early retry or truncation of the server delay. Long
waits renew the validation claim every 30 seconds and stop if the file/attempt
has been replaced. These waits occupy the dedicated worker; this change does
not introduce resumable jobs or a new batch endpoint.

Logs use the plain searchable keyword `LC_AUTHORITY` for request URLs/attempts, response status, content type
and Retry-After at info level; retry delays at warn and exhausted failures at
error. Debug logs include at most 4 KB of the response body. Request URLs include
uploaded heading text, so these are application logs, not public report links.
No credentials or arbitrary response headers are logged.

After three consecutive failed headings a job stops issuing further requests.
Requests that failed remain `lookup_error` with the HTTP status or exception;
remaining unattempted headings are `not_checked` with an explicit “No request
made” rationale. The configuration error summarizes failed and skipped counts.
Successful headings reset the consecutive-failure counter.

Validation is advisory. It searches subjects, names (including personal,
corporate, and geographic names), and genre/forms, but checks only a bounded set
of search candidates. It does not resolve arbitrary subdivisions or claim absence
from LC. A complex heading without a complete-string match is not invalid.
Exact and variant classifications require matching returned labels; other
candidates are possibilities. Multiple candidates are reported as ambiguous,
without choosing a replacement. Original identifiers are not independently
authenticated or matched to the label. The report's suggested URI comes only
from LC's response. A completed job means the requests completed, not that all
headings were verified or approved. Partial failure produces a downloadable
partial report and notification. Owners can retry lookup errors from Review Validation.


## Manual QA

1. As an owner, open the collection's metadata field editor, create a field of
   type **Subject Headings** and save. The options cell shows **Validate Subject
   Headings** and **Configure Subject Headings**.
2. Click Validate Subject Headings. Start Validation stays disabled until a file
   is chosen. Upload a CSV with about 3,000 legacy headings, including duplicates,
   final-period variants and distinct subdivisions. The modal closes, an info
   flash names your email, and the row shows **Validating… N%**. No headings are
   saved to the field.
3. Run the queue worker with access to `id.loc.gov` and mail configured. The row
   switches to **Review Validation** with a badge, and an email arrives.
   Review shows exact/possible/error counts; download the report.
4. Simulate a timeout so some lookups fail. Review shows Lookup Errors; Retry
   Lookup Errors should recheck only those rows.
5. Use the Review modal's Configure Subject Headings link. Upload the unedited
   report and verify headings/URIs are unchanged; then edit `heading`/`uri`,
   upload again and confirm only those edits become active. The summary shows
   rows, unique headings and merged duplicates. The last validation remains.
6. Start a validation, then Validate Another File during the check; confirm old
   results do not appear on the new validation.
7. As an unrelated owner or ordinary transcriber, try the configure, validate,
   review, buttons, template, report and retry URLs; access must be denied.
   Repeat against a private collection and check that other projects' field IDs
   cannot be used.
8. Confirm the editor shows the unique-heading count and a searchable multi-select
   preview. In a work metadata form, select several headings, save, and reload.
   Replace the file and confirm earlier selections remain visible and unchanged.

Guidance document attachment/extraction remains deferred; use the text area.
AI subject-assignment integration belongs to the other team. Full authority
reconciliation, automatic replacement, terminology
modernization and vocabulary history remain outside this feature.

## Validation job logs

Like the upload-specific DocumentUpload process log and collection-specific
CONTENTdm sync log, each subject-heading validation has a dedicated append-only
logfile: `log/subject_headings/validation_<ID>.log`. It remains under Rails `log`,
not the public directory. Locate it in the Rails console with
`SubjectHeadingValidation.find(ID).log_file`.

The Rails application log records a `LC_AUTHORITY job_log` entry linking each
execution to that path. The dedicated file includes UTC timestamps, severity,
validation ID, Active Job ID and validation token on every entry, so retries and
obsolete deliveries can be distinguished. It records execution/claim decisions,
row start/end and result (with row number and total), failures/skips, memo and
lookup cache hits, request/response and retry details, wait progress/remaining
seconds, lease heartbeats, report generation/storage, and notification lifecycle.
Unexpected errors include their message and backtrace. An `execution_ended`
entry indicates the delivery exited; check `final_state_write` to establish that
the validation was finalized. Forced process kills may prevent a final entry.

For example, `tail -f log/subject_headings/validation_123.log` follows a validation,
and `rg 'LC_AUTHORITY row_finished' log/subject_headings/validation_123.log` finds
completed rows. Filter by validation token for a single attempt. `processed_count`
on the validation drives the field row's progress; the report persists at the end.
The file logger inherits the Rails logging level; bounded response bodies require
DEBUG. Logs include heading text and identifiers, and are not exposed as public
links. Files append across retries and are not deleted when the validation is
replaced; normal application log retention should include this directory.

## Verification

Run the owner configuration, import/report, authority service, job, storage and
Chromium tests, plus existing AI tests to check backward compatibility:

```sh
RAILS_ENV=test xvfb-run -a bundle exec rspec \
  spec/interactors/subject_headings spec/jobs/subject_headings \
  spec/requests/subject_headings_spec.rb spec/requests/subject_heading_review_spec.rb \
  spec/features/subject_headings_spec.rb \
  spec/models/subject_heading_candidate_storage_spec.rb \
  spec/models/ai_work_metadata_spec.rb spec/interactors/ai_work_metadata \
  spec/jobs/ai_work_metadata spec/requests/work_describe_ai_spec.rb \
  spec/requests/work_ai_metadata_spec.rb \
  spec/requests/work/ai_work_metadata_controller_spec.rb \
  spec/requests/collection/ai_work_metadata_controller_spec.rb
```

The review regression suite passed **171 examples, 0 failures**, including the two owner
Chromium scenarios, JSON storage checks and existing AI regression tests, using
a fresh MariaDB database loaded from the checked-in schema. External LC
responses are mocked. A live LC request and production mail configuration still
need deployment smoke checks, as described above.


Matching verification uses mocked expanded MADS authority graphs, including
positive and negative variant relationships; fixture outcomes are not assertions
about the current live catalog. LC documentation and sample-record access returned
403/unavailable in this environment. The actual Alabama failure response was not
provided: missing suggestion labels are now tolerated when the record verifies,
but malformed authority data still correctly requires review. Left-anchored and
keyword discovery are bounded to 20 candidates per vocabulary; keyword-only variant relationships
not exposed by candidate hints, remote variant links absent from the returned graph,
and labels outside that window may remain unmatched. Authority verification adds
requests, mitigated by seven-day record caching and the existing retry/throttle.


## Validation outcomes and safe suggestions

A generated report is `completed`, or `completed_with_issues` if lookup errors
or unattempted headings are present. `failed` means no usable report could be
produced (or the job could not be queued). Review counts come from the report's
`result` column: `exact_match` rows are exact matches; `lookup_error` and
`not_checked` rows are lookup errors; every other result (formatting
suggestions, variants, multiple matches, possible matches, no match found) is a
possible match to review. These are report-row counts, not assurances of
cataloging appropriateness.

Current reports put at most one URI in `suggested_uri`. Multiple verified
matches leave both suggested columns blank and list alternatives in
`subject_candidates`, `genre_form_candidates` and `name_candidates`, one
"label — URI" per line. To adopt an identifier, copy one URI into `uri`, review
`heading`, save and upload in Configure Subject Headings. Never copy an entire
multi-candidate cell into `uri`. Reports always import only `heading` and `uri`.

An exact Name-authority label is marked `possible_match`, with its verified URI
preserved, asking the owner to confirm the intended person, organization or
place.
