# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of ActiveRecord to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 26) do

  create_table "article_article_links", :force => true do |t|
    t.integer  "source_article_id"
    t.integer  "target_article_id"
    t.string   "display_text"
    t.datetime "created_on"
  end

  create_table "article_versions", :force => true do |t|
    t.string   "title"
    t.text     "source_text"
    t.text     "xml_text"
    t.integer  "user_id"
    t.integer  "article_id"
    t.integer  "version",     :default => 0
    t.datetime "created_on"
  end

  create_table "articles", :force => true do |t|
    t.string   "title"
    t.text     "source_text"
    t.datetime "created_on"
    t.integer  "lock_version",  :default => 0
    t.text     "xml_text"
    t.string   "graph_image"
    t.integer  "collection_id"
  end

  create_table "articles_categories", :id => false, :force => true do |t|
    t.integer "article_id"
    t.integer "category_id"
  end

  create_table "categories", :force => true do |t|
    t.string   "title"
    t.integer  "parent_id"
    t.integer  "collection_id"
    t.datetime "created_on"
  end

  create_table "collections", :force => true do |t|
    t.string   "title"
    t.integer  "owner_user_id"
    t.datetime "created_on"
  end

  create_table "image_sets", :force => true do |t|
    t.string   "path"
    t.string   "title_format"
    t.datetime "created_on"
    t.integer  "orientation"
    t.integer  "original_width"
    t.integer  "original_height"
    t.integer  "original_to_base_halvings"
    t.integer  "owner_user_id"
  end

  create_table "page_article_links", :force => true do |t|
    t.integer  "page_id"
    t.integer  "article_id"
    t.string   "display_text"
    t.datetime "created_on"
  end

  create_table "page_versions", :force => true do |t|
    t.string   "title"
    t.text     "transcription"
    t.text     "xml_transcription"
    t.integer  "user_id"
    t.integer  "page_id"
    t.integer  "work_version",      :default => 0
    t.integer  "page_version",      :default => 0
    t.datetime "created_on"
  end

  create_table "pages", :force => true do |t|
    t.string   "title"
    t.text     "source_text"
    t.string   "base_image"
    t.integer  "base_width"
    t.integer  "base_height"
    t.integer  "shrink_factor"
    t.integer  "work_id"
    t.datetime "created_on"
    t.integer  "position"
    t.integer  "lock_version",  :default => 0
    t.text     "xml_text"
  end

  create_table "sessions", :force => true do |t|
    t.string   "session_id", :default => "", :null => false
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"
  add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"

  create_table "titled_images", :force => true do |t|
    t.string   "original_file",                  :default => "",    :null => false
    t.string   "title_seed",       :limit => 20
    t.string   "title_override"
    t.string   "title"
    t.boolean  "shrink_completed",               :default => false
    t.boolean  "rotate_completed",               :default => false
    t.boolean  "crop_completed",                 :default => false
    t.integer  "image_set_id"
    t.integer  "position"
    t.datetime "created_on"
    t.integer  "lock_version",                   :default => 0
  end

  create_table "transcribe_authorizations", :id => false, :force => true do |t|
    t.integer "user_id"
    t.integer "work_id"
  end

  create_table "users", :force => true do |t|
    t.string   "login"
    t.string   "display_name"
    t.string   "print_name"
    t.string   "email"
    t.boolean  "owner",                                   :default => false
    t.boolean  "admin",                                   :default => false
    t.string   "crypted_password",          :limit => 40
    t.string   "salt",                      :limit => 40
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "remember_token"
    t.datetime "remember_token_expires_at"
  end

  create_table "works", :force => true do |t|
    t.string   "title"
    t.string   "description",               :limit => 4000
    t.datetime "created_on"
    t.integer  "owner_user_id"
    t.boolean  "restrict_scribes",                          :default => false
    t.integer  "transcription_version",                     :default => 0
    t.text     "physical_description"
    t.text     "document_history"
    t.text     "permission_description"
    t.string   "location_of_composition"
    t.string   "author"
    t.text     "transcription_conventions"
    t.integer  "collection_id"
  end

end
