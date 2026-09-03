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
