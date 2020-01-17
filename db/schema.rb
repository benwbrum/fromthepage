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

ActiveRecord::Schema.define(version: 2019_11_29_190417) do
  
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
    t.datetime "created_on"
    t.index ["source_article_id"], name: "index_article_article_links_on_source_article_id"
    t.index ["target_article_id"], name: "index_article_article_links_on_target_article_id"
  end

  create_table "article_versions", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "title"
    t.text "source_text"
    t.text "xml_text"
    t.integer "user_id"
    t.integer "article_id"
    t.integer "version", default: 0
    t.datetime "created_on"
    t.index ["article_id"], name: "index_article_versions_on_article_id"
    t.index ["user_id"], name: "index_article_versions_on_user_id"
  end

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
    t.integer "user_id"
    t.integer "document_set_id"
  end

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
    t.integer  "next_untranscribed_page_id"
    t.integer  "works_count",                default: 0
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
