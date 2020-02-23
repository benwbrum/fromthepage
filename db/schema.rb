# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

<<<<<<< HEAD
ActiveRecord::Schema.define(version: 2020_01_08_141002) do

  create_table "ahoy_events", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "visit_id"
    t.integer "user_id"
    t.string "name"
    t.text "properties"
    t.timestamp "time"
    t.index ["name", "time"], name: "index_ahoy_events_on_name_and_time"
    t.index ["user_id", "name"], name: "index_ahoy_events_on_user_id_and_name"
    t.index ["visit_id", "name"], name: "index_ahoy_events_on_visit_id_and_name"
  end

  create_table "article_article_links", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "source_article_id"
    t.integer "target_article_id"
    t.string "display_text"
=======
ActiveRecord::Schema.define(version: 20200207034944) do

  create_table "ahoy_events", force: true do |t|
    t.integer  "visit_id"
    t.integer  "user_id"
    t.string   "name"
    t.text     "properties"
    t.datetime "time"
  end

  add_index "ahoy_events", ["name", "time"], name: "index_ahoy_events_on_name_and_time", using: :btree
  add_index "ahoy_events", ["user_id", "name"], name: "index_ahoy_events_on_user_id_and_name", using: :btree
  add_index "ahoy_events", ["visit_id", "name"], name: "index_ahoy_events_on_visit_id_and_name", using: :btree

  create_table "ar_internal_metadata", primary_key: "key", force: true do |t|
    t.string   "value"
    t.datetime "created_at", limit: 6, null: false
    t.datetime "updated_at", limit: 6, null: false
  end

  create_table "article_article_links", force: true do |t|
    t.integer  "source_article_id"
    t.integer  "target_article_id"
    t.string   "display_text"
>>>>>>> development
    t.datetime "created_on"
    t.index ["source_article_id"], name: "index_article_article_links_on_source_article_id"
    t.index ["target_article_id"], name: "index_article_article_links_on_target_article_id"
  end

<<<<<<< HEAD
  create_table "article_versions", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "title"
    t.text "source_text"
    t.text "xml_text"
    t.integer "user_id"
    t.integer "article_id"
    t.integer "version", default: 0
=======
  add_index "article_article_links", ["source_article_id"], name: "index_article_article_links_on_source_article_id", using: :btree
  add_index "article_article_links", ["target_article_id"], name: "index_article_article_links_on_target_article_id", using: :btree

  create_table "article_versions", force: true do |t|
    t.string   "title"
    t.text     "source_text", limit: 16777215
    t.text     "xml_text",    limit: 16777215
    t.integer  "user_id"
    t.integer  "article_id"
    t.integer  "version",                      default: 0
>>>>>>> development
    t.datetime "created_on"
    t.index ["article_id"], name: "index_article_versions_on_article_id"
    t.index ["user_id"], name: "index_article_versions_on_user_id"
  end

<<<<<<< HEAD
  create_table "articles", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "title"
    t.text "source_text"
    t.datetime "created_on"
    t.integer "lock_version", default: 0
    t.text "xml_text"
    t.string "graph_image"
    t.integer "collection_id"
    t.decimal "latitude", precision: 7, scale: 5
    t.decimal "longitude", precision: 8, scale: 5
    t.string "uri"
    t.index ["collection_id"], name: "index_articles_on_collection_id"
=======
  add_index "article_versions", ["article_id"], name: "index_article_versions_on_article_id", using: :btree
  add_index "article_versions", ["user_id"], name: "index_article_versions_on_user_id", using: :btree

  create_table "articles", force: true do |t|
    t.string   "title"
    t.text     "source_text",   limit: 16777215
    t.datetime "created_on"
    t.integer  "lock_version",                                           default: 0
    t.text     "xml_text",      limit: 16777215
    t.string   "graph_image"
    t.integer  "collection_id"
    t.decimal  "latitude",                       precision: 7, scale: 5
    t.decimal  "longitude",                      precision: 8, scale: 5
    t.string   "uri"
