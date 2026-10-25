# Cleaning up migrated page images

Deploy the updated `fromthepage:delete_migrated_page_images` task before using
these commands. Run it from the production application directory on the server
that has the legacy images mounted. It supports Capistrano's linked image
directories.

Arguments, in order:

| Argument | Meaning | Default |
| --- | --- | --- |
| `slug` | User slug, collection slug, or explicit `all` for all pages | Required |
| `start_from_id` | Inclusive page ID to start or resume from | `1` |
| `batch_size` | Maximum pages loaded per batch | `1000` |
| `dry_run` | `true` to preview; `false` to delete files | `true` |

**Changed behavior:** existing invocations with just a slug now preview only.
Pass `false` as the fourth argument to actually delete files. Unknown or
ambiguous slugs and invalid arguments abort before deletion.

Preview all pages:

```sh
RAILS_ENV=production bundle exec rake 'fromthepage:delete_migrated_page_images[all,1,1000,true]' > log/image-cleanup-preview.log 2>&1
```

Run the deletion in a tmux session:

```sh
tmux new -s image-cleanup
RAILS_ENV=production bundle exec rake 'fromthepage:delete_migrated_page_images[all,1,1000,false]' >> log/image-cleanup.log 2>&1
```

Detach with `Ctrl-b`, then `d`. The command keeps running in tmux. Reattach with
`tmux attach -t image-cleanup`, or monitor from another shell:

```sh
tail -f log/image-cleanup.log
```

The task checks each page with a nonempty `base_image`. It only removes existing
legacy originals and/or `_thumb` files when that page has an `image` attachment
and the blob's configured Active Storage service confirms the object exists.
Missing uploaded objects are logged and their local files are kept. Storage
errors stop the task without deleting the affected page's files. Attachment and
blob records, uploaded objects, and `base_image` values are left intact.

The scan uses increasing page IDs, bounded batches, preloaded attachments and
blobs, and disabled query caching. It avoids a full-table count and per-file
shell processes. Storage checks only run when local candidate files exist;
millions of such checks can still take a long time and incur service requests.
The reported bytes are logical file sizes, not guaranteed disk space reclaimed.

Before fetching every batch, the task verifies the database connection and
reconnects if it has expired while checking files/storage. A persistent database
or storage outage can still stop the process. Each completed batch logs
`next start_from_id=N`; after interruption, replace the second argument with the
last logged value of `N`, retaining `false` for deletion. An error also reports
the current batch's starting ID. Repeating a partially completed batch or
restarting from `1` is safe because missing files are skipped.

The same commands accept a user or collection slug in place of `all`. A full
scan must run on each server with a separate legacy filesystem, if applicable.
