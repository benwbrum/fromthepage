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

ActiveRecord::Schema.define(version: 20171103141353) do

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

  create_table "article_article_links", force: true do |t|
    t.integer  "source_article_id"
    t.integer  "target_article_id"
    t.string   "display_text"
    t.datetime "created_on"
  end

  add_index "article_article_links", ["source_article_id"], name: "index_article_article_links_on_source_article_id", using: :btree
  add_index "article_article_links", ["target_article_id"], name: "index_article_article_links_on_target_article_id", using: :btree

  create_table "article_versions", force: true do |t|
    t.string   "title"
    t.text     "source_text"
    t.text     "xml_text"
    t.integer  "user_id"
    t.integer  "article_id"
    t.integer  "version",     default: 0
    t.datetime "created_on"
  end

  add_index "article_versions", ["article_id"], name: "index_article_versions_on_article_id", using: :btree
  add_index "article_versions", ["user_id"], name: "index_article_versions_on_user_id", using: :btree

  create_table "articles", force: true do |t|
    t.string   "title"
    t.text     "source_text"
    t.datetime "created_on"
    t.integer  "lock_version",  default: 0
    t.text     "xml_text"
    t.string   "graph_image"
    t.integer  "collection_id"
  end

  add_index "articles", ["collection_id"], name: "index_articles_on_collection_id", using: :btree

  create_table "articles_categories", id: false, force: true do |t|
    t.integer "article_id"
    t.integer "category_id"
  end

  create_table "categories", force: true do |t|
    t.string   "title"
    t.integer  "parent_id"
    t.integer  "collection_id"
    t.datetime "created_on"
  end

  add_index "categories", ["collection_id"], name: "index_categories_on_collection_id", using: :btree
  add_index "categories", ["parent_id"], name: "index_categories_on_parent_id", using: :btree

  create_table "clientperf_results", force: true do |t|
    t.integer  "clientperf_uri_id"
    t.integer  "milliseconds"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "clientperf_results", ["clientperf_uri_id"], name: "index_clientperf_results_on_clientperf_uri_id", using: :btree

  create_table "clientperf_uris", force: true do |t|
    t.string   "uri"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "clientperf_uris", ["uri"], name: "index_clientperf_uris_on_uri", using: :btree

  create_table "collection_collaborators", id: false, force: true do |t|
    t.integer "user_id"
    t.integer "collection_id"
  end

  create_table "collection_owners", id: false, force: true do |t|
    t.integer  "user_id"
    t.integer  "collection_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "collections", force: true do |t|
    t.string   "title"
    t.integer  "owner_user_id"
    t.datetime "created_on"
    t.text     "intro_block"
    t.string   "footer_block",              limit: 2000
    t.boolean  "restricted",                             default: false
    t.string   "picture"
    t.boolean  "supports_document_sets",                 default: false
    t.boolean  "subjects_disabled",                      default: false
    t.text     "transcription_conventions"
    t.string   "slug"
    t.boolean  "review_workflow",                        default: false
    t.boolean  "hide_completed",                         default: true
    t.text     "help"
    t.text     "link_help"
  end

  add_index "collections", ["owner_user_id"], name: "index_collections_on_owner_user_id", using: :btree
  add_index "collections", ["slug"], name: "index_collections_on_slug", unique: true, using: :btree

  create_table "deeds", force: true do |t|
    t.string   "deed_type",     limit: 10
    t.integer  "page_id"
    t.integer  "work_id"
    t.integer  "collection_id"
    t.integer  "article_id"
    t.integer  "user_id"
    t.integer  "note_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "visit_id"
  end

  add_index "deeds", ["article_id"], name: "index_deeds_on_article_id", using: :btree
  add_index "deeds", ["collection_id"], name: "index_deeds_on_collection_id", using: :btree
  add_index "deeds", ["created_at"], name: "index_deeds_on_created_at", using: :btree
  add_index "deeds", ["note_id"], name: "index_deeds_on_note_id", using: :btree
  add_index "deeds", ["page_id"], name: "index_deeds_on_page_id", using: :btree
  add_index "deeds", ["user_id"], name: "index_deeds_on_user_id", using: :btree
  add_index "deeds", ["work_id"], name: "index_deeds_on_work_id", using: :btree

  create_table "document_set_collaborators", id: false, force: true do |t|
    t.integer "user_id"
    t.integer "document_set_id"
  end

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
    t.string   "status",        default: "new"
  end

  add_index "document_uploads", ["collection_id"], name: "index_document_uploads_on_collection_id", using: :btree
  add_index "document_uploads", ["user_id"], name: "index_document_uploads_on_user_id", using: :btree

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
    t.text     "body"
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

  create_table "oai_repositories", force: true do |t|
    t.string   "url"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "oai_sets", force: true do |t|
    t.string   "set_spec"
    t.string   "repository_url"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "omeka_collections", force: true do |t|
    t.integer  "omeka_id"
    t.integer  "collection_id"
    t.string   "title"
    t.string   "description"
    t.integer  "omeka_site_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "omeka_files", force: true do |t|
    t.integer  "omeka_id"
    t.integer  "omeka_item_id"
    t.string   "mime_type"
    t.string   "fullsize_url"
    t.string   "thumbnail_url"
    t.string   "original_filename"
    t.integer  "omeka_order"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "page_id"
  end

  add_index "omeka_files", ["omeka_id"], name: "index_omeka_files_on_omeka_id", using: :btree

  create_table "omeka_items", force: true do |t|
    t.string   "title"
    t.string   "subject"
    t.string   "description"
    t.string   "rights"
    t.string   "creator"
    t.string   "format"
    t.string   "coverage"
    t.integer  "omeka_site_id"
    t.integer  "omeka_id"
    t.string   "omeka_url"
    t.integer  "omeka_collection_id"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "work_id"
  end

  create_table "omeka_sites", force: true do |t|
    t.string   "title"
    t.string   "api_url"
    t.string   "api_key"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "page_article_links", force: true do |t|
    t.integer  "page_id"
    t.integer  "article_id"
    t.string   "display_text"
    t.datetime "created_on"
    t.string   "text_type",    default: "transcription"
  end

  add_index "page_article_links", ["article_id"], name: "index_page_article_links_on_article_id", using: :btree
  add_index "page_article_links", ["page_id"], name: "index_page_article_links_on_page_id", using: :btree

  create_table "page_blocks", force: true do |t|
    t.string   "controller"
    t.string   "view"
    t.string   "tag"
    t.string   "description"
    t.text     "html"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "page_blocks", ["controller", "view"], name: "index_page_blocks_on_controller_and_view", using: :btree

  create_table "page_versions", force: true do |t|
    t.string   "title"
    t.text     "transcription"
    t.text     "xml_transcription"
    t.integer  "user_id"
    t.integer  "page_id"
    t.integer  "work_version",       default: 0
    t.integer  "page_version",       default: 0
    t.datetime "created_on"
    t.text     "source_translation"
    t.text     "xml_translation"
  end

  add_index "page_versions", ["page_id"], name: "index_page_versions_on_page_id", using: :btree
  add_index "page_versions", ["user_id"], name: "index_page_versions_on_user_id", using: :btree

  create_table "pages", force: true do |t|
    t.string   "title"
    t.text     "source_text"
    t.string   "base_image"
    t.integer  "base_width"
    t.integer  "base_height"
    t.integer  "shrink_factor"
    t.integer  "work_id"
    t.datetime "created_on"
    t.integer  "position"
    t.integer  "lock_version",       default: 0
    t.text     "xml_text"
    t.integer  "page_version_id"
    t.string   "status"
    t.text     "source_translation"
    t.text     "xml_translation"
    t.text     "search_text"
    t.string   "translation_status"
  end

  add_index "pages", ["search_text"], name: "pages_search_text_index", type: :fulltext
  add_index "pages", ["work_id"], name: "index_pages_on_work_id", using: :btree

  create_table "pages_sections", id: false, force: true do |t|
    t.integer "page_id",    null: false
    t.integer "section_id", null: false
  end

  add_index "pages_sections", ["page_id", "section_id"], name: "index_pages_sections_on_page_id_and_section_id", using: :btree
  add_index "pages_sections", ["section_id", "page_id"], name: "index_pages_sections_on_section_id_and_page_id", using: :btree

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
    t.string   "session_id", null: false
    t.text     "data"
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
    t.string   "content"
    t.integer  "row"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "table_cells", ["page_id"], name: "index_table_cells_on_page_id", using: :btree
  add_index "table_cells", ["section_id"], name: "index_table_cells_on_section_id", using: :btree
  add_index "table_cells", ["work_id"], name: "index_table_cells_on_work_id", using: :btree

  create_table "tex_figures", force: true do |t|
    t.integer  "page_id"
    t.integer  "position"
    t.text     "source"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "tex_figures", ["page_id"], name: "index_tex_figures_on_page_id", using: :btree

  create_table "transcribe_authorizations", id: false, force: true do |t|
    t.integer "user_id"
    t.integer "work_id"
  end

  create_table "users", force: true do |t|
    t.string   "login"
    t.string   "display_name"
    t.string   "print_name"
    t.string   "email"
    t.boolean  "owner",                     default: false
    t.boolean  "admin",                     default: false
    t.string   "encrypted_password",        default: "",    null: false
    t.string   "password_salt",             default: "",    null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "remember_token"
    t.datetime "remember_token_expires_at"
    t.string   "location"
    t.string   "website"
    t.string   "about"
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",             default: 0,     null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.string   "account_type"
    t.datetime "paid_date"
    t.boolean  "guest"
    t.string   "slug"
  end

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
    t.string   "description",               limit: 4000
    t.datetime "created_on"
    t.integer  "owner_user_id"
    t.boolean  "restrict_scribes",                       default: false
    t.integer  "transcription_version",                  default: 0
    t.text     "physical_description"
    t.text     "document_history"
    t.text     "permission_description"
    t.string   "location_of_composition"
    t.string   "author"
    t.text     "transcription_conventions"
    t.integer  "collection_id"
    t.boolean  "scribes_can_edit_titles",                default: false
    t.boolean  "supports_translation",                   default: false
    t.text     "translation_instructions"
    t.boolean  "pages_are_meaningful",                   default: true
    t.boolean  "ocr_correction"
    t.string   "slug"
    t.string   "picture"
    t.integer  "featured_page"
    t.string   "identifier"
  end

  add_index "works", ["collection_id"], name: "index_works_on_collection_id", using: :btree
  add_index "works", ["owner_user_id"], name: "index_works_on_owner_user_id", using: :btree
  add_index "works", ["slug"], name: "index_works_on_slug", unique: true, using: :btree

end