>>>>>>> development
  end

  create_table "articles_categories", id: false, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "article_id"
    t.integer "category_id"
  end

  create_table "categories", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "title"
    t.integer "parent_id"
    t.integer "collection_id"
    t.datetime "created_on"
    t.boolean "gis_enabled", default: false, null: false
    t.index ["collection_id"], name: "index_categories_on_collection_id"
    t.index ["parent_id"], name: "index_categories_on_parent_id"
  end

  create_table "clientperf_results", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "clientperf_uri_id"
    t.integer "milliseconds"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["clientperf_uri_id"], name: "index_clientperf_results_on_clientperf_uri_id"
  end

  create_table "clientperf_uris", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "uri"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["uri"], name: "index_clientperf_uris_on_uri"
  end

  create_table "collection_collaborators", id: false, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "user_id"
    t.integer "collection_id"
  end

  create_table "collection_owners", id: false, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "user_id"
    t.integer "collection_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "collections", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "title"
    t.integer "owner_user_id"
    t.datetime "created_on"
<<<<<<< HEAD
    t.text "intro_block"
    t.string "footer_block", limit: 2000
    t.boolean "restricted", default: false
    t.string "picture"
    t.boolean "supports_document_sets", default: false
    t.boolean "subjects_disabled", default: false
    t.text "transcription_conventions"
    t.string "slug"
    t.boolean "review_workflow", default: false
    t.boolean "hide_completed", default: true
    t.text "help"
    t.text "link_help"
    t.boolean "field_based", default: false
    t.boolean "voice_recognition", default: false
    t.string "language"
    t.string "license_key"
    t.string "text_language"
    t.integer "pct_completed"
    t.string "default_orientation"
    t.boolean "is_active", default: true
    t.integer "next_untranscribed_page_id"
    t.integer "works_count", default: 0
    t.index ["owner_user_id"], name: "index_collections_on_owner_user_id"
    t.index ["slug"], name: "index_collections_on_slug", unique: true
  end

  create_table "deeds", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "deed_type", limit: 10
    t.integer "page_id"
    t.integer "work_id"
    t.integer "collection_id"
    t.integer "article_id"
    t.integer "user_id"
    t.integer "note_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "visit_id"
    t.string "prerender", limit: 2047
    t.string "prerender_mailer", limit: 2047
    t.index ["article_id"], name: "index_deeds_on_article_id"
    t.index ["collection_id"], name: "index_deeds_on_collection_id"
    t.index ["created_at"], name: "index_deeds_on_created_at"
    t.index ["note_id"], name: "index_deeds_on_note_id"
    t.index ["page_id"], name: "index_deeds_on_page_id"
    t.index ["user_id"], name: "index_deeds_on_user_id"
    t.index ["work_id"], name: "index_deeds_on_work_id"
  end

  create_table "document_set_collaborators", id: false, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
=======
    t.text     "intro_block",                limit: 16777215
    t.text     "footer_block",               limit: 16777215
    t.boolean  "restricted",                                  default: false
    t.string   "picture"
    t.boolean  "supports_document_sets",                      default: false
    t.boolean  "subjects_disabled",                           default: false
    t.text     "transcription_conventions"
    t.string   "slug"
    t.boolean  "review_workflow",                             default: false
    t.boolean  "hide_completed",                              default: true
    t.text     "help"
    t.text     "link_help"
    t.boolean  "field_based",                                 default: false
    t.boolean  "voice_recognition",                           default: false
    t.string   "language"
    t.string   "text_language"
    t.string   "license_key"
    t.integer  "pct_completed"
    t.string   "default_orientation"
    t.boolean  "is_active",                                   default: true
    t.integer  "works_count",                                 default: 0
    t.integer  "next_untranscribed_page_id"
  end

  add_index "collections", ["owner_user_id"], name: "index_collections_on_owner_user_id", using: :btree
  add_index "collections", ["restricted"], name: "index_collections_on_restricted", using: :btree
  add_index "collections", ["slug"], name: "index_collections_on_slug", unique: true, using: :btree

  create_table "comments", force: true do |t|
    t.integer  "parent_id"
    t.integer  "user_id"
    t.datetime "created_at",                                               null: false
    t.integer  "commentable_id",                    default: 0,            null: false
    t.string   "commentable_type",                  default: "",           null: false
    t.integer  "depth"
    t.string   "title"
    t.text     "body",             limit: 16777215
    t.string   "comment_type",     limit: 10,       default: "annotation"
    t.string   "comment_status",   limit: 10
  end

  create_table "deeds", force: true do |t|
    t.string   "deed_type",        limit: 10
    t.integer  "page_id"
    t.integer  "work_id"
    t.integer  "collection_id"
    t.integer  "article_id"
    t.integer  "user_id"
    t.integer  "note_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "visit_id"
    t.string   "prerender",        limit: 2047
    t.string   "prerender_mailer", limit: 2047
  end

  add_index "deeds", ["article_id"], name: "index_deeds_on_article_id", using: :btree
  add_index "deeds", ["collection_id", "user_id", "created_at"], name: "index_deeds_on_collection_id_user_id_created_at", using: :btree
  add_index "deeds", ["collection_id", "user_id"], name: "index_deeds_on_collection_id_user_id", using: :btree
  add_index "deeds", ["collection_id"], name: "index_deeds_on_collection_id", using: :btree
  add_index "deeds", ["created_at"], name: "index_deeds_on_created_at", using: :btree
  add_index "deeds", ["note_id"], name: "index_deeds_on_note_id", using: :btree
  add_index "deeds", ["page_id"], name: "index_deeds_on_page_id", using: :btree
  add_index "deeds", ["user_id"], name: "index_deeds_on_user_id", using: :btree
  add_index "deeds", ["work_id"], name: "index_deeds_on_work_id", using: :btree

  create_table "document_set_collaborators", id: false, force: true do |t|
