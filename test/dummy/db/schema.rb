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

ActiveRecord::Schema[8.0].define(version: 2026_03_31_165642) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pg_trgm"
  enable_extension "unaccent"

  create_folio_unaccent

  create_table "audits", force: :cascade do |t|
    t.string "action"
    t.bigint "associated_id"
    t.string "associated_type"
    t.bigint "auditable_id"
    t.string "auditable_type"
    t.jsonb "audited_changes"
    t.string "comment"
    t.datetime "created_at", precision: nil
    t.jsonb "folio_data"
    t.integer "placement_version"
    t.string "remote_address"
    t.string "request_uuid"
    t.bigint "user_id"
    t.string "user_type"
    t.string "username"
    t.integer "version", default: 0
    t.index ["associated_type", "associated_id"], name: "associated_index"
    t.index ["auditable_type", "auditable_id", "version"], name: "auditable_index"
    t.index ["created_at"], name: "index_audits_on_created_at"
    t.index ["placement_version"], name: "index_audits_on_placement_version"
    t.index ["request_uuid"], name: "index_audits_on_request_uuid"
    t.index ["user_id", "user_type"], name: "user_index"
  end

  create_table "dummy_blog_articles", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "featured"
    t.string "locale", default: "cs"
    t.text "meta_description"
    t.string "meta_title"
    t.text "perex"
    t.string "preview_token"
    t.boolean "published"
    t.datetime "published_at"
    t.bigint "site_id"
    t.string "slug"
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["featured"], name: "index_dummy_blog_articles_on_featured"
    t.index ["locale"], name: "index_dummy_blog_articles_on_locale"
    t.index ["published"], name: "index_dummy_blog_articles_on_published"
    t.index ["published_at"], name: "index_dummy_blog_articles_on_published_at"
    t.index ["site_id"], name: "index_dummy_blog_articles_on_site_id"
    t.index ["slug"], name: "index_dummy_blog_articles_on_slug"
  end

  create_table "dummy_blog_author_article_links", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "dummy_blog_article_id"
    t.bigint "dummy_blog_author_id"
    t.integer "position"
    t.datetime "updated_at", null: false
    t.index ["dummy_blog_article_id"], name: "dummy_blog_author_article_links_a_id"
    t.index ["dummy_blog_author_id"], name: "dummy_blog_author_article_links_t_id"
    t.index ["position"], name: "index_dummy_blog_author_article_links_on_position"
  end

  create_table "dummy_blog_authors", force: :cascade do |t|
    t.integer "articles_count", default: 0
    t.datetime "created_at", null: false
    t.boolean "featured"
    t.string "first_name"
    t.string "job"
    t.string "last_name"
    t.string "locale", default: "cs"
    t.text "meta_description"
    t.string "meta_title"
    t.text "perex"
    t.integer "position"
    t.string "preview_token"
    t.boolean "published"
    t.bigint "site_id"
    t.string "slug"
    t.jsonb "social_links"
    t.datetime "updated_at", null: false
    t.index ["featured"], name: "index_dummy_blog_authors_on_featured"
    t.index ["locale"], name: "index_dummy_blog_authors_on_locale"
    t.index ["position"], name: "index_dummy_blog_authors_on_position"
    t.index ["published"], name: "index_dummy_blog_authors_on_published"
    t.index ["site_id"], name: "index_dummy_blog_authors_on_site_id"
    t.index ["slug"], name: "index_dummy_blog_authors_on_slug"
  end

  create_table "dummy_blog_localized_articles", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "locale"
    t.integer "site_id"
    t.string "slug"
    t.string "slug_cs"
    t.string "slug_en"
    t.string "title"
    t.string "title_cs"
    t.string "title_en"
    t.datetime "updated_at", null: false
  end

  create_table "dummy_blog_localized_pages", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "locale"
    t.integer "site_id"
    t.string "slug"
    t.string "slug_cs"
    t.string "slug_en"
    t.string "title"
    t.string "title_cs"
    t.string "title_en"
    t.datetime "updated_at", null: false
  end

  create_table "dummy_blog_topic_article_links", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "dummy_blog_article_id"
    t.bigint "dummy_blog_topic_id"
    t.integer "position"
    t.datetime "updated_at", null: false
    t.index ["dummy_blog_article_id"], name: "dummy_blog_topic_article_links_a_id"
    t.index ["dummy_blog_topic_id"], name: "dummy_blog_topic_article_links_t_id"
    t.index ["position"], name: "index_dummy_blog_topic_article_links_on_position"
  end

  create_table "dummy_blog_topics", force: :cascade do |t|
    t.integer "articles_count", default: 0
    t.datetime "created_at", null: false
    t.boolean "featured"
    t.string "locale", default: "cs"
    t.text "meta_description"
    t.string "meta_title"
    t.text "perex"
    t.integer "position"
    t.string "preview_token"
    t.boolean "published"
    t.bigint "site_id"
    t.string "slug"
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["featured"], name: "index_dummy_blog_topics_on_featured"
    t.index ["locale"], name: "index_dummy_blog_topics_on_locale"
    t.index ["position"], name: "index_dummy_blog_topics_on_position"
    t.index ["published"], name: "index_dummy_blog_topics_on_published"
    t.index ["site_id"], name: "index_dummy_blog_topics_on_site_id"
    t.index ["slug"], name: "index_dummy_blog_topics_on_slug"
  end

  create_table "dummy_test_records", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "published"
    t.datetime "published_at"
    t.datetime "published_from"
    t.datetime "published_until"
    t.string "title"
    t.datetime "updated_at", null: false
  end

  create_table "folio_addresses", force: :cascade do |t|
    t.string "address_line_1"
    t.string "address_line_2"
    t.string "city"
    t.string "company_name"
    t.string "country_code"
    t.datetime "created_at", null: false
    t.string "email"
    t.string "identification_number"
    t.string "name"
    t.string "phone"
    t.string "state"
    t.string "type"
    t.datetime "updated_at", null: false
    t.string "vat_identification_number"
    t.string "zip"
    t.index ["type"], name: "index_folio_addresses_on_type"
  end

  create_table "folio_atoms", force: :cascade do |t|
    t.jsonb "associations", default: {}
    t.datetime "created_at", precision: nil, null: false
    t.jsonb "data", default: {}
    t.string "locale"
    t.bigint "placement_id"
    t.string "placement_type"
    t.integer "position"
    t.string "type"
    t.datetime "updated_at", precision: nil, null: false
    t.index ["placement_type", "placement_id"], name: "index_folio_atoms_on_placement_type_and_placement_id"
  end

  create_table "folio_attribute_types", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "data_type", default: "string"
    t.integer "folio_attributes_count"
    t.integer "position"
    t.bigint "site_id"
    t.string "title"
    t.string "type"
    t.datetime "updated_at", null: false
    t.index ["folio_attributes_count"], name: "index_folio_attribute_types_on_folio_attributes_count"
    t.index ["position"], name: "index_folio_attribute_types_on_position"
    t.index ["site_id"], name: "index_folio_attribute_types_on_site_id"
    t.index ["type"], name: "index_folio_attribute_types_on_type"
  end

  create_table "folio_attributes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "folio_attribute_type_id"
    t.bigint "placement_id"
    t.string "placement_type"
    t.datetime "updated_at", null: false
    t.string "value"
    t.index ["folio_attribute_type_id"], name: "index_folio_attributes_on_folio_attribute_type_id"
    t.index ["placement_type", "placement_id"], name: "index_folio_attributes_on_placement"
  end

  create_table "folio_cache_versions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at"
    t.jsonb "invalidation_metadata"
    t.string "key", null: false
    t.bigint "site_id", null: false
    t.datetime "updated_at", null: false
    t.index ["site_id", "key"], name: "index_folio_cache_versions_on_site_id_and_key", unique: true
    t.index ["site_id"], name: "index_folio_cache_versions_on_site_id"
  end

  create_table "folio_console_notes", force: :cascade do |t|
    t.datetime "closed_at", precision: nil
    t.bigint "closed_by_id"
    t.text "content"
    t.datetime "created_at", null: false
    t.bigint "created_by_id"
    t.datetime "due_at", precision: nil
    t.integer "position"
    t.bigint "site_id", null: false
    t.bigint "target_id"
    t.string "target_type"
    t.datetime "updated_at", null: false
    t.index ["closed_by_id"], name: "index_folio_console_notes_on_closed_by_id"
    t.index ["created_by_id"], name: "index_folio_console_notes_on_created_by_id"
    t.index ["site_id"], name: "index_folio_console_notes_on_site_id"
    t.index ["target_type", "target_id"], name: "index_folio_console_notes_on_target"
  end

  create_table "folio_content_templates", force: :cascade do |t|
    t.text "content"
    t.datetime "created_at", precision: nil, null: false
    t.integer "position"
    t.bigint "site_id"
    t.string "title"
    t.string "type"
    t.datetime "updated_at", precision: nil, null: false
    t.index ["position"], name: "index_folio_content_templates_on_position"
    t.index ["site_id"], name: "index_folio_content_templates_on_site_id"
    t.index ["type"], name: "index_folio_content_templates_on_type"
  end

  create_table "folio_email_templates", force: :cascade do |t|
    t.string "action"
    t.boolean "active", default: true
    t.text "body_html_cs"
    t.text "body_html_en"
    t.text "body_text_cs"
    t.text "body_text_en"
    t.datetime "created_at", null: false
    t.string "mailer"
    t.jsonb "optional_keywords"
    t.jsonb "required_keywords"
    t.bigint "site_id"
    t.string "slug"
    t.string "subject_cs"
    t.string "subject_en"
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["site_id"], name: "index_folio_email_templates_on_site_id"
    t.index ["slug"], name: "index_folio_email_templates_on_slug"
  end

  create_table "folio_file_placements", force: :cascade do |t|
    t.string "alt"
    t.datetime "created_at", precision: nil, null: false
    t.text "description"
    t.bigint "file_id"
    t.jsonb "folio_embed_data"
    t.bigint "placement_id"
    t.string "placement_title"
    t.string "placement_title_type"
    t.string "placement_type"
    t.integer "position"
    t.text "title"
    t.string "type"
    t.datetime "updated_at", precision: nil, null: false
    t.index ["file_id"], name: "index_folio_file_placements_on_file_id"
    t.index ["placement_title"], name: "index_folio_file_placements_on_placement_title"
    t.index ["placement_title_type"], name: "index_folio_file_placements_on_placement_title_type"
    t.index ["placement_type", "placement_id"], name: "index_folio_file_placements_on_placement_type_and_placement_id"
    t.index ["type"], name: "index_folio_file_placements_on_type"
  end

  create_table "folio_file_site_links", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "file_id", null: false
    t.bigint "site_id", null: false
    t.datetime "updated_at", null: false
    t.index ["file_id", "site_id"], name: "index_folio_file_site_links_unique", unique: true
    t.index ["file_id"], name: "index_folio_file_site_links_on_file_id"
    t.index ["site_id"], name: "index_folio_file_site_links_on_site_id"
  end

  create_table "folio_files", force: :cascade do |t|
    t.string "aasm_state"
    t.json "additional_data"
    t.string "alt"
    t.string "attribution_copyright"
    t.string "attribution_licence"
    t.integer "attribution_max_usage_count"
    t.string "attribution_source"
    t.string "attribution_source_url"
    t.string "author"
    t.datetime "capture_date"
    t.datetime "created_at", precision: nil, null: false
    t.bigint "created_by_folio_user_id"
    t.string "default_gravity"
    t.text "description"
    t.integer "file_height"
    t.json "file_metadata"
    t.datetime "file_metadata_extracted_at"
    t.string "file_mime_type"
    t.string "file_name"
    t.string "file_name_for_search"
    t.integer "file_placements_count", default: 0, null: false
    t.bigint "file_size"
    t.integer "file_track_duration"
    t.string "file_uid"
    t.integer "file_width"
    t.decimal "gps_latitude", precision: 10, scale: 6
    t.decimal "gps_longitude", precision: 10, scale: 6
    t.string "headline"
    t.bigint "media_source_id"
    t.integer "preview_track_duration_in_seconds"
    t.integer "published_usage_count", default: 0, null: false
    t.json "remote_services_data", default: {}
    t.boolean "sensitive_content", default: false
    t.bigint "site_id", null: false
    t.string "slug"
    t.jsonb "thumbnail_configuration"
    t.text "thumbnail_sizes", default: "--- {}\n"
    t.string "type"
    t.datetime "updated_at", precision: nil, null: false
    t.index "(((to_tsvector('simple'::regconfig, folio_unaccent(COALESCE((file_name_for_search)::text, ''::text))) || to_tsvector('simple'::regconfig, folio_unaccent(COALESCE((headline)::text, ''::text)))) || to_tsvector('simple'::regconfig, folio_unaccent(COALESCE(description, ''::text)))))", name: "index_folio_files_on_by_label_query", using: :gin
    t.index "to_tsvector('simple'::regconfig, folio_unaccent(COALESCE((author)::text, ''::text)))", name: "index_folio_files_on_by_author", using: :gin
    t.index "to_tsvector('simple'::regconfig, folio_unaccent(COALESCE((file_name)::text, ''::text)))", name: "index_folio_files_on_by_file_name", using: :gin
    t.index "to_tsvector('simple'::regconfig, folio_unaccent(COALESCE((file_name_for_search)::text, ''::text)))", name: "index_folio_files_on_by_file_name_for_search", using: :gin
    t.index ["created_at"], name: "index_folio_files_on_created_at"
    t.index ["created_by_folio_user_id"], name: "index_folio_files_on_created_by_folio_user_id"
    t.index ["file_name"], name: "index_folio_files_on_file_name"
    t.index ["media_source_id"], name: "index_folio_files_on_media_source_id"
    t.index ["published_usage_count"], name: "index_folio_files_on_published_usage_count"
    t.index ["site_id"], name: "index_folio_files_on_site_id"
    t.index ["slug"], name: "index_folio_files_on_slug_unique", unique: true
    t.index ["type"], name: "index_folio_files_on_type"
    t.index ["updated_at"], name: "index_folio_files_on_updated_at"
  end

  create_table "folio_leads", force: :cascade do |t|
    t.string "aasm_state", default: "submitted"
    t.json "additional_data"
    t.datetime "created_at", precision: nil, null: false
    t.string "email"
    t.string "name"
    t.text "note"
    t.string "phone"
    t.bigint "site_id"
    t.datetime "updated_at", precision: nil, null: false
    t.string "url"
    t.index ["site_id"], name: "index_folio_leads_on_site_id"
  end

  create_table "folio_media_source_site_links", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "media_source_id", null: false
    t.bigint "site_id", null: false
    t.datetime "updated_at", null: false
    t.index ["media_source_id", "site_id"], name: "index_folio_media_source_site_links_unique", unique: true
    t.index ["media_source_id"], name: "index_folio_media_source_site_links_on_media_source_id"
    t.index ["site_id"], name: "index_folio_media_source_site_links_on_site_id"
  end

  create_table "folio_media_sources", force: :cascade do |t|
    t.string "copyright_text"
    t.datetime "created_at", null: false
    t.string "licence"
    t.integer "max_usage_count", default: 1
    t.bigint "site_id", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["site_id"], name: "index_folio_media_sources_on_site_id"
    t.index ["title"], name: "index_folio_media_sources_on_title", unique: true
  end

  create_table "folio_menu_items", force: :cascade do |t|
    t.string "ancestry"
    t.datetime "created_at", precision: nil, null: false
    t.integer "folio_page_id"
    t.bigint "menu_id"
    t.boolean "open_in_new"
    t.integer "position"
    t.string "rails_path"
    t.string "style"
    t.bigint "target_id"
    t.string "target_type"
    t.string "title"
    t.datetime "updated_at", precision: nil, null: false
    t.string "url"
    t.index ["ancestry"], name: "index_folio_menu_items_on_ancestry"
    t.index ["menu_id"], name: "index_folio_menu_items_on_menu_id"
    t.index ["target_type", "target_id"], name: "index_folio_menu_items_on_target_type_and_target_id"
  end

  create_table "folio_menus", force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.string "locale"
    t.bigint "site_id"
    t.string "title"
    t.string "type"
    t.datetime "updated_at", precision: nil, null: false
    t.index ["site_id"], name: "index_folio_menus_on_site_id"
    t.index ["type"], name: "index_folio_menus_on_type"
  end

  create_table "folio_newsletter_subscriptions", force: :cascade do |t|
    t.boolean "active", default: true
    t.datetime "created_at", precision: nil, null: false
    t.string "email"
    t.text "merge_vars"
    t.bigint "site_id"
    t.bigint "subscribable_id"
    t.string "subscribable_type"
    t.string "tags"
    t.datetime "updated_at", precision: nil, null: false
    t.index ["site_id"], name: "index_folio_newsletter_subscriptions_on_site_id"
    t.index ["subscribable_type", "subscribable_id"], name: "index_folio_newsletter_subscriptions_on_subscribable"
  end

  create_table "folio_omniauth_authentications", force: :cascade do |t|
    t.string "access_token"
    t.string "conflict_token"
    t.integer "conflict_user_id"
    t.datetime "created_at", null: false
    t.string "email"
    t.bigint "folio_user_id"
    t.string "nickname"
    t.string "provider"
    t.json "raw_info"
    t.string "uid"
    t.datetime "updated_at", null: false
    t.index ["folio_user_id"], name: "index_folio_omniauth_authentications_on_folio_user_id"
  end

  create_table "folio_pages", force: :cascade do |t|
    t.string "ancestry"
    t.string "ancestry_slug"
    t.text "atoms_data_for_search"
    t.datetime "created_at", precision: nil, null: false
    t.string "locale", limit: 6
    t.text "meta_description"
    t.string "meta_title", limit: 512
    t.integer "original_id"
    t.text "perex"
    t.integer "position"
    t.string "preview_token"
    t.boolean "published"
    t.datetime "published_at", precision: nil
    t.bigint "site_id"
    t.string "slug"
    t.jsonb "tiptap_content"
    t.string "title"
    t.string "type"
    t.datetime "updated_at", precision: nil, null: false
    t.index "(((setweight(to_tsvector('simple'::regconfig, folio_unaccent(COALESCE((title)::text, ''::text))), 'A'::\"char\") || setweight(to_tsvector('simple'::regconfig, folio_unaccent(COALESCE(perex, ''::text))), 'B'::\"char\")) || setweight(to_tsvector('simple'::regconfig, folio_unaccent(COALESCE(atoms_data_for_search, ''::text))), 'C'::\"char\")))", name: "index_folio_pages_on_by_query", using: :gin
    t.index ["ancestry"], name: "index_folio_pages_on_ancestry"
    t.index ["locale"], name: "index_folio_pages_on_locale"
    t.index ["original_id"], name: "index_folio_pages_on_original_id"
    t.index ["position"], name: "index_folio_pages_on_position"
    t.index ["published"], name: "index_folio_pages_on_published"
    t.index ["published_at"], name: "index_folio_pages_on_published_at"
    t.index ["site_id"], name: "index_folio_pages_on_site_id"
    t.index ["slug"], name: "index_folio_pages_on_slug"
    t.index ["type"], name: "index_folio_pages_on_type"
  end

  create_table "folio_private_attachments", force: :cascade do |t|
    t.json "additional_data"
    t.string "alt"
    t.bigint "attachmentable_id"
    t.string "attachmentable_type"
    t.datetime "created_at", precision: nil, null: false
    t.integer "file_height"
    t.string "file_mime_type"
    t.string "file_name"
    t.bigint "file_size"
    t.string "file_uid"
    t.integer "file_width"
    t.string "hash_id"
    t.integer "position"
    t.text "thumbnail_sizes", default: "--- {}\n"
    t.text "title"
    t.string "type"
    t.datetime "updated_at", precision: nil, null: false
    t.index ["attachmentable_type", "attachmentable_id"], name: "index_folio_private_attachments_on_attachmentable"
    t.index ["type"], name: "index_folio_private_attachments_on_type"
  end

  create_table "folio_session_attachments", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "file_height"
    t.string "file_mime_type"
    t.string "file_name"
    t.bigint "file_size"
    t.string "file_uid"
    t.integer "file_width"
    t.string "hash_id"
    t.bigint "placement_id"
    t.string "placement_type"
    t.json "thumbnail_sizes", default: {}
    t.string "type"
    t.datetime "updated_at", null: false
    t.string "web_session_id"
    t.index ["hash_id"], name: "index_folio_session_attachments_on_hash_id"
    t.index ["placement_type", "placement_id"], name: "index_folio_session_attachments_on_placement"
    t.index ["type"], name: "index_folio_session_attachments_on_type"
    t.index ["web_session_id"], name: "index_folio_session_attachments_on_web_session_id"
  end

  create_table "folio_site_user_links", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "locked_at"
    t.jsonb "roles", default: []
    t.bigint "site_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["site_id"], name: "index_folio_site_user_links_on_site_id"
    t.index ["user_id"], name: "index_folio_site_user_links_on_user_id"
  end

  create_table "folio_sites", force: :cascade do |t|
    t.text "address"
    t.text "address_secondary"
    t.jsonb "available_user_roles", default: ["administrator", "manager"]
    t.string "copyright_info_source"
    t.datetime "created_at", precision: nil, null: false
    t.text "description"
    t.string "domain"
    t.string "email"
    t.string "email_from"
    t.string "facebook_pixel_code"
    t.string "google_analytics_tracking_code"
    t.string "google_analytics_tracking_code_v4"
    t.text "header_message"
    t.boolean "header_message_published", default: false
    t.datetime "header_message_published_from", precision: nil
    t.datetime "header_message_published_until", precision: nil
    t.string "locale"
    t.string "locales", default: [], array: true
    t.string "phone"
    t.string "phone_secondary"
    t.integer "position"
    t.string "slug"
    t.json "social_links"
    t.boolean "subtitle_auto_generation_enabled", default: false
    t.jsonb "subtitle_languages", default: ["cs"]
    t.string "system_email"
    t.string "system_email_copy"
    t.string "title"
    t.string "type"
    t.datetime "updated_at", precision: nil, null: false
    t.index ["domain"], name: "index_folio_sites_on_domain"
    t.index ["position"], name: "index_folio_sites_on_position"
    t.index ["slug"], name: "index_folio_sites_on_slug"
    t.index ["subtitle_languages"], name: "index_folio_sites_on_subtitle_languages", using: :gin
    t.index ["type"], name: "index_folio_sites_on_type"
  end

  create_table "folio_tiptap_revisions", force: :cascade do |t|
    t.string "attribute_name", default: "tiptap_content", null: false
    t.jsonb "content", null: false
    t.datetime "created_at", null: false
    t.bigint "placement_id", null: false
    t.string "placement_type", null: false
    t.bigint "superseded_by_user_id"
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["placement_type", "placement_id"], name: "index_folio_tiptap_revisions_on_placement"
    t.index ["superseded_by_user_id"], name: "index_folio_tiptap_revisions_on_superseded_by_user_id"
    t.index ["user_id"], name: "index_folio_tiptap_revisions_on_user_id"
  end

  create_table "folio_users", force: :cascade do |t|
    t.text "admin_note"
    t.bigint "auth_site_id", null: false
    t.string "bank_account_number"
    t.date "born_at"
    t.string "company_name"
    t.datetime "confirmation_sent_at", precision: nil
    t.string "confirmation_token"
    t.datetime "confirmed_at", precision: nil
    t.jsonb "console_preferences"
    t.string "console_url"
    t.datetime "console_url_updated_at"
    t.datetime "created_at", null: false
    t.datetime "crossdomain_devise_set_at"
    t.string "crossdomain_devise_token"
    t.datetime "current_sign_in_at", precision: nil
    t.inet "current_sign_in_ip"
    t.string "degree_post", limit: 32
    t.string "degree_pre", limit: 32
    t.string "email"
    t.string "encrypted_password", default: "", null: false
    t.integer "failed_attempts", default: 0, null: false
    t.string "first_name"
    t.boolean "has_generated_password", default: false
    t.datetime "invitation_accepted_at", precision: nil
    t.datetime "invitation_created_at", precision: nil
    t.integer "invitation_limit"
    t.datetime "invitation_sent_at", precision: nil
    t.string "invitation_token"
    t.integer "invitations_count", default: 0
    t.bigint "invited_by_id"
    t.string "invited_by_type"
    t.string "last_name"
    t.datetime "last_sign_in_at", precision: nil
    t.inet "last_sign_in_ip"
    t.datetime "locked_at"
    t.string "nickname"
    t.string "phone"
    t.string "phone_secondary"
    t.string "preferred_locale"
    t.bigint "primary_address_id"
    t.datetime "remember_created_at", precision: nil
    t.datetime "reset_password_sent_at", precision: nil
    t.string "reset_password_token"
    t.bigint "secondary_address_id"
    t.integer "sign_in_count", default: 0, null: false
    t.string "sign_out_salt_part"
    t.bigint "source_site_id"
    t.boolean "subscribed_to_newsletter", default: false
    t.boolean "superadmin", default: false, null: false
    t.string "time_zone", default: "Prague"
    t.string "unconfirmed_email"
    t.string "unlock_token"
    t.datetime "updated_at", null: false
    t.boolean "use_secondary_address", default: false
    t.index ["auth_site_id"], name: "index_folio_users_on_auth_site_id"
    t.index ["confirmation_token"], name: "index_folio_users_on_confirmation_token", unique: true
    t.index ["crossdomain_devise_token"], name: "index_folio_users_on_crossdomain_devise_token"
    t.index ["email"], name: "index_folio_users_on_email"
    t.index ["invitation_token"], name: "index_folio_users_on_invitation_token", unique: true
    t.index ["invited_by_id"], name: "index_folio_users_on_invited_by_id"
    t.index ["invited_by_type", "invited_by_id"], name: "index_folio_users_on_invited_by_type_and_invited_by_id"
    t.index ["primary_address_id"], name: "index_folio_users_on_primary_address_id"
    t.index ["reset_password_token"], name: "index_folio_users_on_reset_password_token", unique: true
    t.index ["secondary_address_id"], name: "index_folio_users_on_secondary_address_id"
    t.index ["source_site_id"], name: "index_folio_users_on_source_site_id"
  end

  create_table "folio_video_subtitles", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "enabled", default: false
    t.string "format", default: "vtt"
    t.string "language", null: false
    t.jsonb "metadata", default: {}
    t.text "text"
    t.datetime "updated_at", null: false
    t.bigint "video_id", null: false
    t.index ["enabled"], name: "index_folio_video_subtitles_on_enabled"
    t.index ["language"], name: "index_folio_video_subtitles_on_language"
    t.index ["metadata"], name: "index_folio_video_subtitles_on_metadata", using: :gin
    t.index ["video_id", "language"], name: "index_folio_video_subtitles_on_video_id_and_language", unique: true
    t.index ["video_id"], name: "index_folio_video_subtitles_on_video_id"
  end

  create_table "friendly_id_slugs", force: :cascade do |t|
    t.datetime "created_at", precision: nil
    t.string "scope"
    t.string "slug", null: false
    t.integer "sluggable_id", null: false
    t.string "sluggable_type", limit: 50
    t.index ["slug", "sluggable_type", "scope"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type_and_scope", unique: true
    t.index ["slug", "sluggable_type"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type"
    t.index ["sluggable_id"], name: "index_friendly_id_slugs_on_sluggable_id"
    t.index ["sluggable_type"], name: "index_friendly_id_slugs_on_sluggable_type"
  end

  create_table "pg_search_documents", force: :cascade do |t|
    t.text "content"
    t.datetime "created_at", precision: nil, null: false
    t.bigint "searchable_id"
    t.string "searchable_type"
    t.datetime "updated_at", precision: nil, null: false
    t.index "to_tsvector('simple'::regconfig, folio_unaccent(COALESCE(content, ''::text)))", name: "index_pg_search_documents_on_public_search", using: :gin
    t.index ["searchable_type", "searchable_id"], name: "index_pg_search_documents_on_searchable_type_and_searchable_id"
  end

  create_table "taggings", id: :serial, force: :cascade do |t|
    t.string "context", limit: 128
    t.datetime "created_at", precision: nil
    t.integer "tag_id"
    t.integer "taggable_id"
    t.string "taggable_type"
    t.integer "tagger_id"
    t.string "tagger_type"
    t.string "tenant", limit: 128
    t.index ["context"], name: "index_taggings_on_context"
    t.index ["tag_id", "taggable_id", "taggable_type", "context", "tagger_id", "tagger_type"], name: "taggings_idx", unique: true
    t.index ["tag_id"], name: "index_taggings_on_tag_id"
    t.index ["taggable_id", "taggable_type", "context"], name: "index_taggings_on_taggable_id_and_taggable_type_and_context"
    t.index ["taggable_id", "taggable_type", "tagger_id", "context"], name: "taggings_idy"
    t.index ["taggable_id"], name: "index_taggings_on_taggable_id"
    t.index ["taggable_type"], name: "index_taggings_on_taggable_type"
    t.index ["tagger_id", "tagger_type"], name: "index_taggings_on_tagger_id_and_tagger_type"
    t.index ["tagger_id"], name: "index_taggings_on_tagger_id"
    t.index ["tenant"], name: "index_taggings_on_tenant"
  end

  create_table "tags", id: :serial, force: :cascade do |t|
    t.string "name"
    t.integer "taggings_count", default: 0
    t.index "to_tsvector('simple'::regconfig, folio_unaccent(COALESCE((name)::text, ''::text)))", name: "index_tags_on_by_query", using: :gin
    t.index ["name"], name: "index_tags_on_name", unique: true
  end

  add_foreign_key "folio_console_notes", "folio_sites", column: "site_id"
  add_foreign_key "folio_content_templates", "folio_sites", column: "site_id"
  add_foreign_key "folio_file_site_links", "folio_files", column: "file_id"
  add_foreign_key "folio_file_site_links", "folio_sites", column: "site_id"
  add_foreign_key "folio_files", "folio_media_sources", column: "media_source_id"
  add_foreign_key "folio_files", "folio_sites", column: "site_id"
  add_foreign_key "folio_files", "folio_users", column: "created_by_folio_user_id", on_delete: :nullify
  add_foreign_key "folio_media_source_site_links", "folio_media_sources", column: "media_source_id"
  add_foreign_key "folio_media_source_site_links", "folio_sites", column: "site_id"
  add_foreign_key "folio_media_sources", "folio_sites", column: "site_id"
  add_foreign_key "folio_site_user_links", "folio_sites", column: "site_id"
  add_foreign_key "folio_site_user_links", "folio_users", column: "user_id"
  add_foreign_key "folio_tiptap_revisions", "folio_users", column: "superseded_by_user_id"
  add_foreign_key "folio_tiptap_revisions", "folio_users", column: "user_id"
  add_foreign_key "folio_users", "folio_sites", column: "auth_site_id"
  add_foreign_key "folio_video_subtitles", "folio_files", column: "video_id"
end
