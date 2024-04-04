# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2024_03_26_200815) do

  create_table "ahoy_activity_summaries", id: :integer, charset: "utf8", collation: "utf8_general_ci", force: :cascade do |t|
    t.datetime "date"
    t.integer "user_id"
    t.integer "collection_id"
    t.string "activity"
    t.integer "minutes"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["date", "collection_id", "user_id", "activity"], name: "ahoy_activity_day_user_collection", unique: true
  end

  create_table "ahoy_events", id: :integer, charset: "utf8", collation: "utf8_general_ci", force: :cascade do |t|
    t.integer "visit_id"
    t.integer "user_id"
    t.string "name"
    t.text "properties"
    t.datetime "time"
    t.index ["name", "time"], name: "index_ahoy_events_on_name_and_time"
    t.index ["user_id", "name"], name: "index_ahoy_events_on_user_id_and_name"
    t.index ["visit_id", "name"], name: "index_ahoy_events_on_visit_id_and_name"
  end

  create_table "ai_jobs", id: :integer, charset: "utf8", collation: "utf8_general_ci", force: :cascade do |t|
    t.string "job_type"
    t.string "engine"
    t.string "parameters"
    t.string "status"
    t.integer "work_id", null: false
    t.integer "collection_id", null: false
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["collection_id"], name: "index_ai_jobs_on_collection_id"
    t.index ["user_id"], name: "index_ai_jobs_on_user_id"
    t.index ["work_id"], name: "index_ai_jobs_on_work_id"
  end

  create_table "article_article_links", id: :integer, charset: "utf8", collation: "utf8_general_ci", force: :cascade do |t|
    t.integer "source_article_id"
    t.integer "target_article_id"
    t.string "display_text"
    t.datetime "created_on"
    t.index ["source_article_id"], name: "index_article_article_links_on_source_article_id"
    t.index ["target_article_id"], name: "index_article_article_links_on_target_article_id"
  end

  create_table "article_versions", id: :integer, charset: "utf8", collation: "utf8_general_ci", force: :cascade do |t|
    t.string "title"
    t.text "source_text", size: :medium
    t.text "xml_text", size: :medium
    t.integer "user_id"
    t.integer "article_id"
    t.integer "version", default: 0
    t.datetime "created_on"
    t.index ["article_id"], name: "index_article_versions_on_article_id"
    t.index ["user_id"], name: "index_article_versions_on_user_id"
  end

  create_table "articles", id: :integer, charset: "utf8", collation: "utf8_general_ci", force: :cascade do |t|
    t.string "title"
    t.text "source_text", size: :medium
    t.datetime "created_on"
    t.integer "lock_version", default: 0
    t.text "xml_text", size: :medium
    t.string "graph_image"
    t.integer "collection_id"
    t.decimal "latitude", precision: 7, scale: 5
    t.decimal "longitude", precision: 8, scale: 5
    t.string "uri"
    t.string "provenance"
    t.integer "created_by_id"
    t.integer "pages_count", default: 0
    t.index ["collection_id"], name: "index_articles_on_collection_id"
    t.index ["created_by_id"], name: "fk_rails_35e2f292e3"
  end

  create_table "articles_categories", id: false, charset: "utf8", collation: "utf8_general_ci", force: :cascade do |t|
    t.integer "article_id"
    t.integer "category_id"
    t.index ["article_id", "category_id"], name: "index_articles_categories_on_article_id_and_category_id"
  end

  create_table "bulk_exports", id: :integer, charset: "utf8", collation: "utf8_general_ci", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "collection_id"
    t.string "status"
    t.boolean "plaintext_verbatim_page"
    t.boolean "plaintext_verbatim_work"
    t.boolean "plaintext_emended_page"
    t.boolean "plaintext_emended_work"
    t.boolean "plaintext_searchable_page"
    t.boolean "plaintext_searchable_work"
    t.boolean "tei_work"
    t.boolean "html_page"
    t.boolean "html_work"
    t.boolean "subject_csv_collection"
    t.boolean "table_csv_collection"
    t.boolean "table_csv_work"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "work_metadata_csv", default: false
    t.integer "work_id"
    t.boolean "facing_edition_work"
    t.boolean "text_pdf_work"
    t.boolean "text_docx_work"
    t.boolean "static"
    t.integer "document_set_id"
    t.boolean "subject_details_csv_collection"
    t.boolean "text_only_pdf_work"
    t.string "organization", default: "by_work"
    t.boolean "use_uploaded_filename", default: false
    t.boolean "plaintext_verbatim_zero_index_page", default: false
    t.boolean "owner_mailing_list"
    t.boolean "owner_detailed_activity"
    t.boolean "collection_activity"
    t.boolean "collection_contributors"
    t.string "report_arguments"
    t.boolean "notes_csv"
    t.boolean "admin_searches"
    t.index ["collection_id"], name: "index_bulk_exports_on_collection_id"
    t.index ["document_set_id"], name: "index_bulk_exports_on_document_set_id"
    t.index ["user_id"], name: "index_bulk_exports_on_user_id"
    t.index ["work_id"], name: "index_bulk_exports_on_work_id"
  end

  create_table "categories", id: :integer, charset: "utf8", collation: "utf8_general_ci", force: :cascade do |t|
    t.string "title"
    t.integer "parent_id"
    t.integer "collection_id"
    t.datetime "created_on"
    t.boolean "gis_enabled", default: false, null: false
    t.index ["collection_id"], name: "index_categories_on_collection_id"
    t.index ["parent_id"], name: "index_categories_on_parent_id"
  end

  create_table "cdm_bulk_imports", id: :integer, charset: "utf8", collation: "utf8_general_ci", force: :cascade do |t|
    t.integer "user_id", null: false
    t.boolean "ocr_correction", default: false
    t.string "collection_param", null: false
    t.text "cdm_urls"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_cdm_bulk_imports_on_user_id"
  end

  create_table "clientperf_results", id: :integer, charset: "utf8", collation: "utf8_general_ci", force: :cascade do |t|
    t.integer "clientperf_uri_id"
    t.integer "milliseconds"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["clientperf_uri_id"], name: "index_clientperf_results_on_clientperf_uri_id"
  end

  create_table "clientperf_uris", id: :integer, charset: "utf8", collation: "utf8_general_ci", force: :cascade do |t|
    t.string "uri"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["uri"], name: "index_clientperf_uris_on_uri"
  end

  create_table "collection_blocks", charset: "utf8", collation: "utf8_general_ci", force: :cascade do |t|
    t.integer "collection_id", null: false
    t.integer "user_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["collection_id", "user_id"], name: "index_collection_blocks_on_collection_id_and_user_id", unique: true
    t.index ["user_id"], name: "fk_rails_c117458532"
  end

  create_table "collection_collaborators", id: false, charset: "utf8", collation: "utf8_general_ci", force: :cascade do |t|
    t.integer "user_id"
    t.integer "collection_id"
  end

  create_table "collection_owners", id: false, charset: "utf8", collation: "utf8_general_ci", force: :cascade do |t|
    t.integer "user_id"
    t.integer "collection_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "collection_reviewers", id: :integer, charset: "utf8", collation: "utf8_general_ci", force: :cascade do |t|
    t.integer "user_id"
    t.integer "collection_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["collection_id"], name: "index_collection_reviewers_on_collection_id"
    t.index ["user_id"], name: "index_collection_reviewers_on_user_id"
  end

  create_table "collections", id: :integer, charset: "utf8", collation: "utf8_general_ci", force: :cascade do |t|
    t.string "title"
    t.integer "owner_user_id"
    t.datetime "created_on"
    t.text "intro_block", size: :medium
    t.text "footer_block", size: :medium
    t.boolean "restricted", default: false
    t.string "picture"
    t.boolean "supports_document_sets", default: false
    t.boolean "subjects_disabled", default: true
    t.text "transcription_conventions"
    t.string "slug"
    t.boolean "hide_completed", default: true
    t.text "help"
    t.text "link_help"
    t.boolean "field_based", default: false
    t.boolean "voice_recognition", default: false
    t.string "language"
    t.string "text_language"
    t.string "license_key"
    t.integer "pct_completed"
    t.string "default_orientation"
    t.boolean "is_active", default: true
    t.integer "works_count", default: 0
    t.integer "next_untranscribed_page_id"
    t.boolean "api_access", default: false
    t.boolean "facets_enabled", default: false
    t.boolean "user_download", default: false
    t.string "review_type", default: "optional"
    t.string "data_entry_type", default: "text"
    t.text "description_instructions"
    t.boolean "enable_spellcheck", default: false
    t.string "messageboard_slug"
    t.bigint "thredded_messageboard_group_id"
    t.boolean "messageboards_enabled"
    t.datetime "most_recent_deed_created_at"
    t.boolean "alphabetize_works", default: true
    t.index ["owner_user_id"], name: "index_collections_on_owner_user_id"
    t.index ["restricted"], name: "index_collections_on_restricted"
    t.index ["slug"], name: "index_collections_on_slug", unique: true
    t.index ["thredded_messageboard_group_id"], name: "index_collections_on_thredded_messageboard_group_id"
  end

  create_table "collections_tags", id: false, charset: "utf8", collation: "utf8_general_ci", force: :cascade do |t|
    t.integer "collection_id"
    t.integer "tag_id"
  end

  create_table "comments", id: :integer, charset: "utf8", collation: "utf8_general_ci", force: :cascade do |t|
    t.integer "parent_id"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.integer "commentable_id", default: 0, null: false
    t.string "commentable_type", default: "", null: false
    t.integer "depth"
    t.string "title"
    t.text "body", size: :medium
    t.string "comment_type", limit: 10, default: "annotation"
    t.string "comment_status", limit: 10
  end

  create_table "deeds", id: :integer, charset: "utf8", collation: "utf8_general_ci", force: :cascade do |t|
    t.string "deed_type", limit: 10
    t.integer "page_id"
    t.integer "work_id"
    t.integer "collection_id"
    t.integer "article_id"
    t.integer "user_id"
    t.integer "note_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "visit_id"
    t.string "prerender", limit: 8191
    t.string "prerender_mailer", limit: 8191
    t.boolean "is_public", default: true
    t.index ["article_id"], name: "index_deeds_on_article_id"
    t.index ["collection_id", "created_at"], name: "index_deeds_on_collection_id_and_created_at"
    t.index ["collection_id", "deed_type", "created_at"], name: "index_deeds_on_collection_id_and_deed_type_and_created_at"
    t.index ["created_at", "collection_id"], name: "index_deeds_on_created_at_and_collection_id"
    t.index ["note_id"], name: "index_deeds_on_note_id"
    t.index ["page_id"], name: "index_deeds_on_page_id"
    t.index ["user_id", "created_at"], name: "index_deeds_on_user_id_and_created_at"
    t.index ["visit_id"], name: "index_deeds_on_visit_id"
    t.index ["work_id", "created_at"], name: "index_deeds_on_work_id_and_created_at"
    t.index ["work_id", "deed_type", "user_id", "created_at"], name: "index_deeds_on_work_id_and_deed_type_and_user_id_and_created_at"
  end

  create_table "document_set_collaborators", id: false, charset: "utf8", collation: "utf8_general_ci", force: :cascade do |t|
    t.integer "user_id"
    t.integer "document_set_id"
  end

  create_table "document_sets", id: :integer, charset: "utf8", collation: "utf8_general_ci", force: :cascade do |t|
    t.boolean "is_public"
    t.integer "owner_user_id"
    t.integer "collection_id"
    t.string "title"
    t.text "description"
    t.string "picture"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "slug"
    t.integer "pct_completed"
    t.string "default_orientation"
    t.integer "works_count", default: 0
    t.integer "next_untranscribed_page_id"
    t.index ["collection_id"], name: "index_document_sets_on_collection_id"
    t.index ["owner_user_id"], name: "index_document_sets_on_owner_user_id"
    t.index ["slug"], name: "index_document_sets_on_slug", unique: true
  end

  create_table "document_sets_works", id: false, charset: "utf8", collation: "utf8_general_ci", force: :cascade do |t|
    t.integer "document_set_id", null: false
    t.integer "work_id", null: false
    t.index ["work_id", "document_set_id"], name: "index_document_sets_works_on_work_id_and_document_set_id", unique: true
  end

  create_table "document_uploads", id: :integer, charset: "utf8", collation: "utf8_general_ci", force: :cascade do |t|
    t.integer "user_id"
    t.integer "collection_id"
    t.string "file"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "status", default: "new"
    t.boolean "preserve_titles", default: false
    t.boolean "ocr", default: false
    t.index ["collection_id"], name: "index_document_uploads_on_collection_id"
    t.index ["user_id"], name: "index_document_uploads_on_user_id"
  end

  create_table "editor_buttons", id: :integer, charset: "utf8", collation: "utf8_general_ci", force: :cascade do |t|
    t.string "key"
    t.integer "collection_id", null: false
    t.boolean "prefer_html"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["collection_id"], name: "index_editor_buttons_on_collection_id"
  end

  create_table "external_api_requests", id: :integer, charset: "utf8", collation: "utf8_general_ci", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "collection_id", null: false
    t.integer "work_id"
    t.integer "page_id"
    t.string "engine"
    t.string "status"
    t.text "params"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "ai_job_id"
    t.index ["ai_job_id"], name: "index_external_api_requests_on_ai_job_id"
    t.index ["collection_id"], name: "index_external_api_requests_on_collection_id"
    t.index ["page_id"], name: "index_external_api_requests_on_page_id"
    t.index ["user_id"], name: "index_external_api_requests_on_user_id"
    t.index ["work_id"], name: "index_external_api_requests_on_work_id"
  end

  create_table "facet_configs", id: :integer, charset: "utf8", collation: "utf8_general_ci", force: :cascade do |t|
    t.string "label"
    t.string "input_type"
    t.integer "order"
    t.integer "metadata_coverage_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["metadata_coverage_id"], name: "index_facet_configs_on_metadata_coverage_id"
  end

  create_table "flags", id: :integer, charset: "utf8", collation: "utf8_general_ci", force: :cascade do |t|
    t.integer "author_user_id"
    t.integer "page_version_id"
    t.integer "article_version_id"
    t.integer "note_id"
    t.string "provenance"
    t.string "status", default: "unconfirmed"
    t.text "snippet"
    t.text "comment"
    t.integer "reporter_user_id"
    t.integer "auditor_user_id"
    t.datetime "content_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["article_version_id"], name: "index_flags_on_article_version_id"
    t.index ["auditor_user_id"], name: "index_flags_on_auditor_user_id"
    t.index ["author_user_id"], name: "index_flags_on_author_user_id"
    t.index ["note_id"], name: "index_flags_on_note_id"
    t.index ["page_version_id"], name: "index_flags_on_page_version_id"
    t.index ["reporter_user_id"], name: "index_flags_on_reporter_user_id"
  end

  create_table "friendly_id_slugs", id: :integer, charset: "utf8", collation: "utf8_general_ci", force: :cascade do |t|
    t.string "slug", null: false
    t.integer "sluggable_id", null: false
    t.string "sluggable_type", limit: 50
    t.string "scope"
    t.datetime "created_at"
    t.index ["slug", "sluggable_type", "scope"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type_and_scope", unique: true
    t.index ["slug", "sluggable_type"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type"
    t.index ["sluggable_id"], name: "index_friendly_id_slugs_on_sluggable_id"
    t.index ["sluggable_type"], name: "index_friendly_id_slugs_on_sluggable_type"
  end

  create_table "ia_leaves", id: :integer, charset: "utf8", collation: "utf8_general_ci", force: :cascade do |t|
    t.integer "ia_work_id"
    t.integer "page_id"
    t.integer "page_w"
    t.integer "page_h"
    t.integer "leaf_number"
    t.string "page_number"
    t.string "page_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text "ocr_text"
    t.index ["page_id"], name: "index_ia_leaves_on_page_id"
  end

  create_table "ia_works", id: :integer, charset: "utf8", collation: "utf8_general_ci", force: :cascade do |t|
    t.string "detail_url"
    t.integer "user_id"
    t.integer "work_id"
    t.string "server"
    t.string "ia_path"
    t.string "book_id"
    t.string "title"
    t.string "creator"
    t.string "collection"
    t.string "description", limit: 1024
    t.string "subject"
    t.string "notes"
    t.string "contributor"
    t.string "sponsor"
    t.string "image_count"
    t.integer "title_leaf"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "image_format", default: "jp2"
    t.string "archive_format", default: "zip"
    t.string "scandata_file"
    t.string "djvu_file"
    t.string "zip_file"
    t.boolean "use_ocr", default: false
  end

  create_table "metadata_coverages", id: :integer, charset: "utf8", collation: "utf8_general_ci", force: :cascade do |t|
    t.string "key"
    t.integer "count", default: 0
    t.integer "collection_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "metadata_description_versions", id: :integer, charset: "utf8", collation: "utf8_general_ci", force: :cascade do |t|
    t.text "metadata_description"
    t.integer "user_id", null: false
    t.integer "work_id", null: false
    t.integer "version_number"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_metadata_description_versions_on_user_id"
    t.index ["work_id"], name: "index_metadata_description_versions_on_work_id"
  end

  create_table "notes", id: :integer, charset: "utf8", collation: "utf8_general_ci", force: :cascade do |t|
    t.string "title"
    t.text "body", size: :medium, collation: "utf8mb4_unicode_ci"
    t.integer "user_id"
    t.integer "collection_id"
    t.integer "work_id"
    t.integer "page_id"
    t.integer "parent_id"
    t.integer "depth"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["page_id"], name: "index_notes_on_page_id"
  end

  create_table "notifications", id: :integer, charset: "utf8", collation: "utf8_general_ci", force: :cascade do |t|
    t.boolean "add_as_owner", default: true
    t.boolean "add_as_collaborator", default: true
    t.boolean "note_added", default: true
    t.boolean "owner_stats", default: false
    t.boolean "user_activity", default: true
    t.integer "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "add_as_reviewer", default: true
  end

  create_table "oai_repositories", id: :integer, charset: "utf8", collation: "utf8_general_ci", force: :cascade do |t|
    t.string "url"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "oai_sets", id: :integer, charset: "utf8", collation: "utf8_general_ci", force: :cascade do |t|
    t.string "set_spec"
    t.string "repository_url"
    t.integer "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "omeka_collections", id: :integer, charset: "utf8", collation: "utf8_general_ci", force: :cascade do |t|
    t.integer "omeka_id"
    t.integer "collection_id"
    t.string "title"
    t.string "description"
    t.integer "omeka_site_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "omeka_files", id: :integer, charset: "utf8", collation: "utf8_general_ci", force: :cascade do |t|
    t.integer "omeka_id"
    t.integer "omeka_item_id"
    t.string "mime_type"
    t.string "fullsize_url"
    t.string "thumbnail_url"
    t.string "original_filename"
    t.integer "omeka_order"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "page_id"
    t.index ["omeka_id"], name: "index_omeka_files_on_omeka_id"
  end

  create_table "omeka_items", id: :integer, charset: "utf8", collation: "utf8_general_ci", force: :cascade do |t|
    t.string "title"
    t.string "subject"
    t.string "description"
    t.string "rights"
    t.string "creator"
    t.string "format"
    t.string "coverage"
    t.integer "omeka_site_id"
    t.integer "omeka_id"
    t.string "omeka_url"
    t.integer "omeka_collection_id"
    t.integer "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "work_id"
  end

  create_table "omeka_sites", id: :integer, charset: "utf8", collation: "utf8_general_ci", force: :cascade do |t|
    t.string "title"
    t.string "api_url"
    t.string "api_key"
    t.integer "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "page_article_links", id: :integer, charset: "utf8", collation: "utf8_general_ci", force: :cascade do |t|
    t.integer "page_id"
    t.integer "article_id"
    t.string "display_text"
    t.datetime "created_on"
    t.string "text_type", default: "transcription"
    t.index ["article_id"], name: "index_page_article_links_on_article_id"
    t.index ["page_id"], name: "index_page_article_links_on_page_id"
  end

  create_table "page_blocks", id: :integer, charset: "utf8", collation: "utf8_general_ci", force: :cascade do |t|
    t.string "controller"
    t.string "view"
    t.string "tag"
    t.string "description"
    t.text "html", size: :medium
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["controller", "view"], name: "index_page_blocks_on_controller_and_view"
  end

  create_table "page_versions", id: :integer, charset: "utf8", collation: "utf8_general_ci", force: :cascade do |t|
    t.string "title"
    t.text "transcription", size: :medium, collation: "utf8mb4_unicode_ci"
    t.text "xml_transcription", size: :medium, collation: "utf8mb4_unicode_ci"
    t.integer "user_id"
    t.integer "page_id"
    t.integer "work_version", default: 0
    t.integer "page_version", default: 0
    t.datetime "created_on"
    t.text "source_translation", collation: "utf8mb4_unicode_ci"
    t.text "xml_translation", collation: "utf8mb4_unicode_ci"
    t.string "status"
    t.index ["page_id"], name: "index_page_versions_on_page_id"
    t.index ["user_id"], name: "index_page_versions_on_user_id"
  end

  create_table "pages", id: :integer, charset: "utf8", collation: "utf8_general_ci", force: :cascade do |t|
    t.string "title"
    t.text "source_text", size: :medium, collation: "utf8mb4_unicode_ci"
    t.string "base_image"
    t.integer "base_width"
    t.integer "base_height"
    t.integer "shrink_factor"
    t.integer "work_id"
    t.datetime "created_on"
    t.integer "position"
    t.integer "lock_version", default: 0
    t.text "xml_text", size: :medium, collation: "utf8mb4_unicode_ci"
    t.integer "page_version_id"
    t.string "status"
    t.text "source_translation", size: :medium, collation: "utf8mb4_unicode_ci"
    t.text "xml_translation", size: :medium, collation: "utf8mb4_unicode_ci"
    t.text "search_text", collation: "utf8mb4_unicode_ci"
    t.string "translation_status"
    t.text "metadata"
    t.datetime "edit_started_at"
    t.integer "edit_started_by_user_id"
    t.integer "line_count"
    t.float "approval_delta"
    t.integer "last_editor_user_id"
    t.datetime "last_note_updated_at"
    t.datetime "updated_at"
    t.index ["edit_started_by_user_id"], name: "index_pages_on_edit_started_by_user_id"
    t.index ["search_text"], name: "pages_search_text_index", type: :fulltext
    t.index ["status", "work_id", "edit_started_at"], name: "index_pages_on_status_and_work_id_and_edit_started_at"
    t.index ["work_id"], name: "index_pages_on_work_id"
  end

  create_table "pages_sections", id: false, charset: "utf8", collation: "utf8_general_ci", force: :cascade do |t|
    t.integer "page_id", null: false
    t.integer "section_id", null: false
    t.index ["page_id", "section_id"], name: "index_pages_sections_on_page_id_and_section_id"
    t.index ["section_id", "page_id"], name: "index_pages_sections_on_section_id_and_page_id"
  end

  create_table "plugin_schema_info", id: false, charset: "utf8", collation: "utf8_general_ci", options: "ENGINE=MyISAM", force: :cascade do |t|
    t.string "plugin_name"
    t.integer "version"
  end

  create_table "quality_samplings", id: :integer, charset: "utf8", collation: "utf8_general_ci", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "collection_id", null: false
    t.text "sample_set", size: :medium
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["collection_id"], name: "index_quality_samplings_on_collection_id"
    t.index ["user_id"], name: "index_quality_samplings_on_user_id"
  end

  create_table "sc_canvases", id: :integer, charset: "utf8", collation: "utf8_general_ci", force: :cascade do |t|
    t.string "sc_id"
    t.integer "sc_manifest_id"
    t.integer "page_id"
    t.string "sc_canvas_id"
    t.string "sc_canvas_label"
    t.string "sc_service_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "height"
    t.integer "width"
    t.string "sc_resource_id"
    t.string "sc_service_context"
    t.text "annotations", size: :medium
    t.index ["page_id"], name: "index_sc_canvases_on_page_id"
    t.index ["sc_manifest_id"], name: "index_sc_canvases_on_sc_manifest_id"
  end

  create_table "sc_collections", id: :integer, charset: "utf8", collation: "utf8_general_ci", force: :cascade do |t|
    t.integer "collection_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "at_id"
    t.integer "parent_id"
    t.string "label"
    t.string "version", default: "2"
    t.index ["collection_id"], name: "index_sc_collections_on_collection_id"
  end

  create_table "sc_manifests", id: :integer, charset: "utf8", collation: "utf8_general_ci", force: :cascade do |t|
    t.integer "work_id"
    t.integer "sc_collection_id"
    t.string "sc_id"
    t.text "label"
    t.text "metadata"
    t.string "first_sequence_id"
    t.string "first_sequence_label"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "at_id"
    t.integer "collection_id"
    t.string "version", default: "2"
    t.index ["sc_collection_id"], name: "index_sc_manifests_on_sc_collection_id"
    t.index ["work_id"], name: "index_sc_manifests_on_work_id"
  end

  create_table "search_attempts", id: :integer, charset: "utf8", collation: "utf8_general_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "query"
    t.integer "hits", default: 0
    t.integer "clicks", default: 0
    t.integer "contributions", default: 0
    t.integer "visit_id"
    t.integer "user_id"
    t.boolean "owner", default: false
    t.string "slug"
    t.integer "collection_id"
    t.integer "work_id"
    t.string "search_type"
    t.bigint "document_set_id"
    t.index ["collection_id"], name: "index_search_attempts_on_collection_id"
    t.index ["document_set_id"], name: "index_search_attempts_on_document_set_id"
    t.index ["slug"], name: "index_search_attempts_on_slug", unique: true
    t.index ["user_id"], name: "index_search_attempts_on_user_id"
    t.index ["visit_id"], name: "index_search_attempts_on_visit_id"
    t.index ["work_id"], name: "index_search_attempts_on_work_id"
  end

  create_table "sections", id: :integer, charset: "utf8", collation: "utf8_general_ci", force: :cascade do |t|
    t.string "title"
    t.integer "depth"
    t.integer "position"
    t.integer "work_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["work_id"], name: "index_sections_on_work_id"
  end

  create_table "sessions", id: :integer, charset: "utf8", collation: "utf8_general_ci", force: :cascade do |t|
    t.string "session_id", default: "", null: false
    t.text "data", size: :medium
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["session_id"], name: "index_sessions_on_session_id"
    t.index ["updated_at"], name: "index_sessions_on_updated_at"
  end

  create_table "spreadsheet_columns", id: :integer, charset: "utf8", collation: "utf8_general_ci", force: :cascade do |t|
    t.integer "transcription_field_id", null: false
    t.integer "position"
    t.string "label"
    t.string "input_type"
    t.text "options"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["transcription_field_id"], name: "index_spreadsheet_columns_on_transcription_field_id"
  end

  create_table "table_cells", id: :integer, charset: "utf8", collation: "utf8_general_ci", force: :cascade do |t|
    t.integer "work_id"
    t.integer "page_id"
    t.integer "section_id"
    t.string "header"
    t.text "content"
    t.integer "row"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "transcription_field_id"
    t.index ["page_id"], name: "index_table_cells_on_page_id"
    t.index ["section_id"], name: "index_table_cells_on_section_id"
    t.index ["transcription_field_id"], name: "index_table_cells_on_transcription_field_id"
    t.index ["work_id"], name: "index_table_cells_on_work_id"
  end

  create_table "tags", id: :integer, charset: "utf8", collation: "utf8_general_ci", force: :cascade do |t|
    t.string "tag_type"
    t.boolean "canonical"
    t.string "ai_text"
    t.string "message_key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "tex_figures", id: :integer, charset: "utf8", collation: "utf8_general_ci", force: :cascade do |t|
    t.integer "page_id"
    t.integer "position"
    t.text "source"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["page_id"], name: "index_tex_figures_on_page_id"
  end

  create_table "thredded_categories", charset: "utf8", collation: "utf8_general_ci", force: :cascade do |t|
    t.bigint "messageboard_id", null: false
    t.text "name", null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "slug", null: false
    t.index ["messageboard_id", "slug"], name: "index_thredded_categories_on_messageboard_id_and_slug", unique: true, length: { slug: 191 }
    t.index ["messageboard_id"], name: "index_thredded_categories_on_messageboard_id"
    t.index ["name"], name: "thredded_categories_name_ci", length: 191
  end

  create_table "thredded_messageboard_groups", charset: "utf8", collation: "utf8_general_ci", force: :cascade do |t|
    t.string "name"
    t.integer "position", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "thredded_messageboard_notifications_for_followed_topics", charset: "utf8", collation: "utf8_general_ci", force: :cascade do |t|
    t.integer "user_id", null: false
    t.bigint "messageboard_id", null: false
    t.string "notifier_key", limit: 90, null: false
    t.boolean "enabled", default: true, null: false
    t.index ["user_id", "messageboard_id", "notifier_key"], name: "thredded_messageboard_notifications_for_followed_topics_unique", unique: true
  end

  create_table "thredded_messageboard_users", charset: "utf8", collation: "utf8_general_ci", force: :cascade do |t|
    t.bigint "thredded_user_detail_id", null: false
    t.bigint "thredded_messageboard_id", null: false
    t.datetime "last_seen_at", null: false
    t.index ["thredded_messageboard_id", "last_seen_at"], name: "index_thredded_messageboard_users_for_recently_active"
    t.index ["thredded_messageboard_id", "thredded_user_detail_id"], name: "index_thredded_messageboard_users_primary", unique: true
    t.index ["thredded_user_detail_id"], name: "fk_rails_06e42c62f5"
  end

  create_table "thredded_messageboards", charset: "utf8", collation: "utf8_general_ci", force: :cascade do |t|
    t.text "name", null: false
    t.text "slug"
    t.text "description"
    t.integer "topics_count", default: 0
    t.integer "posts_count", default: 0
    t.integer "position", null: false
    t.bigint "last_topic_id"
    t.bigint "messageboard_group_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "locked", default: false, null: false
    t.index ["messageboard_group_id"], name: "index_thredded_messageboards_on_messageboard_group_id"
    t.index ["slug"], name: "index_thredded_messageboards_on_slug", unique: true, length: 191
  end

  create_table "thredded_notifications_for_followed_topics", charset: "utf8", collation: "utf8_general_ci", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "notifier_key", limit: 90, null: false
    t.boolean "enabled", default: true, null: false
    t.index ["user_id", "notifier_key"], name: "thredded_notifications_for_followed_topics_unique", unique: true
  end

  create_table "thredded_notifications_for_private_topics", charset: "utf8", collation: "utf8_general_ci", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "notifier_key", limit: 90, null: false
    t.boolean "enabled", default: true, null: false
    t.index ["user_id", "notifier_key"], name: "thredded_notifications_for_private_topics_unique", unique: true
  end

  create_table "thredded_post_moderation_records", charset: "utf8", collation: "utf8_general_ci", force: :cascade do |t|
    t.bigint "post_id"
    t.bigint "messageboard_id"
    t.text "post_content"
    t.integer "post_user_id"
    t.text "post_user_name"
    t.integer "moderator_id"
    t.integer "moderation_state", null: false
    t.integer "previous_moderation_state", null: false
    t.timestamp "created_at", default: -> { "current_timestamp()" }, null: false
    t.index ["messageboard_id", "created_at"], name: "index_thredded_moderation_records_for_display"
  end

  create_table "thredded_posts", charset: "utf8", collation: "utf8_general_ci", force: :cascade do |t|
    t.integer "user_id"
    t.text "content"
    t.string "source", limit: 191, default: "web"
    t.bigint "postable_id", null: false
    t.bigint "messageboard_id", null: false
    t.integer "moderation_state", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["content"], name: "thredded_posts_content_fts", type: :fulltext
    t.index ["messageboard_id"], name: "index_thredded_posts_on_messageboard_id"
    t.index ["moderation_state", "updated_at"], name: "index_thredded_posts_for_display"
    t.index ["postable_id", "created_at"], name: "index_thredded_posts_on_postable_id_and_created_at"
    t.index ["postable_id"], name: "index_thredded_posts_on_postable_id"
    t.index ["user_id"], name: "index_thredded_posts_on_user_id"
  end

  create_table "thredded_private_posts", charset: "utf8", collation: "utf8_general_ci", force: :cascade do |t|
    t.integer "user_id"
    t.text "content"
    t.bigint "postable_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["postable_id", "created_at"], name: "index_thredded_private_posts_on_postable_id_and_created_at"
  end

  create_table "thredded_private_topics", charset: "utf8", collation: "utf8_general_ci", force: :cascade do |t|
    t.integer "user_id"
    t.integer "last_user_id"
    t.text "title", null: false
    t.text "slug", null: false
    t.integer "posts_count", default: 0
    t.string "hash_id", limit: 20, null: false
    t.datetime "last_post_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["hash_id"], name: "index_thredded_private_topics_on_hash_id"
    t.index ["last_post_at"], name: "index_thredded_private_topics_on_last_post_at"
    t.index ["slug"], name: "index_thredded_private_topics_on_slug", unique: true, length: 191
  end

  create_table "thredded_private_users", charset: "utf8", collation: "utf8_general_ci", force: :cascade do |t|
    t.bigint "private_topic_id"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["private_topic_id"], name: "index_thredded_private_users_on_private_topic_id"
    t.index ["user_id"], name: "index_thredded_private_users_on_user_id"
  end

  create_table "thredded_topic_categories", charset: "utf8", collation: "utf8_general_ci", force: :cascade do |t|
    t.bigint "topic_id", null: false
    t.bigint "category_id", null: false
    t.index ["category_id"], name: "index_thredded_topic_categories_on_category_id"
    t.index ["topic_id"], name: "index_thredded_topic_categories_on_topic_id"
  end

  create_table "thredded_topics", charset: "utf8", collation: "utf8_general_ci", force: :cascade do |t|
    t.integer "user_id"
    t.integer "last_user_id"
    t.text "title", null: false
    t.text "slug", null: false
    t.bigint "messageboard_id", null: false
    t.integer "posts_count", default: 0, null: false
    t.boolean "sticky", default: false, null: false
    t.boolean "locked", default: false, null: false
    t.string "hash_id", limit: 20, null: false
    t.integer "moderation_state", null: false
    t.datetime "last_post_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["hash_id"], name: "index_thredded_topics_on_hash_id"
    t.index ["last_post_at"], name: "index_thredded_topics_on_last_post_at"
    t.index ["messageboard_id"], name: "index_thredded_topics_on_messageboard_id"
    t.index ["moderation_state", "sticky", "updated_at"], name: "index_thredded_topics_for_display"
    t.index ["slug"], name: "index_thredded_topics_on_slug", unique: true, length: 191
    t.index ["title"], name: "thredded_topics_title_fts", type: :fulltext
    t.index ["user_id"], name: "index_thredded_topics_on_user_id"
  end

  create_table "thredded_user_details", charset: "utf8", collation: "utf8_general_ci", force: :cascade do |t|
    t.integer "user_id", null: false
    t.datetime "latest_activity_at"
    t.integer "posts_count", default: 0
    t.integer "topics_count", default: 0
    t.datetime "last_seen_at"
    t.integer "moderation_state", default: 0, null: false
    t.timestamp "moderation_state_changed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["latest_activity_at"], name: "index_thredded_user_details_on_latest_activity_at"
    t.index ["moderation_state", "moderation_state_changed_at"], name: "index_thredded_user_details_for_moderations"
    t.index ["user_id"], name: "index_thredded_user_details_on_user_id", unique: true
  end

  create_table "thredded_user_messageboard_preferences", charset: "utf8", collation: "utf8_general_ci", force: :cascade do |t|
    t.integer "user_id", null: false
    t.bigint "messageboard_id", null: false
    t.boolean "follow_topics_on_mention", default: true, null: false
    t.boolean "auto_follow_topics", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "messageboard_id"], name: "thredded_user_messageboard_preferences_user_id_messageboard_id", unique: true
  end

  create_table "thredded_user_post_notifications", charset: "utf8", collation: "utf8_general_ci", force: :cascade do |t|
    t.integer "user_id", null: false
    t.bigint "post_id", null: false
    t.datetime "notified_at", null: false
    t.index ["post_id"], name: "index_thredded_user_post_notifications_on_post_id"
    t.index ["user_id", "post_id"], name: "index_thredded_user_post_notifications_on_user_id_and_post_id", unique: true
  end

  create_table "thredded_user_preferences", charset: "utf8", collation: "utf8_general_ci", force: :cascade do |t|
    t.integer "user_id", null: false
    t.boolean "follow_topics_on_mention", default: true, null: false
    t.boolean "auto_follow_topics", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_thredded_user_preferences_on_user_id", unique: true
  end

  create_table "thredded_user_private_topic_read_states", charset: "utf8", collation: "utf8_general_ci", force: :cascade do |t|
    t.integer "user_id", null: false
    t.bigint "postable_id", null: false
    t.integer "unread_posts_count", default: 0, null: false
    t.integer "read_posts_count", default: 0, null: false
    t.integer "integer", default: 0, null: false
    t.timestamp "read_at", default: -> { "current_timestamp()" }, null: false
    t.index ["user_id", "postable_id"], name: "thredded_user_private_topic_read_states_user_postable", unique: true
  end

  create_table "thredded_user_topic_follows", charset: "utf8", collation: "utf8_general_ci", force: :cascade do |t|
    t.integer "user_id", null: false
    t.bigint "topic_id", null: false
    t.datetime "created_at", null: false
    t.integer "reason", limit: 1
    t.index ["user_id", "topic_id"], name: "thredded_user_topic_follows_user_topic", unique: true
  end

  create_table "thredded_user_topic_read_states", charset: "utf8", collation: "utf8_general_ci", force: :cascade do |t|
    t.bigint "messageboard_id", null: false
    t.integer "user_id", null: false
    t.bigint "postable_id", null: false
    t.integer "unread_posts_count", default: 0, null: false
    t.integer "read_posts_count", default: 0, null: false
    t.integer "integer", default: 0, null: false
    t.timestamp "read_at", default: -> { "current_timestamp()" }, null: false
    t.index ["messageboard_id"], name: "index_thredded_user_topic_read_states_on_messageboard_id"
    t.index ["user_id", "messageboard_id"], name: "thredded_user_topic_read_states_user_messageboard"
    t.index ["user_id", "postable_id"], name: "thredded_user_topic_read_states_user_postable", unique: true
  end

  create_table "transcribe_authorizations", id: false, charset: "utf8", collation: "utf8_general_ci", force: :cascade do |t|
    t.integer "user_id"
    t.integer "work_id"
  end

  create_table "transcription_fields", id: :integer, charset: "utf8", collation: "utf8_general_ci", force: :cascade do |t|
    t.string "label"
    t.integer "collection_id"
    t.string "input_type"
    t.text "options"
    t.integer "line_number"
    t.integer "position"
    t.integer "percentage"
    t.integer "page_number"
    t.integer "starting_rows"
    t.float "top_offset", default: 0.0
    t.float "bottom_offset", default: 1.0
    t.boolean "row_highlight", default: false
    t.string "field_type", default: "transcription"
  end

  create_table "users", id: :integer, charset: "utf8", collation: "utf8_general_ci", force: :cascade do |t|
    t.string "login"
    t.string "display_name"
    t.string "real_name"
    t.string "email"
    t.boolean "owner", default: false
    t.boolean "admin", default: false
    t.string "encrypted_password", default: "", null: false
    t.string "password_salt", default: "", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "remember_token"
    t.datetime "remember_token_expires_at"
    t.string "location"
    t.string "website"
    t.text "about"
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.string "account_type"
    t.datetime "paid_date"
    t.boolean "guest"
    t.string "slug"
    t.boolean "deleted", default: false
    t.string "provider"
    t.string "uid"
    t.datetime "start_date"
    t.string "orcid"
    t.string "dictation_language", default: "en-US"
    t.boolean "activity_email"
    t.string "external_id"
    t.string "sso_issuer"
    t.string "preferred_locale"
    t.string "api_key"
    t.string "picture"
    t.text "help"
    t.text "footer_block", size: :medium
    t.index ["deleted"], name: "index_users_on_deleted"
    t.index ["login"], name: "index_users_on_login"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["slug"], name: "index_users_on_slug", unique: true
  end

  create_table "visits", id: :integer, charset: "utf8", collation: "utf8_general_ci", force: :cascade do |t|
    t.string "visit_token"
    t.string "visitor_token"
    t.string "ip"
    t.text "user_agent"
    t.text "referrer"
    t.text "landing_page"
    t.integer "user_id"
    t.string "referring_domain"
    t.string "search_keyword"
    t.string "browser"
    t.string "os"
    t.string "device_type"
    t.integer "screen_height"
    t.integer "screen_width"
    t.string "country"
    t.string "region"
    t.string "city"
    t.string "postal_code"
    t.decimal "latitude", precision: 10
    t.decimal "longitude", precision: 10
    t.string "utm_source"
    t.string "utm_medium"
    t.string "utm_term"
    t.string "utm_content"
    t.string "utm_campaign"
    t.datetime "started_at"
    t.index ["user_id"], name: "index_visits_on_user_id"
    t.index ["visit_token"], name: "index_visits_on_visit_token", unique: true
  end

  create_table "work_facets", id: :integer, charset: "utf8", collation: "utf8_general_ci", force: :cascade do |t|
    t.string "s0", limit: 512
    t.string "s1", limit: 512
    t.string "s2", limit: 512
    t.string "s3", limit: 512
    t.string "s4", limit: 512
    t.string "s5", limit: 512
    t.string "s6", limit: 512
    t.string "s7", limit: 512
    t.string "s8", limit: 512
    t.string "s9", limit: 512
    t.date "d0"
    t.date "d1"
    t.date "d2"
    t.integer "work_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["work_id"], name: "index_work_facets_on_work_id"
  end

  create_table "work_statistics", id: :integer, charset: "utf8", collation: "utf8_general_ci", force: :cascade do |t|
    t.integer "work_id"
    t.integer "transcribed_pages"
    t.integer "annotated_pages"
    t.integer "total_pages"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "blank_pages", default: 0
    t.integer "incomplete_pages", default: 0
    t.integer "corrected_pages"
    t.integer "needs_review"
    t.integer "translated_pages"
    t.integer "translated_blank"
    t.integer "translated_review"
    t.integer "translated_annotated"
    t.integer "complete"
    t.integer "translation_complete"
    t.integer "line_count"
    t.integer "transcribed_percentage"
    t.integer "needs_review_percentage"
    t.datetime "last_edit_at"
    t.index ["work_id", "line_count"], name: "index_work_statistics_on_work_id_and_line_count"
  end

  create_table "works", id: :integer, charset: "utf8", collation: "utf8_general_ci", force: :cascade do |t|
    t.string "title"
    t.text "description", size: :medium
    t.datetime "created_on"
    t.integer "owner_user_id"
    t.boolean "restrict_scribes", default: false
    t.integer "transcription_version", default: 0
    t.text "physical_description", size: :medium
    t.text "document_history", size: :medium
    t.text "permission_description", size: :medium
    t.string "location_of_composition"
    t.string "author"
    t.text "transcription_conventions", size: :medium
    t.integer "collection_id"
    t.boolean "scribes_can_edit_titles", default: false
    t.boolean "supports_translation", default: false
    t.text "translation_instructions"
    t.boolean "pages_are_meaningful", default: true
    t.boolean "ocr_correction", default: false
    t.string "slug"
    t.string "picture"
    t.integer "featured_page"
    t.string "identifier"
    t.integer "next_untranscribed_page_id"
    t.text "original_metadata"
    t.string "genre"
    t.string "source_location"
    t.string "source_collection_name"
    t.string "source_box_folder"
    t.boolean "in_scope", default: true
    t.text "editorial_notes"
    t.string "document_date"
    t.string "uploaded_filename"
    t.text "metadata_description"
    t.integer "metadata_description_version_id"
    t.string "description_status", default: "undescribed"
    t.text "searchable_metadata"
    t.string "recipient"
    t.datetime "most_recent_deed_created_at"
    t.index ["collection_id"], name: "index_works_on_collection_id"
    t.index ["metadata_description_version_id"], name: "index_works_on_metadata_description_version_id"
    t.index ["owner_user_id"], name: "index_works_on_owner_user_id"
    t.index ["slug"], name: "index_works_on_slug", unique: true
  end

  add_foreign_key "ai_jobs", "collections"
  add_foreign_key "ai_jobs", "users"
  add_foreign_key "ai_jobs", "works"
  add_foreign_key "bulk_exports", "collections"
  add_foreign_key "bulk_exports", "document_sets"
  add_foreign_key "bulk_exports", "users"
  add_foreign_key "bulk_exports", "works"
  add_foreign_key "cdm_bulk_imports", "users"
  add_foreign_key "collection_blocks", "collections"
  add_foreign_key "collection_blocks", "users"
  add_foreign_key "collections", "thredded_messageboard_groups"
  add_foreign_key "editor_buttons", "collections"
  add_foreign_key "external_api_requests", "ai_jobs"
  add_foreign_key "external_api_requests", "collections"
  add_foreign_key "external_api_requests", "users"
  add_foreign_key "external_api_requests", "works"
  add_foreign_key "facet_configs", "metadata_coverages"
  add_foreign_key "metadata_description_versions", "users"
  add_foreign_key "metadata_description_versions", "works"
  add_foreign_key "quality_samplings", "collections"
  add_foreign_key "quality_samplings", "users"
  add_foreign_key "spreadsheet_columns", "transcription_fields"
  add_foreign_key "thredded_messageboard_users", "thredded_messageboards", on_delete: :cascade
  add_foreign_key "thredded_messageboard_users", "thredded_user_details", on_delete: :cascade
  add_foreign_key "thredded_user_post_notifications", "thredded_posts", column: "post_id", on_delete: :cascade
  add_foreign_key "thredded_user_post_notifications", "users", on_delete: :cascade
  add_foreign_key "work_facets", "works"
  add_foreign_key "works", "metadata_description_versions"
end