>>>>>>> development
    t.integer "user_id"
    t.integer "document_set_id"
  end

<<<<<<< HEAD
  create_table "document_sets", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.boolean "is_public"
    t.bigint "owner_user_id"
    t.bigint "collection_id"
    t.string "title"
    t.text "description"
    t.string "picture"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "slug"
    t.integer "pct_completed"
    t.string "default_orientation"
    t.integer "next_untranscribed_page_id"
    t.integer "works_count", default: 0
    t.index ["collection_id"], name: "index_document_sets_on_collection_id"
    t.index ["owner_user_id"], name: "index_document_sets_on_owner_user_id"
    t.index ["slug"], name: "index_document_sets_on_slug", unique: true
  end

  create_table "document_sets_works", id: false, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "document_set_id", null: false
    t.bigint "work_id", null: false
    t.index ["work_id", "document_set_id"], name: "index_document_sets_works_on_work_id_and_document_set_id", unique: true
  end

  create_table "document_uploads", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "collection_id"
    t.string "file"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "status", default: "new"
    t.boolean "preserve_titles", default: false
    t.boolean "ocr", default: false
    t.index ["collection_id"], name: "index_document_uploads_on_collection_id"
    t.index ["user_id"], name: "index_document_uploads_on_user_id"
  end

  create_table "flags", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "author_user_id"
    t.bigint "page_version_id"
    t.bigint "article_version_id"
    t.bigint "note_id"
    t.string "provenance"
    t.string "status", default: "unconfirmed"
    t.text "snippet"
    t.text "comment"
    t.bigint "reporter_user_id"
    t.bigint "auditor_user_id"
=======
  create_table "document_sets", force: true do |t|
    t.boolean  "is_public"
    t.integer  "owner_user_id"
    t.integer  "collection_id"
    t.string   "title"
    t.text     "description"
    t.string   "picture"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "slug"
    t.integer  "pct_completed"
    t.string   "default_orientation"
    t.integer  "works_count",                default: 0
    t.integer  "next_untranscribed_page_id"
  end

  add_index "document_sets", ["collection_id"], name: "index_document_sets_on_collection_id", using: :btree
  add_index "document_sets", ["owner_user_id"], name: "index_document_sets_on_owner_user_id", using: :btree
  add_index "document_sets", ["slug"], name: "index_document_sets_on_slug", unique: true, using: :btree

  create_table "document_sets_works", id: false, force: true do |t|
    t.integer "document_set_id", null: false
    t.integer "work_id",         null: false
  end

  add_index "document_sets_works", ["work_id", "document_set_id"], name: "index_document_sets_works_on_work_id_and_document_set_id", unique: true, using: :btree

  create_table "document_uploads", force: true do |t|
    t.integer  "user_id"
    t.integer  "collection_id"
    t.string   "file"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "status",          default: "new"
    t.boolean  "preserve_titles", default: false
    t.boolean  "ocr",             default: false
  end

  add_index "document_uploads", ["collection_id"], name: "index_document_uploads_on_collection_id", using: :btree
  add_index "document_uploads", ["user_id"], name: "index_document_uploads_on_user_id", using: :btree

  create_table "flags", force: true do |t|
    t.integer  "author_user_id"
    t.integer  "page_version_id"
    t.integer  "article_version_id"
    t.integer  "note_id"
    t.string   "provenance"
    t.string   "status",             default: "unconfirmed"
    t.text     "snippet"
    t.text     "comment"
    t.integer  "reporter_user_id"
    t.integer  "auditor_user_id"
