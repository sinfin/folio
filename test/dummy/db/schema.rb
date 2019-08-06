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

ActiveRecord::Schema.define(version: 2019_08_06_061816) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "unaccent"

  create_table "ahoy_events", force: :cascade do |t|
    t.integer "visit_id"
    t.bigint "account_id"
    t.string "name"
    t.jsonb "properties"
    t.datetime "time"
    t.index ["account_id"], name: "index_ahoy_events_on_account_id"
    t.index ["name", "time"], name: "index_ahoy_events_on_name_and_time"
    t.index ["visit_id", "name"], name: "index_ahoy_events_on_visit_id_and_name"
  end

  create_table "audits", force: :cascade do |t|
    t.bigint "auditable_id"
    t.string "auditable_type"
    t.bigint "associated_id"
    t.string "associated_type"
    t.bigint "user_id"
    t.string "user_type"
    t.string "username"
    t.string "action"
    t.jsonb "audited_changes"
    t.integer "version", default: 0
    t.string "comment"
    t.string "remote_address"
    t.string "request_uuid"
    t.datetime "created_at"
    t.index ["associated_type", "associated_id"], name: "associated_index"
    t.index ["auditable_type", "auditable_id", "version"], name: "auditable_index"
    t.index ["created_at"], name: "index_audits_on_created_at"
    t.index ["request_uuid"], name: "index_audits_on_request_uuid"
    t.index ["user_id", "user_type"], name: "user_index"
  end

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
    t.string "invitation_token"
    t.datetime "invitation_created_at"
    t.datetime "invitation_sent_at"
    t.datetime "invitation_accepted_at"
    t.integer "invitation_limit"
    t.string "invited_by_type"
    t.bigint "invited_by_id"
    t.integer "invitations_count", default: 0
    t.index ["email"], name: "index_folio_accounts_on_email", unique: true
    t.index ["invitation_token"], name: "index_folio_accounts_on_invitation_token", unique: true
    t.index ["invitations_count"], name: "index_folio_accounts_on_invitations_count"
    t.index ["invited_by_id"], name: "index_folio_accounts_on_invited_by_id"
    t.index ["invited_by_type", "invited_by_id"], name: "index_folio_accounts_on_invited_by_type_and_invited_by_id"
    t.index ["reset_password_token"], name: "index_folio_accounts_on_reset_password_token", unique: true
  end

  create_table "folio_atoms", force: :cascade do |t|
    t.string "type"
    t.text "content"
    t.integer "position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "placement_type"
    t.bigint "placement_id"
    t.string "model_type"
    t.bigint "model_id"
    t.string "title"
    t.text "perex"
    t.string "locale"
    t.index ["model_type", "model_id"], name: "index_folio_atoms_on_model_type_and_model_id"
    t.index ["placement_type", "placement_id"], name: "index_folio_atoms_on_placement_type_and_placement_id"
  end

  create_table "folio_file_placements", force: :cascade do |t|
    t.string "placement_type"
    t.bigint "placement_id"
    t.bigint "file_id"
    t.integer "position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "type"
    t.text "title"
    t.string "alt"
    t.string "placement_title"
    t.string "placement_title_type"
    t.index ["file_id"], name: "index_folio_file_placements_on_file_id"
    t.index ["placement_type", "placement_id"], name: "index_folio_file_placements_on_placement_type_and_placement_id"
    t.index ["type"], name: "index_folio_file_placements_on_type"
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
    t.json "additional_data"
    t.json "file_metadata"
    t.string "hash_id"
    t.index ["type"], name: "index_folio_files_on_type"
  end

  create_table "folio_leads", force: :cascade do |t|
    t.string "email"
    t.string "phone"
    t.text "note"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.string "url"
    t.json "additional_data"
    t.string "aasm_state", default: "submitted"
    t.bigint "visit_id"
    t.index ["visit_id"], name: "index_folio_leads_on_visit_id"
  end

  create_table "folio_menu_items", force: :cascade do |t|
    t.bigint "menu_id"
    t.string "type"
    t.string "ancestry"
    t.string "title"
    t.string "rails_path"
    t.integer "position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "target_type"
    t.bigint "target_id"
    t.index ["ancestry"], name: "index_folio_menu_items_on_ancestry"
    t.index ["menu_id"], name: "index_folio_menu_items_on_menu_id"
    t.index ["target_type", "target_id"], name: "index_folio_menu_items_on_target_type_and_target_id"
    t.index ["type"], name: "index_folio_menu_items_on_type"
  end

  create_table "folio_menus", force: :cascade do |t|
    t.string "type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "locale"
    t.index ["type"], name: "index_folio_menus_on_type"
  end

  create_table "folio_newsletter_subscriptions", force: :cascade do |t|
    t.string "email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "visit_id"
    t.index ["visit_id"], name: "index_folio_newsletter_subscriptions_on_visit_id"
  end

  create_table "folio_pages", force: :cascade do |t|
    t.string "title"
    t.string "slug"
    t.text "perex"
    t.string "meta_title", limit: 512
    t.text "meta_description"
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
    t.index ["ancestry"], name: "index_folio_pages_on_ancestry"
    t.index ["featured"], name: "index_folio_pages_on_featured"
    t.index ["locale"], name: "index_folio_pages_on_locale"
    t.index ["original_id"], name: "index_folio_pages_on_original_id"
    t.index ["position"], name: "index_folio_pages_on_position"
    t.index ["published"], name: "index_folio_pages_on_published"
    t.index ["published_at"], name: "index_folio_pages_on_published_at"
    t.index ["slug"], name: "index_folio_pages_on_slug"
    t.index ["type"], name: "index_folio_pages_on_type"
  end

  create_table "folio_private_attachments", force: :cascade do |t|
    t.string "attachmentable_type"
    t.bigint "attachmentable_id"
    t.string "type"
    t.string "file_uid"
    t.string "file_name"
    t.text "title"
    t.string "alt"
    t.text "thumbnail_sizes"
    t.integer "position"
    t.integer "file_width"
    t.integer "file_height"
    t.bigint "file_size"
    t.string "mime_type", limit: 255
    t.json "additional_data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "hash_id"
    t.index ["attachmentable_type", "attachmentable_id"], name: "index_folio_private_attachments_on_attachmentable"
    t.index ["type"], name: "index_folio_private_attachments_on_type"
  end

  create_table "folio_sites", force: :cascade do |t|
    t.string "title"
    t.string "domain"
    t.string "email"
    t.string "phone"
    t.string "locale"
    t.string "locales", default: [], array: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "google_analytics_tracking_code"
    t.string "facebook_pixel_code"
    t.json "social_links"
    t.text "address"
    t.text "description"
    t.boolean "turbo_mode", default: false
    t.string "system_email"
    t.string "system_email_copy"
    t.string "email_from"
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

  create_table "pg_search_documents", force: :cascade do |t|
    t.text "content"
    t.string "searchable_type"
    t.bigint "searchable_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["searchable_type", "searchable_id"], name: "index_pg_search_documents_on_searchable_type_and_searchable_id"
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

  create_table "visits", force: :cascade do |t|
    t.string "visit_token"
    t.string "visitor_token"
    t.string "ip"
    t.text "user_agent"
    t.text "referrer"
    t.text "landing_page"
    t.bigint "account_id"
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
    t.decimal "latitude"
    t.decimal "longitude"
    t.string "utm_source"
    t.string "utm_medium"
    t.string "utm_term"
    t.string "utm_content"
    t.string "utm_campaign"
    t.datetime "started_at"
    t.index ["account_id"], name: "index_visits_on_account_id"
    t.index ["visit_token"], name: "index_visits_on_visit_token", unique: true
  end

end
