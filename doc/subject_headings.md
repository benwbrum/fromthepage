# Project owner subject heading configuration

## Scope and team boundary

This phase lets project owners configure a Subject Headings (LCSH) metadata
field, upload and replace a CSV inventory, save subject-assignment guidance,
request advisory LC checking, and review reports and email notifications.
The [implementation prompt](subject_headings_implementation_prompt.md) defines
this owner configuration scope.

Item-level metadata editing, subject selection, candidate retrieval/ranking,
LLM prompt construction and response handling, AI validation warnings, and
applying headings to work metadata are owned by the separate drafting team.
This PR adds no subject-specific behavior to those workflows. Existing work
metadata storage, rendering, exports, and AI drafting code are unchanged.

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

## CSV contract

Upload UTF-8 CSV (BOM supported), with `heading` and optional `uri` headers.
Other column values never determine the active vocabulary. HTTP/HTTPS URIs are
supported; bare LCCNs and other identifiers are not interpreted. Limits are
5 MB, 10,000 nonblank rows, and 1,000 characters per heading/URI. Surrounding
whitespace is removed. Malformed CSV, empty inventories, invalid UTF-8, null
bytes, and missing required columns are rejected without replacing a valid
existing inventory.

Exact duplicate headings, or headings differing only in one final period,
share an inventory entry when their URIs are identical. The first spelling wins.
Case, singular/plural, subdivisions and differing URIs remain distinct. Source
rows retain all spellings so report rows and import counts can be explained.

Reports contain exactly:

```csv
heading,uri,suggested_heading,suggested_uri,result,rationale
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

Parameters are `q` (URI-encoded full heading), `searchtype=keyword`, and `count=5`.
The parsed response is `{count: number, hits: [{aLabel, suggestLabel, uri}]}`.
Returned identifiers must belong to these LC authority paths. Uploaded URIs are
preserved as data and never fetched. No authentication credential is assumed or
added. No advertised service rate limit is assumed: the application throttles
uncached requests to at most four per second, sequentially. It uses 5-second
connect/write and 10-second read timeouts, up to three attempts with exponential
backoff on timeouts, HTTP 429 and server failures, and seven-day Rails caching
of successful lookups. Configure a persistent Rails cache in production for
cross-job reuse. Errors are never cached as no-match results. After three failed
rows a job stops issuing requests and marks remaining rows as lookup errors.

Validation is advisory. It searches subjects, names (including personal,
corporate, and geographic names), and genre/forms, but checks only a small set
of keyword results. It does not resolve arbitrary subdivisions or claim absence
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

Guidance document attachment/extraction remains deferred; use the text area.
Item-level subject selection and AI drafting integration belong to the other
team. Full authority reconciliation, automatic replacement, terminology
modernization and vocabulary history remain outside this feature.

## Verification

Run the owner configuration, import/report, authority service, job, storage and
Chromium tests, plus existing AI tests to check backward compatibility:

```sh
RAILS_ENV=test xvfb-run -a bundle exec rspec \
  spec/interactors/subject_headings spec/jobs/subject_headings \
  spec/requests/subject_headings_spec.rb spec/features/subject_headings_spec.rb \
  spec/models/subject_heading_candidate_storage_spec.rb \
  spec/models/ai_work_metadata_spec.rb spec/interactors/ai_work_metadata \
  spec/jobs/ai_work_metadata spec/requests/work_describe_ai_spec.rb \
  spec/requests/work_ai_metadata_spec.rb \
  spec/requests/work/ai_work_metadata_controller_spec.rb \
  spec/requests/collection/ai_work_metadata_controller_spec.rb
```

The revised scope passed **163 examples, 0 failures**, including the two owner
Chromium scenarios, JSON storage checks and existing AI regression tests, using
a fresh MariaDB database loaded from the checked-in schema. External LC
responses are mocked. A live LC request and production mail configuration still
need deployment smoke checks, as described above.
