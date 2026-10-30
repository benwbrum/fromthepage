# Subject headings in Metadata Description

## Architecture and deployment

Metadata fields remain `TranscriptionField` records (`field_type: metadata`,
`input_type: subject_headings`). Migration `20261030000000_add_subject_headings`
adds `subject_heading_inventories`, `subject_headings`, field instructions, and
the candidate snapshot on `ai_work_metadata`. Run `rails db:migrate` and restart
the web application and Solid Queue. `config/queue.yml` includes a dedicated
`subject_headings` worker with one thread/process, to keep authority requests
sequential. Existing field types and draft review use the original pipeline.

An inventory stores source rows (including duplicates), filename, validation
attempt/status, report CSV, completion time, and notification time. Its child
rows hold the unique selectable options. Reports are private database text,
with a 16 MB report limit, served through an owner-authorized controller;
there are no public report files
or temporary attachment URLs. Replacing an import atomically replaces these
rows and deletes its old report. This intentionally does not keep vocabulary
history. Item descriptions and AI drafts store independent heading/URI snapshots.

`SubjectHeadings::Import`, `Selection`, `Candidates`, `AuthorityLookup`, and
`Report` implement the focused operations. `SubjectHeadings::ValidateJob` uses
the existing ApplicationJob user context, retries and mailer infrastructure.
Each job is bound to an inventory ID and a validation attempt token. Claiming
queued work is atomic, and all final writes check the token. Replacing an
inventory cannot receive an older job's status/report. Normal job retries skip
already delivered notifications; failed email delivery can retry without
repeating the authority queries. As with SMTP generally, a process crash after
the server accepts mail but before the delivery stamp commits can still cause
a duplicate notification.

## CSV contract

Upload UTF-8 CSV (BOM supported), with `heading` and optional `uri` headers.
Other column **values** never influence the selected vocabulary. HTTP/HTTPS
URIs are supported; bare LCCNs and other identifiers are not interpreted.
The limit is 5 MB, 10,000 nonblank rows, and 1,000 characters per heading/URI.
Whitespace around values is removed. Exact duplicate headings, or headings
differing only in a single final period, share an option if their URIs are
identical. The first spelling wins. Case, singular/plural, subdivisions, and
different URIs remain distinct. Source rows retain all spellings for the report.

Reports have exactly these columns:

```csv
heading,uri,suggested_heading,suggested_uri,result,rationale
```

They use UTF-8 BOM, CRLF, standard CSV quoting, and apostrophe-prefix escaping
for spreadsheet formula text. An already apostrophe-prefixed formula receives
another apostrophe. When the six report headers are present, import reverses
one such escape in `heading`/`uri`; it never consumes suggestion, result, or
rationale values. This reversible serialization lets an unedited report preserve
the uploaded vocabulary, including headings beginning with `=`, `+`, `-`, or
`@`. Owners should edit only `heading` and `uri` to adopt a suggestion. Spreadsheet
programs can alter CSV cell types or apostrophes during save; review the import
counts and keep a copy of the source file.

Saved Metadata Description values for this type are arrays of objects:

```json
[{"heading":"Agriculture","uri":"http://id.loc.gov/authorities/subjects/sh85002415"}]
```

Other datatypes keep their current value formats. Selected options are encoded
as JSON in the form and resolved server-side against the current inventory or
the item's exact previous snapshots. Retired saved selections can be retained
or removed, but cannot be newly assigned to another item. Metadata displays and
CSV exports retain identifiers; subject values in the item metadata export are
JSON cells rather than a lossy semicolon list. Bulk item-metadata import still
uses the existing original-metadata workflow; it does not assign subject options.

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

## AI retrieval and review

The existing prompt builder supplies at most 40 candidates per field, selected
by deterministic lexical overlap weighted by inverse heading-token frequency.
It uses the item transcript, title, description and original metadata. This
simple retrieval mechanism handles thousands of headings without sending the
entire inventory to the model or introducing a vector service. It does not
infer synonyms, stem words, or translate terms: relevant headings can be missed.
Evaluate retrieval recall separately from the model's choices using real
collection examples; tests explicitly cover inclusion, exclusion, empty results
and the candidate cap.

