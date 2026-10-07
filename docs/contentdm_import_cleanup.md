# CONTENTdm import version cleanup

The REST importer used `page.save!` until commit `492bf1558` (June 9,
2021). It now uses `update_columns`. Older metadata-only imports could create
an identical version 1 after the initial blank version 0. Transcription deeds
previously used version numbers to decide between transcription and edit.

Start with a small work and a dry run:

```sh
bundle exec rake fromthepage:cleanup_contentdm_imports WORK_ID=123 AUDIT_PATH=/secure/path/cdm-dry-run.jsonl
```

Review the audit, take a database backup, then apply to the same scope:

```sh
bundle exec rake fromthepage:cleanup_contentdm_imports WORK_ID=123 APPLY=true REPAIR_DEEDS=true AUDIT_PATH=/secure/path/cdm-apply.jsonl
```

`COLLECTION_ID` narrows scope; `START_PAGE_ID` resumes from a reported page ID.
`BATCH_SIZE` defaults to 100 and `PAUSE` to 0.1 seconds between batches.
The task is idempotent, takes one page lock/transaction at a time, and queries
deeds through the existing page ID index. Run a single instance during quiet
hours; a page with unusually large history may take longer. Dry runs also take
brief page locks. There is no global deeds scan or schema migration.

Only matching, blank versions 0 and 1, attributed to the work owner and created
within one minute of the page, qualify. OCR works, flagged duplicate versions,
early deeds, nonblank content, differing snapshots, irregular numbering, and
unexpected current-version pointers are skipped. Older records without usable
timestamps are skipped. This deliberately misses uncertain cases, including
slow imports and OCR imports; examine them separately instead of widening the
criteria without evidence.

The task deletes version 1, renumbers later page versions, and repairs the
current-version pointer when necessary. It preserves all current page content,
status, remaining version IDs, work-version numbers, and the work's monotonic
transcription counter. It does not call `PageVersion#expunge`, which can restore
old page content.

Deed repair is optional. Only a unique `page_edit` for the user of version 2,
within five seconds after that first nonblank transcription and before the next
version, is converted to `page_trans`. Existing transcription deeds or ambiguous
matches prevent conversion. The audit reports the original deed and whether it
will be repaired. Cached activity HTML is regenerated; activity timestamps and
most-recent-activity pointers are preserved. Later edits remain edits.
Choose `REPAIR_DEEDS=true` on the initial apply if desired: after deleting the
duplicate, rerunning this task cannot identify that page for later deed repair.

Leaderboard and collection/document-set deed counts query deeds directly and
reflect the correction automatically. Work completion statistics and parent
completion percentages depend on page statuses, which are unchanged; they do
not need recalculation. No search-index rebuild is needed for these changes.

Audit lines are written and flushed **before** mutations, with original version,
numbering, pointer, and deed attributes for recovery. A planned line is not proof
of a committed change: on failure, check the database before restoring anything.
Retain the audit securely (it contains user IDs and activity HTML), alongside the
database backup. There is no automatic rollback command.
