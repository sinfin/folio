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

ActiveRecord::Schema.define(version: 20170710125813) do

  create_table "folio_nodes", force: :cascade do |t|
    t.integer "folio_site_id"
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
    t.datetime "published_at"
    t.integer "original_id"
    t.string "locale", limit: 6
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ancestry"], name: "index_folio_nodes_on_ancestry"
    t.index ["code"], name: "index_folio_nodes_on_code"
    t.index ["folio_site_id"], name: "index_folio_nodes_on_folio_site_id"
    t.index ["locale"], name: "index_folio_nodes_on_locale"
    t.index ["original_id"], name: "index_folio_nodes_on_original_id"
    t.index ["position"], name: "index_folio_nodes_on_position"
    t.index ["published_at"], name: "index_folio_nodes_on_published_at"
    t.index ["slug"], name: "index_folio_nodes_on_slug"
    t.index ["type"], name: "index_folio_nodes_on_type"
  end

  create_table "folio_sites", force: :cascade do |t|
    t.string "title"
    t.string "domain"
    t.string "locale", default: "en"
    t.string "locales"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["domain"], name: "index_folio_sites_on_domain"
    t.index ["locales"], name: "index_folio_sites_on_locales"
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

end
