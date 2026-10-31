# Project owner subject heading configuration

## Scope and team boundary

This phase lets project owners configure a Subject Headings (LCSH) metadata
field, upload and replace a CSV inventory, save subject-assignment guidance,
request advisory LC checking, and review reports and email notifications.
The [implementation prompt](subject_headings_implementation_prompt.md) defines
this owner configuration scope.

The metadata field preview and manual work metadata form use the existing
searchable Select2 multi-select, populated from the uploaded unique headings.
Owners see a localized heading count beside Configure Subject Headings. Manual
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
the reserved candidate attribute on `ai_work_metadata`. Run `rails db:migrate`
and restart the web application and Solid Queue. `config/queue.yml` includes
a dedicated `subject_headings` worker with one thread/process to keep authority
requests sequential.

An inventory stores source rows (including duplicates), filename, validation
attempt/status, report CSV, completion time, and notification time. Child rows
hold unique headings and optional URIs. Reports are private database text with
a 16 MB limit, served through owner-authorized controller actions; no public
report files or temporary attachment URLs are used. Configuration, template,
import, report and retry endpoints all require owner-like or admin access.

Replacing an import atomically replaces its heading rows and deletes its old
report. It does not modify work descriptions, AI metadata, or candidate storage.
This intentionally does not keep vocabulary history.

`SubjectHeadings::Import`, `AuthorityLookup`, and `Report` handle inventory
configuration and advisory checks. `SubjectHeadings::ValidateJob` uses the
existing ApplicationJob user context, retries and mailer infrastructure. Jobs
are bound to an inventory ID and validation attempt token. Claiming queued work
is atomic, and final writes check the token. Older jobs cannot attach results
to a replacement inventory. Normal retries skip already delivered notifications;
failed email delivery can retry without repeating authority queries. As with
SMTP generally, a process crash after server acceptance but before committing
the delivery stamp can still cause a duplicate notification.

Running claims expire after ten minutes without a heartbeat. Redelivery or an
owner retry can recover an expired attempt; each row refreshes the lease, and
final writes require the exact lease timestamp and attempt token. A requester
who has lost access leaves a retryable failed state without authority requests.

## Starting an authority check

For a new upload or replacement file, select the authority-check checkbox and
click **Save Subject Headings**. The checkbox is shown only when uploading a
file; it does not start a check by itself.

For a saved file, use **Run authority check** without uploading it again. A
completed check offers **Run authority check again**; a failed or expired check
offers **Retry authority check**. Queued/running checks keep a disabled status
button visible. Choosing a replacement file switches to the upload checkbox,
so the two ways to request a check are never shown together.

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
heading,uri,suggested_heading,suggested_uri,result,rationale,authority_type
```

They use UTF-8 BOM, CRLF, standard CSV quoting and apostrophe-prefix escaping for
spreadsheet formula text. An already apostrophe-prefixed formula receives
another apostrophe. When the six report headers are present, import reverses
one such escape in `heading`/`uri`; suggestion, result and rationale values are
ignored. An unedited report therefore preserves the uploaded vocabulary.
Owners adopt suggestions by editing `heading` and `uri` and reuploading through
the same configuration form. Spreadsheet applications can alter cell types or
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
with semicolon-separated URIs in `suggested_uri`; unrelated keyword candidates
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

Rails logs `[LC authority]` request URLs/attempts, response status, content type
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
partial report and failure notification. Owners can retry from configuration.


## Manual QA

1. As an owner, open the collection's metadata field editor, create a field of
   type **Subject Headings (LCSH)**, save, and open **Configure Subject Headings**.
2. Download the template. Import a CSV with about 3,000 legacy headings,
   including duplicates, final-period variants and distinct subdivisions.
   Optionally include URI values and subject-assignment instructions. Leave
   the validation checkbox unchecked. Confirm filename, row/unique counts,
   saved guidance and `Not requested` status.
3. Replace the CSV and request LC checking. Confirm the replacement inventory
   is stored immediately and status becomes queued/running. Work descriptions,
   draft metadata and reserved candidate payloads must remain unchanged.
4. Run the queue worker with access to `id.loc.gov` and mail configured. Confirm
   the completion email links to configuration, where a protected report can
   be downloaded. No suggestions should have changed the inventory.
5. Reupload the report unchanged and verify headings/URIs remain the same. Then
   edit `heading`/`uri`, reupload and confirm only those edits become active.
6. Simulate a timeout and inspect failed status, partial report, failure email
   and retry. Replace the inventory during a check and confirm old results do
   not appear on the replacement. Retry a completed job and confirm there is
   no duplicate notification.
7. As an unrelated owner or ordinary transcriber, try configuration, upload,
   template, report and retry URLs; access must be denied. Repeat against a
   private collection and check that other projects' field IDs cannot be used.

8. Confirm the editor shows the unique-heading count and a searchable multi-select
   preview. In a work metadata form, select several headings, save, and reload.
   Replace the file and confirm earlier selections remain visible and unchanged.

Guidance document attachment/extraction remains deferred; use the text area.
AI subject-assignment integration belongs to the other team. Full authority
reconciliation, automatic replacement, terminology
modernization and vocabulary history remain outside this feature.

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
