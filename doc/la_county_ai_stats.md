# LA County AI Assist statistics

Generate a refreshed analysis for **all of 2025** and **February 1, 2026
through the report cutoff**, separately, comparing weekly output, growth, and
recorded AI draft use. January 2026 is treated as the rollout period and is
excluded from the period comparison.

The earlier report uses Wednesday weekly buckets beginning January 1, 2025.
This script keeps that timeline and its six principal columns, with an
explicitly labeled availability proxy and additional audit columns. The
original extraction query is unavailable, so exact parity is unverified.

## Run

From a FromThePage checkout connected to the database containing LA County's
history:

```sh
# Inspect the scope first. Default owner slug is lacountylibrary.
RAILS_ENV=production bundle exec rails runner script/la_county_ai_stats.rb --list-collections

# Include November 19, 2026; omit --through to use the report-zone current date.
RAILS_ENV=production bundle exec rails runner script/la_county_ai_stats.rb \
  --through 2026-11-19 --out tmp/la_county_stats_2026-11-19
```

The default scope includes every collection owned by `lacountylibrary` and
prints the resolved IDs and titles. Review that list against the intended
project. To restrict the scope, use `--collection-ids` with the actual numeric
IDs, separated by commas. Do not use fixture IDs as production IDs. A missing
owner or collection fails explicitly. `--owner` selects a different owner slug.

`--timezone America/Chicago` is the default, matching the reference spreadsheet.
Use `--timezone America/Los_Angeles` if local project dates are preferred;
counts near midnight may then differ from the reference. `--through` is an
inclusive date, and all queries use an exclusive next-midnight cutoff. Today
is incomplete if the script runs before midnight; choose yesterday for stable
full-day comparisons. An existing output directory is never overwritten.

## Files produced

- `weekly.csv`: continuous Wednesday buckets from January 1, 2025, including
  zero-activity weeks and January 2026. The last bucket may contain fewer than
  seven days. Its first six columns follow the reference's order.
- `summary.csv`: exactly the two requested periods, calculated directly from
  event timestamps. It includes counts, AI share, cumulative baselines, and
  pages per week, normalized by calendar days / 7.
- `comparison.csv`: absolute and percentage changes in overall, recorded-AI,
  and without-recorded-AI weekly output. Zero baselines give blank percentages.
- `methodology.json`: exact scope, cutoff, time zone, definitions, generation
  time, and limitations to keep with the CSVs.

Use `summary.csv` for period comparisons: a Wednesday week can straddle New
Year or February 1. Summing whole weekly rows would put some days in the wrong
period. Percentages are numeric **percentage points**, e.g. `33.3333`, with
blank values for zero denominators; they are not fractional spreadsheet values.

## Definitions and limits

**Pages transcribed** are distinct page IDs dated by their first `page_trans`
deed in the selected collections. Repeated deeds do not inflate counts; ordinary
edits, blank-page markings, translations, and review events are excluded. This
is first transcription activity, which can be an incomplete save, rather than
QC completion. Cumulative counts include history before 2025 and January 2026.

**AI drafts used** counts only those newly transcribed pages with an `ai_draft`
deed or `page_versions.ai_draft_used` flag at or before that first transcription.
This makes the numerator a subset of the denominator. The separate import-event
and distinct-imported-page columns show draft imports during later edits, too.
No recorded import does not prove a volunteer never consulted the AI tab.

**Draft availability** is a record-date proxy: distinct current pages with
nonempty draft text/JSON in a current `new` or `finished` AI record created
before a bucket's end. Text-bearing `new` records matter because the legacy
migration did not set status to `finished`. Queued records without content and
current failed/processing records are excluded. There is no immutable historical
completion timestamp: migration dates may be later than actual availability,
creation dates may precede generation, and later deletion/status changes may
remove evidence. `updated_at` is unsuitable because accuracy calculations also
change it. This column cannot establish exactly when users could view a draft.

The script performs only SELECT queries, in a transaction for its data reads,
and writes local report files. It does not create drafts, schedule jobs, change
database records, or send messages. Collection moves, deleted history,
timestamp precision, and current page membership can affect historical results.

The before/after rates describe project throughput, not causal effects of AI,
time spent per page, individual volunteer productivity, or QC speed/accuracy.
Those require additional data; other changes in the project can also affect
output.

## Verification

Run the standalone integration checks against an isolated **test** database
with the current application schema:

```sh
RAILS_ENV=test bundle exec rails runner script/la_county_ai_stats_test.rb
```

They insert synthetic rows inside transactions and roll them back, covering
period boundaries, repeat events, AI attribution, scope, cumulative history,
legacy drafts, zero weeks, partial weeks, daylight saving, file output, and
read-only report queries. The available development database was empty, so no
fresh customer figures were generated or validated here. To check historical
parity, run against the intended production scope with `--through 2026-05-19`
and compare Wednesday rows through May 13 with the earlier spreadsheet before
sharing refreshed results.
