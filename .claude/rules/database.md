---
paths:
  - "db/**"
  - "app/models/**"
---

# Database & models

- MariaDB 11.8 (prod + CI) via `mysql2`, `utf8mb4_unicode_ci`, `sql_mode: TRADITIONAL`, `strict: false`
  - MariaDB 11 images/installs drop the `mysql*` CLI aliases — use `mariadb`, `mariadb-admin`, `mariadb-dump`
  - Test MySQL-specific behaviour (index length limits on utf8mb4 strings, case-insensitive collation comparisons)
- Schema is `db/schema.rb` (Ruby, not structure.sql); migrations are `ActiveRecord::Migration[7.2]`
- `config/database.yml` is a protected linked file — never edit it
- Large tables (pages, page_versions, deeds, ahoy_*, page_article_links): add indexes for new query patterns;
  recent perf work added composite indexes — check `db/schema.rb` before adding duplicates
- Prefer reversible `change` migrations; data backfills go in a rake task or job, not in the migration
- Model annotations are maintained by annotate_rb (schema comment above class) — regenerate, don't hand-edit
- Counter caches exist (`works_count`, `document_set_works`); use `reset_counters` after bulk writes that skip callbacks
- Search: models call `update_index(...)` guarded by `ELASTIC_ENABLED`; bulk `update_all`/`delete_all` bypass
  indexing — reindex explicitly or use the Elasticsearch interactors/jobs
- Watch N+1s: listing pages use `includes` heavily; check new associations in loops
- Friendly IDs (slugs) on User, Collection, Work, DocumentSet — lookup with `.friendly.find`
- Models may read `Current.user` (set in controllers and jobs); don't assume it's present in rake tasks/console
- SolidQueue tables share this DB; don't drop/alter `solid_queue_*` tables manually
