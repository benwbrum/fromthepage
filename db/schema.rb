# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20180412032317) do

  create_table "ahoy_events", force: :cascade do |t|
    t.integer  "visit_id",   limit: 4
    t.integer  "user_id",    limit: 4
    t.string   "name",       limit: 255
    t.text     "properties", limit: 65535
    t.datetime "time"
  end

  add_index "ahoy_events", ["name", "time"], name: "index_ahoy_events_on_name_and_time", using: :btree
  add_index "ahoy_events", ["user_id", "name"], name: "index_ahoy_events_on_user_id_and_name", using: :btree
  add_index "ahoy_events", ["visit_id", "name"], name: "index_ahoy_events_on_visit_id_and_name", using: :btree

  create_table "article_article_links", force: :cascade do |t|
    t.integer  "source_article_id", limit: 4
    t.integer  "target_article_id", limit: 4
    t.string   "display_text",      limit: 255
    t.datetime "created_on"
  end

  add_index "article_article_links", ["source_article_id"], name: "index_article_article_links_on_source_article_id", using: :btree
  add_index "article_article_links", ["target_article_id"], name: "index_article_article_links_on_target_article_id", using: :btree

  create_table "article_versions", force: :cascade do |t|
    t.string   "title",       limit: 255
    t.text     "source_text", limit: 65535
    t.text     "xml_text",    limit: 65535
    t.integer  "user_id",     limit: 4
    t.integer  "article_id",  limit: 4
    t.integer  "version",     limit: 4,     default: 0
    t.datetime "created_on"
  end

  add_index "article_versions", ["article_id"], name: "index_article_versions_on_article_id", using: :btree
  add_index "article_versions", ["user_id"], name: "index_article_versions_on_user_id", using: :btree

  create_table "articles", force: :cascade do |t|
    t.string   "title",         limit: 255
    t.text     "source_text",   limit: 65535
    t.datetime "created_on"
    t.integer  "lock_version",  limit: 4,     default: 0
    t.text     "xml_text",      limit: 65535
    t.string   "graph_image",   limit: 255
    t.integer  "collection_id", limit: 4
  end

  add_index "articles", ["collection_id"], name: "index_articles_on_collection_id", using: :btree

  create_table "articles_categories", id: false, force: :cascade do |t|
    t.integer "article_id",  limit: 4
    t.integer "category_id", limit: 4
  end

  create_table "categories", force: :cascade do |t|
    t.string   "title",         limit: 255
    t.integer  "parent_id",     limit: 4
    t.integer  "collection_id", limit: 4
    t.datetime "created_on"
  end

  add_index "categories", ["collection_id"], name: "index_categories_on_collection_id", using: :btree
  add_index "categories", ["parent_id"], name: "index_categories_on_parent_id", using: :btree

  create_table "clientperf_results", force: :cascade do |t|
    t.integer  "clientperf_uri_id", limit: 4
    t.integer  "milliseconds",      limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "clientperf_results", ["clientperf_uri_id"], name: "index_clientperf_results_on_clientperf_uri_id", using: :btree

  create_table "clientperf_uris", force: :cascade do |t|
    t.string   "uri",        limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "clientperf_uris", ["uri"], name: "index_clientperf_uris_on_uri", using: :btree

  create_table "collection_collaborators", id: false, force: :cascade do |t|
    t.integer "user_id",       limit: 4
    t.integer "collection_id", limit: 4
  end

  create_table "collection_owners", id: false, force: :cascade do |t|
    t.integer  "user_id",       limit: 4
    t.integer  "collection_id", limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "collections", force: :cascade do |t|
    t.string   "title",                     limit: 255
    t.integer  "owner_user_id",             limit: 4
    t.datetime "created_on"
    t.text     "intro_block",               limit: 65535
    t.string   "footer_block",              limit: 2000
    t.boolean  "restricted",                              default: false
    t.string   "picture",                   limit: 255
    t.boolean  "supports_document_sets",                  default: false
    t.boolean  "subjects_disabled",                       default: false
    t.text     "transcription_conventions", limit: 65535
    t.string   "slug",                      limit: 255
    t.boolean  "review_workflow",                         default: false
    t.boolean  "hide_completed",                          default: true
    t.text     "help",                      limit: 65535
    t.text     "link_help",                 limit: 65535
  end

  add_index "collections", ["owner_user_id"], name: "index_collections_on_owner_user_id", using: :btree
  add_index "collections", ["slug"], name: "index_collections_on_slug", unique: true, using: :btree

  create_table "contributions", force: :cascade do |t|
    t.string   "type",                  limit: 255
    t.string   "text",                  limit: 255
    t.integer  "mark_id",               limit: 4
    t.integer  "user_id",               limit: 4
    t.integer  "cached_weighted_score", limit: 4,   default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "contributions", ["mark_id"], name: "index_contributions_on_mark_id", using: :btree
  add_index "contributions", ["user_id"], name: "index_contributions_on_user_id", using: :btree

  create_table "deeds", force: :cascade do |t|
    t.string   "deed_type",     limit: 10
    t.integer  "page_id",       limit: 4
    t.integer  "work_id",       limit: 4
    t.integer  "collection_id", limit: 4
    t.integer  "article_id",    limit: 4
    t.integer  "user_id",       limit: 4
    t.integer  "note_id",       limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "visit_id",      limit: 4
  end

  add_index "deeds", ["article_id"], name: "index_deeds_on_article_id", using: :btree
  add_index "deeds", ["collection_id"], name: "index_deeds_on_collection_id", using: :btree
  add_index "deeds", ["created_at"], name: "index_deeds_on_created_at", using: :btree
  add_index "deeds", ["note_id"], name: "index_deeds_on_note_id", using: :btree
  add_index "deeds", ["page_id"], name: "index_deeds_on_page_id", using: :btree
  add_index "deeds", ["user_id"], name: "index_deeds_on_user_id", using: :btree
  add_index "deeds", ["work_id"], name: "index_deeds_on_work_id", using: :btree

  create_table "document_set_collaborators", id: false, force: :cascade do |t|
    t.integer "user_id",         limit: 4
    t.integer "document_set_id", limit: 4
  end

  create_table "document_sets", force: :cascade do |t|
    t.boolean  "is_public"
    t.integer  "owner_user_id", limit: 4
    t.integer  "collection_id", limit: 4
    t.string   "title",         limit: 255
    t.text     "description",   limit: 65535
    t.string   "picture",       limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "slug",          limit: 255
  end

  add_index "document_sets", ["collection_id"], name: "index_document_sets_on_collection_id", using: :btree
  add_index "document_sets", ["owner_user_id"], name: "index_document_sets_on_owner_user_id", using: :btree
  add_index "document_sets", ["slug"], name: "index_document_sets_on_slug", unique: true, using: :btree

  create_table "document_sets_works", id: false, force: :cascade do |t|
    t.integer "document_set_id", limit: 4, null: false
    t.integer "work_id",         limit: 4, null: false
  end

  add_index "document_sets_works", ["work_id", "document_set_id"], name: "index_document_sets_works_on_work_id_and_document_set_id", unique: true, using: :btree

  create_table "document_uploads", force: :cascade do |t|
    t.integer  "user_id",       limit: 4
    t.integer  "collection_id", limit: 4
    t.string   "file",          limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "status",        limit: 255, default: "new"
  end

  add_index "document_uploads", ["collection_id"], name: "index_document_uploads_on_collection_id", using: :btree
  add_index "document_uploads", ["user_id"], name: "index_document_uploads_on_user_id", using: :btree

  create_table "foros", force: :cascade do |t|
    t.integer  "user_id",      limit: 4
    t.integer  "element_id",   limit: 4
    t.string   "element_type", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "friendly_id_slugs", force: :cascade do |t|
    t.string   "slug",           limit: 255, null: false
    t.integer  "sluggable_id",   limit: 4,   null: false
    t.string   "sluggable_type", limit: 50
    t.string   "scope",          limit: 255
    t.datetime "created_at"
  end

  add_index "friendly_id_slugs", ["slug", "sluggable_type", "scope"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type_and_scope", unique: true, using: :btree
  add_index "friendly_id_slugs", ["slug", "sluggable_type"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type", using: :btree
  add_index "friendly_id_slugs", ["sluggable_id"], name: "index_friendly_id_slugs_on_sluggable_id", using: :btree
  add_index "friendly_id_slugs", ["sluggable_type"], name: "index_friendly_id_slugs_on_sluggable_type", using: :btree

  create_table "ia_leaves", force: :cascade do |t|
    t.integer  "ia_work_id",  limit: 4
    t.integer  "page_id",     limit: 4
    t.integer  "page_w",      limit: 4
    t.integer  "page_h",      limit: 4
    t.integer  "leaf_number", limit: 4
    t.string   "page_number", limit: 255
    t.string   "page_type",   limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "ocr_text",    limit: 65535
  end

  create_table "ia_works", force: :cascade do |t|
    t.string   "detail_url",     limit: 255
    t.integer  "user_id",        limit: 4
    t.integer  "work_id",        limit: 4
    t.string   "server",         limit: 255
    t.string   "ia_path",        limit: 255
    t.string   "book_id",        limit: 255
    t.string   "title",          limit: 255
    t.string   "creator",        limit: 255
    t.string   "collection",     limit: 255
    t.string   "description",    limit: 1024
    t.string   "subject",        limit: 255
    t.string   "notes",          limit: 255
    t.string   "contributor",    limit: 255
    t.string   "sponsor",        limit: 255
    t.string   "image_count",    limit: 255
    t.integer  "title_leaf",     limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "image_format",   limit: 255,  default: "jp2"
    t.string   "archive_format", limit: 255,  default: "zip"
    t.string   "scandata_file",  limit: 255
    t.string   "djvu_file",      limit: 255
    t.string   "zip_file",       limit: 255
    t.boolean  "use_ocr",                     default: false
  end

  create_table "marks", force: :cascade do |t|
    t.integer "page_id",          limit: 4
    t.integer "transcription_id", limit: 4
    t.integer "translation_id",   limit: 4
    t.string  "text_type",        limit: 255
    t.text    "coordinates",      limit: 65535
    t.string  "shape_type",       limit: 255
  end

  add_index "marks", ["page_id"], name: "index_marks_on_page_id", using: :btree

  create_table "notes", force: :cascade do |t|
    t.string   "title",         limit: 255
    t.text     "body",          limit: 65535
    t.integer  "user_id",       limit: 4
    t.integer  "collection_id", limit: 4
    t.integer  "work_id",       limit: 4
    t.integer  "page_id",       limit: 4
    t.integer  "parent_id",     limit: 4
    t.integer  "depth",         limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "notes", ["page_id"], name: "index_notes_on_page_id", using: :btree

  create_table "oai_repositories", force: :cascade do |t|
    t.string   "url",        limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "oai_sets", force: :cascade do |t|
    t.string   "set_spec",       limit: 255
    t.string   "repository_url", limit: 255
    t.integer  "user_id",        limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "omeka_collections", force: :cascade do |t|
    t.integer  "omeka_id",      limit: 4
    t.integer  "collection_id", limit: 4
    t.string   "title",         limit: 255
    t.string   "description",   limit: 255
    t.integer  "omeka_site_id", limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "omeka_files", force: :cascade do |t|
    t.integer  "omeka_id",          limit: 4
    t.integer  "omeka_item_id",     limit: 4
    t.string   "mime_type",         limit: 255
    t.string   "fullsize_url",      limit: 255
    t.string   "thumbnail_url",     limit: 255
    t.string   "original_filename", limit: 255
    t.integer  "omeka_order",       limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "page_id",           limit: 4
  end

  add_index "omeka_files", ["omeka_id"], name: "index_omeka_files_on_omeka_id", using: :btree

  create_table "omeka_items", force: :cascade do |t|
    t.string   "title",               limit: 255
    t.string   "subject",             limit: 255
    t.string   "description",         limit: 255
    t.string   "rights",              limit: 255
    t.string   "creator",             limit: 255
    t.string   "format",              limit: 255
    t.string   "coverage",            limit: 255
    t.integer  "omeka_site_id",       limit: 4
    t.integer  "omeka_id",            limit: 4
    t.string   "omeka_url",           limit: 255
    t.integer  "omeka_collection_id", limit: 4
    t.integer  "user_id",             limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "work_id",             limit: 4
  end

  create_table "omeka_sites", force: :cascade do |t|
    t.string   "title",      limit: 255
    t.string   "api_url",    limit: 255
    t.string   "api_key",    limit: 255
    t.integer  "user_id",    limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "page_article_links", force: :cascade do |t|
    t.integer  "page_id",      limit: 4
    t.integer  "article_id",   limit: 4
    t.string   "display_text", limit: 255
    t.datetime "created_on"
    t.string   "text_type",    limit: 255, default: "transcription"
  end

  add_index "page_article_links", ["article_id"], name: "index_page_article_links_on_article_id", using: :btree
  add_index "page_article_links", ["page_id"], name: "index_page_article_links_on_page_id", using: :btree

  create_table "page_blocks", force: :cascade do |t|
    t.string   "controller",  limit: 255
    t.string   "view",        limit: 255
    t.string   "tag",         limit: 255
    t.string   "description", limit: 255
    t.text     "html",        limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "page_blocks", ["controller", "view"], name: "index_page_blocks_on_controller_and_view", using: :btree

  create_table "page_versions", force: :cascade do |t|
    t.string   "title",              limit: 255
    t.text     "transcription",      limit: 65535
    t.text     "xml_transcription",  limit: 65535
    t.integer  "user_id",            limit: 4
    t.integer  "page_id",            limit: 4
    t.integer  "work_version",       limit: 4,     default: 0
    t.integer  "page_version",       limit: 4,     default: 0
    t.datetime "created_on"
    t.text     "source_translation", limit: 65535
    t.text     "xml_translation",    limit: 65535
  end

  add_index "page_versions", ["page_id"], name: "index_page_versions_on_page_id", using: :btree
  add_index "page_versions", ["user_id"], name: "index_page_versions_on_user_id", using: :btree

  create_table "pages", force: :cascade do |t|
    t.string   "title",              limit: 255
    t.text     "source_text",        limit: 65535
    t.string   "base_image",         limit: 255
    t.integer  "base_width",         limit: 4
    t.integer  "base_height",        limit: 4
    t.integer  "shrink_factor",      limit: 4
    t.integer  "work_id",            limit: 4
    t.datetime "created_on"
    t.integer  "position",           limit: 4
    t.integer  "lock_version",       limit: 4,     default: 0
    t.text     "xml_text",           limit: 65535
    t.integer  "page_version_id",    limit: 4
    t.string   "status",             limit: 255
    t.text     "source_translation", limit: 65535
    t.text     "xml_translation",    limit: 65535
    t.text     "search_text",        limit: 65535
    t.string   "translation_status", limit: 255
  end

  add_index "pages", ["search_text"], name: "pages_search_text_index", type: :fulltext
  add_index "pages", ["work_id"], name: "index_pages_on_work_id", using: :btree

  create_table "pages_sections", id: false, force: :cascade do |t|
    t.integer "page_id",    limit: 4, null: false
    t.integer "section_id", limit: 4, null: false
  end

  add_index "pages_sections", ["page_id", "section_id"], name: "index_pages_sections_on_page_id_and_section_id", using: :btree
  add_index "pages_sections", ["section_id", "page_id"], name: "index_pages_sections_on_section_id_and_page_id", using: :btree

  create_table "publications", force: :cascade do |t|
    t.integer  "user_id",    limit: 4
    t.integer  "foro_id",    limit: 4
    t.integer  "parent_id",  limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "text",       limit: 255
  end

  create_table "sc_canvases", force: :cascade do |t|
    t.string   "sc_id",              limit: 255
    t.integer  "sc_manifest_id",     limit: 4
    t.integer  "page_id",            limit: 4
    t.string   "sc_canvas_id",       limit: 255
    t.string   "sc_canvas_label",    limit: 255
    t.string   "sc_service_id",      limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "height",             limit: 4
    t.integer  "width",              limit: 4
    t.string   "sc_resource_id",     limit: 255
    t.string   "sc_service_context", limit: 255
  end

  add_index "sc_canvases", ["page_id"], name: "index_sc_canvases_on_page_id", using: :btree
  add_index "sc_canvases", ["sc_manifest_id"], name: "index_sc_canvases_on_sc_manifest_id", using: :btree

  create_table "sc_collections", force: :cascade do |t|
    t.integer  "collection_id", limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "at_id",         limit: 255
    t.integer  "parent_id",     limit: 4
    t.string   "label",         limit: 255
  end

  add_index "sc_collections", ["collection_id"], name: "index_sc_collections_on_collection_id", using: :btree

  create_table "sc_manifests", force: :cascade do |t|
    t.integer  "work_id",              limit: 4
    t.integer  "sc_collection_id",     limit: 4
    t.string   "sc_id",                limit: 255
    t.text     "label",                limit: 65535
    t.text     "metadata",             limit: 65535
    t.string   "first_sequence_id",    limit: 255
    t.string   "first_sequence_label", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "at_id",                limit: 255
    t.integer  "collection_id",        limit: 4
  end

  add_index "sc_manifests", ["sc_collection_id"], name: "index_sc_manifests_on_sc_collection_id", using: :btree
  add_index "sc_manifests", ["work_id"], name: "index_sc_manifests_on_work_id", using: :btree

  create_table "sections", force: :cascade do |t|
    t.string   "title",      limit: 255
    t.integer  "depth",      limit: 4
    t.integer  "position",   limit: 4
    t.integer  "work_id",    limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sections", ["work_id"], name: "index_sections_on_work_id", using: :btree

  create_table "sessions", force: :cascade do |t|
    t.string   "session_id", limit: 255,   null: false
    t.text     "data",       limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], name: "index_sessions_on_session_id", using: :btree
  add_index "sessions", ["updated_at"], name: "index_sessions_on_updated_at", using: :btree

  create_table "table_cells", force: :cascade do |t|
    t.integer  "work_id",    limit: 4
    t.integer  "page_id",    limit: 4
    t.integer  "section_id", limit: 4
    t.string   "header",     limit: 255
    t.string   "content",    limit: 255
    t.integer  "row",        limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "table_cells", ["page_id"], name: "index_table_cells_on_page_id", using: :btree
  add_index "table_cells", ["section_id"], name: "index_table_cells_on_section_id", using: :btree
  add_index "table_cells", ["work_id"], name: "index_table_cells_on_work_id", using: :btree

  create_table "tex_figures", force: :cascade do |t|
    t.integer  "page_id",    limit: 4
    t.integer  "position",   limit: 4
    t.text     "source",     limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "tex_figures", ["page_id"], name: "index_tex_figures_on_page_id", using: :btree

  create_table "transcribe_authorizations", id: false, force: :cascade do |t|
    t.integer "user_id", limit: 4
    t.integer "work_id", limit: 4
  end

  create_table "users", force: :cascade do |t|
    t.string   "login",                           limit: 255
    t.string   "display_name",                    limit: 255
    t.string   "print_name",                      limit: 255
    t.string   "email",                           limit: 255
    t.boolean  "owner",                                       default: false
    t.boolean  "admin",                                       default: false
    t.string   "encrypted_password",              limit: 255, default: "",    null: false
    t.string   "password_salt",                   limit: 255, default: "",    null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "remember_token",                  limit: 255
    t.datetime "remember_token_expires_at"
    t.string   "location",                        limit: 255
    t.string   "website",                         limit: 255
    t.string   "about",                           limit: 255
    t.string   "reset_password_token",            limit: 255
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                   limit: 4,   default: 0,     null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip",              limit: 255
    t.string   "last_sign_in_ip",                 limit: 255
    t.string   "account_type",                    limit: 255
    t.datetime "paid_date"
    t.boolean  "guest"
    t.string   "slug",                            limit: 255
    t.string   "authentication_token",            limit: 255
    t.datetime "authentication_token_created_at"
  end

  add_index "users", ["authentication_token"], name: "index_users_on_authentication_token", unique: true, using: :btree
  add_index "users", ["login"], name: "index_users_on_login", using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree
  add_index "users", ["slug"], name: "index_users_on_slug", unique: true, using: :btree

  create_table "visits", force: :cascade do |t|
    t.string   "visit_token",      limit: 255
    t.string   "visitor_token",    limit: 255
    t.string   "ip",               limit: 255
    t.text     "user_agent",       limit: 65535
    t.text     "referrer",         limit: 65535
    t.text     "landing_page",     limit: 65535
    t.integer  "user_id",          limit: 4
    t.string   "referring_domain", limit: 255
    t.string   "search_keyword",   limit: 255
    t.string   "browser",          limit: 255
    t.string   "os",               limit: 255
    t.string   "device_type",      limit: 255
    t.integer  "screen_height",    limit: 4
    t.integer  "screen_width",     limit: 4
    t.string   "country",          limit: 255
    t.string   "region",           limit: 255
    t.string   "city",             limit: 255
    t.string   "postal_code",      limit: 255
    t.decimal  "latitude",                       precision: 10
    t.decimal  "longitude",                      precision: 10
    t.string   "utm_source",       limit: 255
    t.string   "utm_medium",       limit: 255
    t.string   "utm_term",         limit: 255
    t.string   "utm_content",      limit: 255
    t.string   "utm_campaign",     limit: 255
    t.datetime "started_at"
  end

  add_index "visits", ["user_id"], name: "index_visits_on_user_id", using: :btree
  add_index "visits", ["visit_token"], name: "index_visits_on_visit_token", unique: true, using: :btree

  create_table "votes", force: :cascade do |t|
    t.integer  "votable_id",   limit: 4
    t.string   "votable_type", limit: 255
    t.integer  "voter_id",     limit: 4
    t.string   "voter_type",   limit: 255
    t.boolean  "vote_flag"
    t.string   "vote_scope",   limit: 255
    t.integer  "vote_weight",  limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "votes", ["votable_id", "votable_type", "vote_scope"], name: "index_votes_on_votable_id_and_votable_type_and_vote_scope", using: :btree
  add_index "votes", ["voter_id", "voter_type", "vote_scope"], name: "index_votes_on_voter_id_and_voter_type_and_vote_scope", using: :btree

  create_table "work_statistics", force: :cascade do |t|
    t.integer  "work_id",              limit: 4
    t.integer  "transcribed_pages",    limit: 4
    t.integer  "annotated_pages",      limit: 4
    t.integer  "total_pages",          limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "blank_pages",          limit: 4, default: 0
    t.integer  "incomplete_pages",     limit: 4, default: 0
    t.integer  "corrected_pages",      limit: 4
    t.integer  "needs_review",         limit: 4
    t.integer  "translated_pages",     limit: 4
    t.integer  "translated_blank",     limit: 4
    t.integer  "translated_review",    limit: 4
    t.integer  "translated_annotated", limit: 4
  end

  create_table "works", force: :cascade do |t|
    t.string   "title",                     limit: 255
    t.string   "description",               limit: 4000
    t.datetime "created_on"
    t.integer  "owner_user_id",             limit: 4
    t.boolean  "restrict_scribes",                        default: false
    t.integer  "transcription_version",     limit: 4,     default: 0
    t.text     "physical_description",      limit: 65535
    t.text     "document_history",          limit: 65535
    t.text     "permission_description",    limit: 65535
    t.string   "location_of_composition",   limit: 255
    t.string   "author",                    limit: 255
    t.text     "transcription_conventions", limit: 65535
    t.integer  "collection_id",             limit: 4
    t.boolean  "scribes_can_edit_titles",                 default: false
    t.boolean  "supports_translation",                    default: false
    t.text     "translation_instructions",  limit: 65535
    t.boolean  "pages_are_meaningful",                    default: true
    t.boolean  "ocr_correction"
    t.string   "slug",                      limit: 255
    t.string   "picture",                   limit: 255
    t.integer  "featured_page",             limit: 4
    t.string   "identifier",                limit: 255
  end

  add_index "works", ["collection_id"], name: "index_works_on_collection_id", using: :btree
  add_index "works", ["owner_user_id"], name: "index_works_on_owner_user_id", using: :btree
  add_index "works", ["slug"], name: "index_works_on_slug", unique: true, using: :btree

end