The draft record saves exactly the candidate ID-to-snapshot map that accompanied
its prompt. The response validator rejects IDs absent from that map and converts
accepted IDs to trusted snapshots. It accepts an empty assignment. Replacement
uploads do not change an in-flight prompt's candidate map; newly applying a
retired draft selection to an item is refused by the normal save validation.
Drafts never update saved item metadata until staff review and save them.
Guidance and document content are labeled untrusted task data and cannot relax
the application-enforced candidate constraint.

## Manual QA

1. As an owner, enable Metadata Description in a collection. In its metadata
   field editor, add **Subject Headings (LCSH)**, enter a label, save, then select
   **Configure Subject Headings**.
2. Download the template. Import a one-column file with about 3,000 headings,
   including duplicate rows, a final-period pair, singular/plural terms, and
   constructed headings. Enter AI instructions. Leave validation unchecked.
   Confirm row/option counts and the unchecked default.
3. Open an item's Describe screen. Search, select several headings, save, and
   reload. Verify identifiers using a second file containing `uri` values.
   Confirm the initial DOM contains only saved options and remote search pages
   results in groups of 30.
4. Replace the CSV and request validation. Immediately search/use the new
   inventory and confirm existing item selections still display their original
   text/URIs. Remove one saved heading and save.
5. Open AI settings at collection and item level while validation is queued or
   running. Confirm the warning is visible and generation remains enabled.
   Generate drafts and review them through the existing AI comparison controls.
   Saving metadata still requires the staff Save action.
6. Run the configured queue worker with network access to `id.loc.gov` and mail
   delivery configured. Check the completion email links to configuration,
   rather than a report URL. Download the report; confirm suggestions have not
   changed available options. Reupload it unchanged and verify the same options.
   Then edit `heading`/`uri`, reupload, and confirm those edits are adopted.
7. Simulate an LC timeout. Confirm failed status, error rows/partial report,
   failure email, continued metadata/AI availability, and successful retry.
   Replace an inventory while its check runs and confirm old results never
   appear on the replacement.
8. As an unrelated user, try configuration, upload, report and retry URLs.
   They must be denied. A permitted transcriber may search and select headings
   but cannot configure inventories. Repeat against a private collection.

Guidance document attachment/extraction is deliberately deferred: the existing
attachment facilities do not provide a general guidance-document text extractor.
Use the text area. Full authority reconciliation, automatic replacement,
terminology modernization and vocabulary history remain outside scope.

## Verification

The combined feature, existing AI metadata, metadata export and Chromium run
passed **170 examples, 0 failures**. It used a fresh MariaDB database loaded
from the updated checked-in schema. The Chromium scenarios exercised a
3,000-heading inventory, multiselect save/reload, retired selections with URIs,
single-model draft review, disagreement between models, and modal CSV upload.
The final importer-only run also covers null bytes and invalid upload parameters.
The final validation-job run also covers an enqueue failure, retaining usable
headings and exposing a retryable failed state.
All changed Ruby code passed RuboCop (39 files), Rails' eager-load check passed,
and `git diff --check` was clean. No external authority or LLM calls were made
by these tests.

The combined command was:

```sh
RAILS_ENV=test xvfb-run -a bundle exec rspec \
  spec/interactors/subject_headings spec/jobs/subject_headings \
  spec/requests/subject_headings_spec.rb \
  spec/requests/subject_heading_descriptions_spec.rb \
  spec/interactors/ai_work_metadata spec/jobs/ai_work_metadata \
  spec/requests/work_describe_ai_spec.rb spec/requests/work_ai_metadata_spec.rb \
  spec/requests/work/ai_work_metadata_controller_spec.rb \
  spec/requests/collection/ai_work_metadata_controller_spec.rb \
  spec/interactors/work/metadata/export_csv_spec.rb \
  spec/features/subject_headings_spec.rb
```

Four of six additional existing field-editor checks passed. Two transcription
editor checks failed in this environment: adding an unsaved field row
(`spec/features/field_based_spec.rb:113`) and reordering full lines
(`spec/features/field_based_spec.rb:190`, sortable not initialized). Both failures
reproduced with the original Git controller and field-row template loaded in
a separate test process. Those existing initialization failures were left
outside this enhancement. The full repository suite was not run.

The migration was applied successfully to local test and development databases.
Production deployment and a live LC request remain to be verified in the
deployment environment, where access to `id.loc.gov` and mail delivery must be
configured.