>>>>>>> development
    t.datetime "content_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["article_version_id"], name: "index_flags_on_article_version_id"
    t.index ["auditor_user_id"], name: "index_flags_on_auditor_user_id"
    t.index ["author_user_id"], name: "index_flags_on_author_user_id"
    t.index ["note_id"], name: "index_flags_on_note_id"
    t.index ["page_version_id"], name: "index_flags_on_page_version_id"
    t.index ["reporter_user_id"], name: "index_flags_on_reporter_user_id"
    t.index ["status"], name: "index_flags_on_status"
  end

  create_table "friendly_id_slugs", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "slug", null: false
    t.integer "sluggable_id", null: false
    t.string "sluggable_type", limit: 50
    t.string "scope"
    t.datetime "created_at"
<<<<<<< HEAD
    t.index ["slug", "sluggable_type", "scope"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type_and_scope", unique: true
    t.index ["slug", "sluggable_type"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type"
    t.index ["sluggable_id"], name: "index_friendly_id_slugs_on_sluggable_id"
    t.index ["sluggable_type"], name: "index_friendly_id_slugs_on_sluggable_type"
  end

  create_table "ia_leaves", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "ia_work_id"
    t.integer "page_id"
    t.integer "page_w"
    t.integer "page_h"
    t.integer "leaf_number"
    t.string "page_number"
    t.string "page_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "ocr_text"
  end

  create_table "ia_works", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
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
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "image_format", default: "jp2"
    t.string "archive_format", default: "zip"
    t.string "scandata_file"
    t.string "djvu_file"
    t.string "zip_file"
    t.boolean "use_ocr", default: false
  end

  create_table "notes", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "title"
    t.text "body"
    t.integer "user_id"
    t.integer "collection_id"
    t.integer "work_id"
    t.integer "page_id"
    t.integer "parent_id"
    t.integer "depth"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["page_id"], name: "index_notes_on_page_id"
  end

  create_table "notifications", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.boolean "add_as_owner", default: true
    t.boolean "add_as_collaborator", default: true
    t.boolean "note_added", default: true
    t.boolean "owner_stats", default: false
    t.boolean "user_activity", default: true
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
=======
    t.datetime "updated_at"
  end

  add_index "flags", ["article_version_id"], name: "index_flags_on_article_version_id", using: :btree
  add_index "flags", ["auditor_user_id"], name: "index_flags_on_auditor_user_id", using: :btree
  add_index "flags", ["author_user_id"], name: "index_flags_on_author_user_id", using: :btree
  add_index "flags", ["note_id"], name: "index_flags_on_note_id", using: :btree
  add_index "flags", ["page_version_id"], name: "index_flags_on_page_version_id", using: :btree
  add_index "flags", ["reporter_user_id"], name: "index_flags_on_reporter_user_id", using: :btree

  create_table "friendly_id_slugs", force: true do |t|
    t.string   "slug",                      null: false
    t.integer  "sluggable_id",              null: false
    t.string   "sluggable_type", limit: 50
    t.string   "scope"
    t.datetime "created_at"
  end

  add_index "friendly_id_slugs", ["slug", "sluggable_type", "scope"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type_and_scope", unique: true, using: :btree
  add_index "friendly_id_slugs", ["slug", "sluggable_type"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type", using: :btree
  add_index "friendly_id_slugs", ["sluggable_id"], name: "index_friendly_id_slugs_on_sluggable_id", using: :btree
  add_index "friendly_id_slugs", ["sluggable_type"], name: "index_friendly_id_slugs_on_sluggable_type", using: :btree

  create_table "ia_leaves", force: true do |t|
    t.integer  "ia_work_id"
    t.integer  "page_id"
    t.integer  "page_w"
    t.integer  "page_h"
    t.integer  "leaf_number"
    t.string   "page_number"
    t.string   "page_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "ocr_text"
  end

  create_table "ia_works", force: true do |t|
    t.string   "detail_url"
    t.integer  "user_id"
    t.integer  "work_id"
    t.string   "server"
    t.string   "ia_path"
    t.string   "book_id"
    t.string   "title"
    t.string   "creator"
    t.string   "collection"
    t.string   "description",    limit: 1024
    t.string   "subject"
    t.string   "notes"
    t.string   "contributor"
    t.string   "sponsor"
    t.string   "image_count"
    t.integer  "title_leaf"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "image_format",                default: "jp2"
    t.string   "archive_format",              default: "zip"
    t.string   "scandata_file"
    t.string   "djvu_file"
    t.string   "zip_file"
    t.boolean  "use_ocr",                     default: false
  end

  create_table "notes", force: true do |t|
    t.string   "title"
    t.text     "body",          limit: 16777215
    t.integer  "user_id"
    t.integer  "collection_id"
    t.integer  "work_id"
    t.integer  "page_id"
    t.integer  "parent_id"
    t.integer  "depth"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "notes", ["page_id"], name: "index_notes_on_page_id", using: :btree

  create_table "notifications", force: true do |t|
    t.boolean  "add_as_owner",        default: true
    t.boolean  "add_as_collaborator", default: true
    t.boolean  "note_added",          default: true
    t.boolean  "owner_stats",         default: false
    t.boolean  "user_activity",       default: true
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "oai_repositories", force: true do |t|
    t.string   "url"
    t.datetime "created_at"
    t.datetime "updated_at"
>>>>>>> development
  end

  create_table "oai_repositories", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "oai_sets", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "set_spec"
    t.string "repository_url"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "omeka_collections", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "omeka_id"
    t.integer "collection_id"
    t.string "title"
    t.string "description"
    t.integer "omeka_site_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "omeka_files", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "omeka_id"
    t.integer "omeka_item_id"
    t.string "mime_type"
    t.string "fullsize_url"
    t.string "thumbnail_url"
    t.string "original_filename"
    t.integer "omeka_order"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "page_id"
    t.index ["omeka_id"], name: "index_omeka_files_on_omeka_id"
  end

  create_table "omeka_items", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
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
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "work_id"
  end

  create_table "omeka_sites", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "title"
    t.string "api_url"
    t.string "api_key"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "page_article_links", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "page_id"
    t.integer "article_id"
    t.string "display_text"
    t.datetime "created_on"
<<<<<<< HEAD
    t.string "text_type", default: "transcription"
    t.index ["article_id"], name: "index_page_article_links_on_article_id"
    t.index ["page_id"], name: "index_page_article_links_on_page_id"
  end

  create_table "page_blocks", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "controller"
    t.string "view"
    t.string "tag"
    t.string "description"
    t.text "html"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["controller", "view"], name: "index_page_blocks_on_controller_and_view"
  end

  create_table "page_versions", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "title"
    t.text "transcription"
    t.text "xml_transcription"
    t.integer "user_id"
    t.integer "page_id"
    t.integer "work_version", default: 0
    t.integer "page_version", default: 0
    t.datetime "created_on"
    t.text "source_translation"
    t.text "xml_translation"
    t.index ["page_id"], name: "index_page_versions_on_page_id"
    t.index ["user_id"], name: "index_page_versions_on_user_id"
  end

  create_table "pages", options: "ENGINE=MyISAM DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "title"
    t.text "source_text"
    t.string "base_image"
    t.integer "base_width"
    t.integer "base_height"
    t.integer "shrink_factor"
    t.integer "work_id"
    t.datetime "created_on"
    t.integer "position"
    t.integer "lock_version", default: 0
    t.text "xml_text"
    t.integer "page_version_id"
    t.string "status"
    t.text "source_translation"
    t.text "xml_translation"
    t.text "search_text"
    t.string "translation_status"
    t.text "metadata"
    t.timestamp "edit_started_at"
    t.bigint "edit_started_by_user_id"
    t.index ["edit_started_by_user_id"], name: "index_pages_on_edit_started_by_user_id"
    t.index ["search_text"], name: "pages_search_text_index", type: :fulltext
    t.index ["work_id"], name: "index_pages_on_work_id"
  end

  create_table "pages_sections", id: false, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "page_id", null: false
    t.bigint "section_id", null: false
    t.index ["page_id", "section_id"], name: "index_pages_sections_on_page_id_and_section_id"
    t.index ["section_id", "page_id"], name: "index_pages_sections_on_section_id_and_page_id"
  end

  create_table "sc_canvases", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "sc_id"
    t.bigint "sc_manifest_id"
    t.bigint "page_id"
    t.string "sc_canvas_id"
    t.string "sc_canvas_label"
    t.string "sc_service_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "height"
    t.integer "width"
    t.string "sc_resource_id"
    t.string "sc_service_context"
    t.index ["page_id"], name: "index_sc_canvases_on_page_id"
    t.index ["sc_manifest_id"], name: "index_sc_canvases_on_sc_manifest_id"
  end

  create_table "sc_collections", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "collection_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "at_id"
    t.integer "parent_id"
    t.string "label"
    t.index ["collection_id"], name: "index_sc_collections_on_collection_id"
  end

  create_table "sc_manifests", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "work_id"
    t.bigint "sc_collection_id"
    t.string "sc_id"
    t.text "label"
    t.text "metadata"
    t.string "first_sequence_id"
    t.string "first_sequence_label"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "at_id"
    t.integer "collection_id"
    t.index ["sc_collection_id"], name: "index_sc_manifests_on_sc_collection_id"
    t.index ["work_id"], name: "index_sc_manifests_on_work_id"
=======
    t.string   "text_type",    default: "transcription"
  end

  add_index "page_article_links", ["article_id"], name: "index_page_article_links_on_article_id", using: :btree
  add_index "page_article_links", ["page_id"], name: "index_page_article_links_on_page_id", using: :btree

  create_table "page_blocks", force: true do |t|
    t.string   "controller"
    t.string   "view"
    t.string   "tag"
    t.string   "description"
    t.text     "html",        limit: 16777215
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "page_blocks", ["controller", "view"], name: "index_page_blocks_on_controller_and_view", using: :btree

  create_table "page_versions", force: true do |t|
    t.string   "title"
    t.text     "transcription",      limit: 16777215
    t.text     "xml_transcription",  limit: 16777215
    t.integer  "user_id"
    t.integer  "page_id"
    t.integer  "work_version",                        default: 0
    t.integer  "page_version",                        default: 0
    t.datetime "created_on"
    t.text     "source_translation"
    t.text     "xml_translation"
  end

  add_index "page_versions", ["page_id"], name: "index_page_versions_on_page_id", using: :btree
  add_index "page_versions", ["user_id"], name: "index_page_versions_on_user_id", using: :btree

  create_table "pages", force: true do |t|
    t.string   "title"
    t.text     "source_text",             limit: 16777215
    t.string   "base_image"
    t.integer  "base_width"
    t.integer  "base_height"
    t.integer  "shrink_factor"
    t.integer  "work_id"
    t.datetime "created_on"
    t.integer  "position"
    t.integer  "lock_version",                             default: 0
    t.text     "xml_text",                limit: 16777215
    t.integer  "page_version_id"
    t.string   "status"
    t.text     "source_translation"
    t.text     "xml_translation"
    t.text     "search_text"
    t.string   "translation_status"
    t.text     "metadata"
    t.datetime "edit_started_at"
    t.integer  "edit_started_by_user_id"
  end

  add_index "pages", ["edit_started_by_user_id"], name: "index_pages_on_edit_started_by_user_id", using: :btree
  add_index "pages", ["search_text"], name: "pages_search_text_index", type: :fulltext
  add_index "pages", ["work_id"], name: "index_pages_on_work_id", using: :btree

  create_table "pages_sections", id: false, force: true do |t|
    t.integer "page_id",    null: false
    t.integer "section_id", null: false
  end

  add_index "pages_sections", ["page_id", "section_id"], name: "index_pages_sections_on_page_id_and_section_id", using: :btree
  add_index "pages_sections", ["section_id", "page_id"], name: "index_pages_sections_on_section_id_and_page_id", using: :btree

  create_table "plugin_schema_info", id: false, force: true do |t|
    t.string  "plugin_name"
    t.integer "version"
  end

  create_table "sc_canvases", force: true do |t|
    t.string   "sc_id"
    t.integer  "sc_manifest_id"
    t.integer  "page_id"
    t.string   "sc_canvas_id"
    t.string   "sc_canvas_label"
    t.string   "sc_service_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "height"
    t.integer  "width"
    t.string   "sc_resource_id"
    t.string   "sc_service_context"
  end

  add_index "sc_canvases", ["page_id"], name: "index_sc_canvases_on_page_id", using: :btree
  add_index "sc_canvases", ["sc_manifest_id"], name: "index_sc_canvases_on_sc_manifest_id", using: :btree

  create_table "sc_collections", force: true do |t|
    t.integer  "collection_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "at_id"
    t.integer  "parent_id"
    t.string   "label"
  end

  add_index "sc_collections", ["collection_id"], name: "index_sc_collections_on_collection_id", using: :btree

  create_table "sc_manifests", force: true do |t|
    t.integer  "work_id"
    t.integer  "sc_collection_id"
    t.string   "sc_id"
    t.text     "label"
    t.text     "metadata"
    t.string   "first_sequence_id"
    t.string   "first_sequence_label"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "at_id"
    t.integer  "collection_id"
  end

  add_index "sc_manifests", ["sc_collection_id"], name: "index_sc_manifests_on_sc_collection_id", using: :btree
  add_index "sc_manifests", ["work_id"], name: "index_sc_manifests_on_work_id", using: :btree

  create_table "sections", force: true do |t|
    t.string   "title"
    t.integer  "depth"
    t.integer  "position"
    t.integer  "work_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sections", ["work_id"], name: "index_sections_on_work_id", using: :btree

  create_table "sessions", force: true do |t|
    t.string   "session_id",                  default: "", null: false
    t.text     "data",       limit: 16777215
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], name: "index_sessions_on_session_id", using: :btree
  add_index "sessions", ["updated_at"], name: "index_sessions_on_updated_at", using: :btree

  create_table "table_cells", force: true do |t|
    t.integer  "work_id"
    t.integer  "page_id"
    t.integer  "section_id"
    t.string   "header"
    t.text     "content"
    t.integer  "row"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "transcription_field_id"
>>>>>>> development
  end

  create_table "sections", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "title"
    t.integer "depth"
    t.integer "position"
    t.bigint "work_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["work_id"], name: "index_sections_on_work_id"
  end

  create_table "sessions", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "session_id", null: false
    t.text "data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["session_id"], name: "index_sessions_on_session_id"
    t.index ["updated_at"], name: "index_sessions_on_updated_at"
  end

  create_table "table_cells", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "work_id"
    t.bigint "page_id"
    t.bigint "section_id"
    t.string "header"
    t.text "content"
    t.integer "row"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "transcription_field_id"
    t.index ["page_id"], name: "index_table_cells_on_page_id"
    t.index ["section_id"], name: "index_table_cells_on_section_id"
    t.index ["work_id"], name: "index_table_cells_on_work_id"
  end

  create_table "tex_figures", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "page_id"
    t.integer "position"
    t.text "source"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["page_id"], name: "index_tex_figures_on_page_id"
  end

  create_table "transcribe_authorizations", id: false, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "user_id"
    t.integer "work_id"
  end

  create_table "transcription_fields", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "label"
    t.integer "collection_id"
    t.string "input_type"
    t.text "options"
    t.integer "line_number"
    t.integer "position"
    t.integer "percentage"
    t.integer "page_number"
  end

<<<<<<< HEAD
  create_table "users", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "login"
    t.string "display_name"
    t.string "print_name"
    t.string "email"
    t.boolean "owner", default: false
    t.boolean "admin", default: false
    t.string "encrypted_password", default: "", null: false
    t.string "password_salt", default: "", null: false
=======
  create_table "users", force: true do |t|
    t.string   "login"
    t.string   "display_name"
    t.string   "real_name"
    t.string   "email"
    t.boolean  "owner",                     default: false
    t.boolean  "admin",                     default: false
    t.string   "encrypted_password",        default: "",      null: false
    t.string   "password_salt",             default: "",      null: false
>>>>>>> development
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "remember_token"
    t.datetime "remember_token_expires_at"
    t.string "location"
    t.string "website"
    t.string "about"
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
<<<<<<< HEAD
    t.string "orcid"
    t.string "dictation_language", default: "en-US"
    t.boolean "activity_email"
    t.index ["login"], name: "index_users_on_login"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["slug"], name: "index_users_on_slug", unique: true
  end

  create_table "visits", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
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
    t.timestamp "started_at"
    t.index ["user_id"], name: "index_visits_on_user_id"
    t.index ["visit_token"], name: "index_visits_on_visit_token", unique: true
  end

  create_table "work_statistics", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "work_id"
    t.integer "transcribed_pages"
    t.integer "annotated_pages"
    t.integer "total_pages"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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
  end

  create_table "works", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "title"
    t.string "description", limit: 4000
    t.datetime "created_on"
    t.integer "owner_user_id"
    t.boolean "restrict_scribes", default: false
    t.integer "transcription_version", default: 0
    t.text "physical_description"
    t.text "document_history"
    t.text "permission_description"
    t.string "location_of_composition"
    t.string "author"
    t.text "transcription_conventions"
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
    t.index ["collection_id"], name: "index_works_on_collection_id"
    t.index ["owner_user_id"], name: "index_works_on_owner_user_id"
    t.index ["slug"], name: "index_works_on_slug", unique: true
  end
=======
    t.string   "orcid"
    t.string   "dictation_language",        default: "en-US"
    t.boolean  "activity_email"
  end

  add_index "users", ["deleted"], name: "index_users_on_deleted", using: :btree
  add_index "users", ["login"], name: "index_users_on_login", using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree
  add_index "users", ["slug"], name: "index_users_on_slug", unique: true, using: :btree

  create_table "visits", force: true do |t|
    t.string   "visit_token"
    t.string   "visitor_token"
    t.string   "ip"
    t.text     "user_agent"
    t.text     "referrer"
    t.text     "landing_page"
    t.integer  "user_id"
    t.string   "referring_domain"
    t.string   "search_keyword"
    t.string   "browser"
    t.string   "os"
    t.string   "device_type"
    t.integer  "screen_height"
    t.integer  "screen_width"
    t.string   "country"
    t.string   "region"
    t.string   "city"
    t.string   "postal_code"
    t.decimal  "latitude",         precision: 10, scale: 0
    t.decimal  "longitude",        precision: 10, scale: 0
    t.string   "utm_source"
    t.string   "utm_medium"
    t.string   "utm_term"
    t.string   "utm_content"
    t.string   "utm_campaign"
    t.datetime "started_at"
  end

  add_index "visits", ["user_id"], name: "index_visits_on_user_id", using: :btree
  add_index "visits", ["visit_token"], name: "index_visits_on_visit_token", unique: true, using: :btree

  create_table "work_statistics", force: true do |t|
    t.integer  "work_id"
    t.integer  "transcribed_pages"
    t.integer  "annotated_pages"
    t.integer  "total_pages"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "blank_pages",          default: 0
    t.integer  "incomplete_pages",     default: 0
    t.integer  "corrected_pages"
    t.integer  "needs_review"
    t.integer  "translated_pages"
    t.integer  "translated_blank"
    t.integer  "translated_review"
    t.integer  "translated_annotated"
    t.integer  "complete"
    t.integer  "translation_complete"
  end

  create_table "works", force: true do |t|
    t.string   "title"
    t.text     "description",                limit: 16777215
    t.datetime "created_on"
    t.integer  "owner_user_id"
    t.boolean  "restrict_scribes",                            default: false
    t.integer  "transcription_version",                       default: 0
    t.text     "physical_description",       limit: 16777215
    t.text     "document_history",           limit: 16777215
    t.text     "permission_description",     limit: 16777215
    t.string   "location_of_composition"
    t.string   "author"
    t.text     "transcription_conventions",  limit: 16777215
    t.integer  "collection_id"
    t.boolean  "scribes_can_edit_titles",                     default: false
    t.boolean  "supports_translation",                        default: false
    t.text     "translation_instructions"
    t.boolean  "pages_are_meaningful",                        default: true
    t.boolean  "ocr_correction",                              default: false
    t.string   "slug"
    t.string   "picture"
    t.integer  "featured_page"
    t.string   "identifier"
    t.integer  "next_untranscribed_page_id"
  end

  add_index "works", ["collection_id"], name: "index_works_on_collection_id", using: :btree
  add_index "works", ["owner_user_id"], name: "index_works_on_owner_user_id", using: :btree
  add_index "works", ["slug"], name: "index_works_on_slug", unique: true, using: :btree
>>>>>>> development

end
