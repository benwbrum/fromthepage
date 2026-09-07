# AI volunteer behavior report

Run the production analysis from the application root:

```sh
OUTPUT=/secure/path/ai_volunteer_behavior_report.md \
  bundle exec rails runner script/ai_volunteer_behavior_report.rb
```

The report compares the fixed six-month windows A (2024), B (2025), and C
(2026) described in the conference proposal. It writes retention, adoption,
collection switching, productivity, eligible collection, and survey-candidate
tables to one Markdown file. Definitions and denominators are written into the
report itself so exported results remain interpretable.

Productivity is reported for three collection cohorts: the full period-C-selected
AI collection cohort, a balanced panel active in A/B/C, and a larger panel active
in both B/C. The collection-switching comparisons use the same fixed AI-enabled
collection universe in both transitions. The report also explains why deed-based
retention and saved-page-version analyses have different user denominators.

The script prints timestamped `START`, `DONE`, and `ERROR` messages to standard
output for every database-loading and report-rendering step. It also prints
intermediate record counts, cohort sizes, adoption bands, and productivity
totals. Output is flushed immediately, so a long-running database query remains
identifiable while the script is running.

The default eligible-collection threshold is 100 AI transcription records in
period C. The default "heavy AI" survey threshold is 10 AI-assisted saves and
AI use on at least half of saved versions. Both can be overridden:

```sh
OUTPUT=/secure/path/report.md \
  AI_COLLECTION_MINIMUM=100 \
  HEAVY_AI_MINIMUM=10 \
  bundle exec rails runner script/ai_volunteer_behavior_report.rb
```

The generated file contains volunteer email addresses. Write it to a secure,
non-public location, restrict access, and do not commit it to the repository.
The default output is `tmp/ai_volunteer_behavior_report.md`, which is ignored
by Git.
