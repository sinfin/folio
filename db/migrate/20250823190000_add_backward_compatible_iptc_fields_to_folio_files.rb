# frozen_string_literal: true

class AddBackwardCompatibleIptcFieldsToFolioFiles < ActiveRecord::Migration[7.1]
  def up
    # 1. SAFELY rename existing fields to keep as backup
    # Only rename if columns exist to handle fresh installs
    if column_exists?(:folio_files, :author) && !column_exists?(:folio_files, :author_legacy)
      rename_column :folio_files, :author, :author_legacy
    end

    if column_exists?(:folio_files, :alt) && !column_exists?(:folio_files, :alt_legacy)
      rename_column :folio_files, :alt, :alt_legacy
    end

    # Keep description as-is since it maps to IPTC description
    # We'll use aliases for backward compatibility

    # 2. Add new IPTC-compliant fields
    # Core descriptive fields
    add_column :folio_files, :headline, :string unless column_exists?(:folio_files, :headline)
    add_column :folio_files, :creator, :jsonb, default: [] unless column_exists?(:folio_files, :creator)
    add_column :folio_files, :caption_writer, :string unless column_exists?(:folio_files, :caption_writer)
    add_column :folio_files, :credit_line, :string unless column_exists?(:folio_files, :credit_line)
    add_column :folio_files, :source, :string unless column_exists?(:folio_files, :source)

    # Rights management
    add_column :folio_files, :copyright_notice, :text unless column_exists?(:folio_files, :copyright_notice)
    add_column :folio_files, :copyright_marked, :boolean, default: false unless column_exists?(:folio_files, :copyright_marked)
    add_column :folio_files, :usage_terms, :text unless column_exists?(:folio_files, :usage_terms)
    add_column :folio_files, :rights_usage_info, :string unless column_exists?(:folio_files, :rights_usage_info)

    # Classification (JSONB arrays for multi-value fields)
    add_column :folio_files, :keywords, :jsonb, default: [] unless column_exists?(:folio_files, :keywords)
    add_column :folio_files, :intellectual_genre, :string unless column_exists?(:folio_files, :intellectual_genre)
    add_column :folio_files, :subject_codes, :jsonb, default: [] unless column_exists?(:folio_files, :subject_codes)
    add_column :folio_files, :scene_codes, :jsonb, default: [] unless column_exists?(:folio_files, :scene_codes)
    add_column :folio_files, :event, :string unless column_exists?(:folio_files, :event)

    # Legacy fields (for backwards compatibility)
    add_column :folio_files, :category, :string unless column_exists?(:folio_files, :category)
    add_column :folio_files, :urgency, :integer unless column_exists?(:folio_files, :urgency)

    # People and objects (JSONB arrays)
    add_column :folio_files, :persons_shown, :jsonb, default: [] unless column_exists?(:folio_files, :persons_shown)
    add_column :folio_files, :persons_shown_details, :jsonb, default: [] unless column_exists?(:folio_files, :persons_shown_details)
    add_column :folio_files, :organizations_shown, :jsonb, default: [] unless column_exists?(:folio_files, :organizations_shown)

    # Location data
    add_column :folio_files, :location_created, :jsonb, default: [] unless column_exists?(:folio_files, :location_created)
    add_column :folio_files, :location_shown, :jsonb, default: [] unless column_exists?(:folio_files, :location_shown)
    add_column :folio_files, :sublocation, :string unless column_exists?(:folio_files, :sublocation)
    add_column :folio_files, :city, :string unless column_exists?(:folio_files, :city)
    add_column :folio_files, :state_province, :string unless column_exists?(:folio_files, :state_province)
    add_column :folio_files, :country, :string unless column_exists?(:folio_files, :country)
    add_column :folio_files, :country_code, :string, limit: 2 unless column_exists?(:folio_files, :country_code)

    # Technical metadata
    add_column :folio_files, :camera_make, :string unless column_exists?(:folio_files, :camera_make)
    add_column :folio_files, :camera_model, :string unless column_exists?(:folio_files, :camera_model)
    add_column :folio_files, :lens_info, :string unless column_exists?(:folio_files, :lens_info)
    add_column :folio_files, :capture_date, :datetime unless column_exists?(:folio_files, :capture_date)
    add_column :folio_files, :capture_date_offset, :string unless column_exists?(:folio_files, :capture_date_offset)
    add_column :folio_files, :gps_latitude, :decimal, precision: 10, scale: 6 unless column_exists?(:folio_files, :gps_latitude)
    add_column :folio_files, :gps_longitude, :decimal, precision: 10, scale: 6 unless column_exists?(:folio_files, :gps_longitude)
    add_column :folio_files, :orientation, :integer unless column_exists?(:folio_files, :orientation)

    # Re-add alt field as new IPTC field (will be populated by rake task)
    add_column :folio_files, :alt, :string unless column_exists?(:folio_files, :alt)

    # Re-add author field as string (will be populated by rake task for BC)
    add_column :folio_files, :author, :string unless column_exists?(:folio_files, :author)

    # Tracking field
    add_column :folio_files, :file_metadata_extracted_at, :datetime unless column_exists?(:folio_files, :file_metadata_extracted_at)

    # 3. Add indexes for common searches (GIN for JSONB arrays)
    add_index :folio_files, :creator, using: :gin unless index_exists?(:folio_files, :creator)
    add_index :folio_files, :keywords, using: :gin unless index_exists?(:folio_files, :keywords)
    add_index :folio_files, :subject_codes, using: :gin unless index_exists?(:folio_files, :subject_codes)
    add_index :folio_files, :persons_shown, using: :gin unless index_exists?(:folio_files, :persons_shown)
    add_index :folio_files, :source unless index_exists?(:folio_files, :source)
    add_index :folio_files, :country_code unless index_exists?(:folio_files, :country_code)
    add_index :folio_files, :capture_date unless index_exists?(:folio_files, :capture_date)
    add_index :folio_files, [:gps_latitude, :gps_longitude] unless index_exists?(:folio_files, [:gps_latitude, :gps_longitude])
    add_index :folio_files, :file_metadata_extracted_at unless index_exists?(:folio_files, :file_metadata_extracted_at)

    puts ""
    puts "=" * 80
    puts "IMPORTANT: IPTC Fields Migration Completed"
    puts "=" * 80
    puts ""
    puts "✅ Old fields safely renamed to *_legacy (preserved as backup)"
    puts "✅ New IPTC-compliant fields added"
    puts "✅ Backward compatibility maintained through model aliases"
    puts ""
    puts "🔧 NEXT STEPS:"
    puts "   Run data migration: rails folio:developer_tools:migrate_legacy_metadata"
    puts "   This will:"
    puts "   - Copy author_legacy -> author (string) + creator (JSONB array)"
    puts "   - Copy alt_legacy -> alt"
    puts "   - No metadata extraction will be triggered"
    puts ""
    puts "💡 TIP: Old columns (*_legacy) are kept as backup and won't be used"
    puts "=" * 80
  end

  def down
    # Safe rollback - restore original schema
    if column_exists?(:folio_files, :author_legacy)
      remove_column :folio_files, :author if column_exists?(:folio_files, :author)
      rename_column :folio_files, :author_legacy, :author
    end

    if column_exists?(:folio_files, :alt_legacy)
      remove_column :folio_files, :alt if column_exists?(:folio_files, :alt)
      rename_column :folio_files, :alt_legacy, :alt
    end

    # Remove all IPTC fields
    iptc_columns = [
      :headline, :creator, :caption_writer, :credit_line, :source,
      :copyright_notice, :copyright_marked, :usage_terms, :rights_usage_info,
      :keywords, :intellectual_genre, :subject_codes, :scene_codes, :event,
      :category, :urgency, :persons_shown, :persons_shown_details, :organizations_shown,
      :location_created, :location_shown, :sublocation, :city, :state_province,
      :country, :country_code, :camera_make, :camera_model, :lens_info,
      :capture_date, :capture_date_offset, :gps_latitude, :gps_longitude,
      :orientation, :file_metadata_extracted_at
    ]

    iptc_columns.each do |column|
      remove_column :folio_files, column if column_exists?(:folio_files, column)
    end

    # Remove indexes
    remove_index :folio_files, :creator if index_exists?(:folio_files, :creator)
    remove_index :folio_files, :keywords if index_exists?(:folio_files, :keywords)
    remove_index :folio_files, :subject_codes if index_exists?(:folio_files, :subject_codes)
    remove_index :folio_files, :persons_shown if index_exists?(:folio_files, :persons_shown)
    remove_index :folio_files, :source if index_exists?(:folio_files, :source)
    remove_index :folio_files, :country_code if index_exists?(:folio_files, :country_code)
    remove_index :folio_files, :capture_date if index_exists?(:folio_files, :capture_date)
    remove_index :folio_files, [:gps_latitude, :gps_longitude] if index_exists?(:folio_files, [:gps_latitude, :gps_longitude])
    remove_index :folio_files, :file_metadata_extracted_at if index_exists?(:folio_files, :file_metadata_extracted_at)
  end
end
