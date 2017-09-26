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

ActiveRecord::Schema.define(version: 20170925111436) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "folio_accounts", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "first_name"
    t.string "last_name"
    t.string "role"
    t.boolean "is_active", default: true
    t.index ["email"], name: "index_folio_accounts_on_email", unique: true
    t.index ["reset_password_token"], name: "index_folio_accounts_on_reset_password_token", unique: true
  end

  create_table "folio_atoms", force: :cascade do |t|
    t.string "type"
    t.bigint "node_id"
    t.text "content"
    t.integer "position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["node_id"], name: "index_folio_atoms_on_node_id"
  end

  create_table "folio_file_placements", force: :cascade do |t|
    t.bigint "node_id"
    t.bigint "file_id"
    t.string "caption"
    t.integer "position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["file_id"], name: "index_folio_file_placements_on_file_id"
    t.index ["node_id"], name: "index_folio_file_placements_on_node_id"
  end

  create_table "folio_files", force: :cascade do |t|
    t.string "file_uid"
    t.string "file_name"
    t.string "type"
    t.text "thumbnail_sizes", default: "--- {}\n"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "file_width"
    t.integer "file_height"
    t.bigint "file_size"
    t.string "mime_type", limit: 255
    t.index ["type"], name: "index_folio_files_on_type"
  end

  create_table "folio_leads", force: :cascade do |t|
    t.string "email"
    t.string "phone"
    t.text "note"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "folio_menu_items", force: :cascade do |t|
    t.bigint "menu_id"
    t.bigint "node_id"
    t.string "type"
    t.string "ancestry"
    t.string "title"
    t.string "rails_path"
    t.integer "position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ancestry"], name: "index_folio_menu_items_on_ancestry"
    t.index ["menu_id"], name: "index_folio_menu_items_on_menu_id"
    t.index ["node_id"], name: "index_folio_menu_items_on_node_id"
    t.index ["type"], name: "index_folio_menu_items_on_type"
  end

  create_table "folio_menus", force: :cascade do |t|
    t.string "type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["type"], name: "index_folio_menus_on_type"
  end

  create_table "folio_nodes", force: :cascade do |t|
    t.integer "site_id"
    t.string "title"
    t.string "slug"
    t.text "perex"
    t.text "content"
    t.string "meta_title", limit: 512
    t.string "meta_description", limit: 1024
    t.string "code"
    t.string "ancestry"
    t.string "type"
    t.boolean "featured"
    t.integer "position"
    t.boolean "published"
    t.datetime "published_at"
    t.integer "original_id"
    t.string "locale", limit: 6
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ancestry"], name: "index_folio_nodes_on_ancestry"
    t.index ["code"], name: "index_folio_nodes_on_code"
    t.index ["featured"], name: "index_folio_nodes_on_featured"
    t.index ["locale"], name: "index_folio_nodes_on_locale"
    t.index ["original_id"], name: "index_folio_nodes_on_original_id"
    t.index ["position"], name: "index_folio_nodes_on_position"
    t.index ["published"], name: "index_folio_nodes_on_published"
    t.index ["published_at"], name: "index_folio_nodes_on_published_at"
    t.index ["site_id"], name: "index_folio_nodes_on_site_id"
    t.index ["slug"], name: "index_folio_nodes_on_slug"
    t.index ["type"], name: "index_folio_nodes_on_type"
  end

  create_table "folio_sites", force: :cascade do |t|
    t.string "title"
    t.string "domain"
    t.string "email"
    t.string "phone"
    t.string "locale", default: "en"
    t.string "locales", default: [], array: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "google_analytics_tracking_code"
    t.string "facebook_pixel_code"
    t.index ["domain"], name: "index_folio_sites_on_domain"
  end

  create_table "friendly_id_slugs", force: :cascade do |t|
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

  create_table "taggings", id: :serial, force: :cascade do |t|
    t.integer "tag_id"
    t.string "taggable_type"
    t.integer "taggable_id"
    t.string "tagger_type"
    t.integer "tagger_id"
    t.string "context", limit: 128
    t.datetime "created_at"
    t.index ["context"], name: "index_taggings_on_context"
    t.index ["tag_id", "taggable_id", "taggable_type", "context", "tagger_id", "tagger_type"], name: "taggings_idx", unique: true
    t.index ["tag_id"], name: "index_taggings_on_tag_id"
    t.index ["taggable_id", "taggable_type", "context"], name: "index_taggings_on_taggable_id_and_taggable_type_and_context"
    t.index ["taggable_id", "taggable_type", "tagger_id", "context"], name: "taggings_idy"
    t.index ["taggable_id"], name: "index_taggings_on_taggable_id"
    t.index ["taggable_type"], name: "index_taggings_on_taggable_type"
    t.index ["tagger_id", "tagger_type"], name: "index_taggings_on_tagger_id_and_tagger_type"
    t.index ["tagger_id"], name: "index_taggings_on_tagger_id"
  end

  create_table "tags", id: :serial, force: :cascade do |t|
    t.string "name"
    t.integer "taggings_count", default: 0
    t.index ["name"], name: "index_tags_on_name", unique: true
  end

end
