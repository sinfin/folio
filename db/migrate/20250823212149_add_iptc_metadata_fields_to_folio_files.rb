# frozen_string_literal: true

class AddIptcMetadataFieldsToFolioFiles < ActiveRecord::Migration[7.1]
  def change
    # Core descriptive fields (IPTC Core) - skip existing columns
    add_column :folio_files, :description, :text unless column_exists?(:folio_files, :description)
    add_column :folio_files, :caption_writer, :string unless column_exists?(:folio_files, :caption_writer)
    add_column :folio_files, :credit_line, :string unless column_exists?(:folio_files, :credit_line)
    add_column :folio_files, :source, :string unless column_exists?(:folio_files, :source)
    add_column :folio_files, :copyright_notice, :text unless column_exists?(:folio_files, :copyright_notice)
    add_column :folio_files, :rights_usage_terms, :text unless column_exists?(:folio_files, :rights_usage_terms)
    add_column :folio_files, :web_statement, :string unless column_exists?(:folio_files, :web_statement)
    
    # Keywords and categorization - skip existing columns
    add_column :folio_files, :subject_codes, :jsonb, default: [] unless column_exists?(:folio_files, :subject_codes)
    add_column :folio_files, :category, :string unless column_exists?(:folio_files, :category)
    add_column :folio_files, :supplemental_categories, :jsonb, default: [] unless column_exists?(:folio_files, :supplemental_categories)
    
    # Rights and usage
    add_column :folio_files, :copyright_marked, :boolean unless column_exists?(:folio_files, :copyright_marked)
    add_column :folio_files, :model_age_disclosure, :string unless column_exists?(:folio_files, :model_age_disclosure)
    add_column :folio_files, :minor_model_age_disclosure, :string unless column_exists?(:folio_files, :minor_model_age_disclosure)
    add_column :folio_files, :persons_shown, :jsonb, default: [] unless column_exists?(:folio_files, :persons_shown)
    add_column :folio_files, :image_supplier_image_id, :string unless column_exists?(:folio_files, :image_supplier_image_id)
    
    # Date and location - skip existing columns
    add_column :folio_files, :capture_date, :datetime unless column_exists?(:folio_files, :capture_date)
    add_column :folio_files, :intellectual_genre, :string unless column_exists?(:folio_files, :intellectual_genre)
    add_column :folio_files, :location_created, :jsonb unless column_exists?(:folio_files, :location_created)
    add_column :folio_files, :location_shown, :jsonb unless column_exists?(:folio_files, :location_shown)
    add_column :folio_files, :city, :string unless column_exists?(:folio_files, :city)
    add_column :folio_files, :state_province, :string unless column_exists?(:folio_files, :state_province)
    add_column :folio_files, :country_name, :string unless column_exists?(:folio_files, :country_name)
    add_column :folio_files, :country_code, :string unless column_exists?(:folio_files, :country_code)
    add_column :folio_files, :world_region, :string unless column_exists?(:folio_files, :world_region)
    
    # Technical fields
    add_column :folio_files, :job_id, :string unless column_exists?(:folio_files, :job_id)
    add_column :folio_files, :instructions, :text unless column_exists?(:folio_files, :instructions)
    add_column :folio_files, :transmit_reference, :string unless column_exists?(:folio_files, :transmit_reference)
    add_column :folio_files, :urgency, :integer unless column_exists?(:folio_files, :urgency)
    add_column :folio_files, :artwork_circulate_reference, :string unless column_exists?(:folio_files, :artwork_circulate_reference)
    
    # GPS coordinates
    add_column :folio_files, :gps_latitude, :decimal, precision: 10, scale: 7 unless column_exists?(:folio_files, :gps_latitude)
    add_column :folio_files, :gps_longitude, :decimal, precision: 10, scale: 7 unless column_exists?(:folio_files, :gps_longitude)
    add_column :folio_files, :gps_altitude, :decimal, precision: 10, scale: 3 unless column_exists?(:folio_files, :gps_altitude)
    
    # Add indexes for performance (only if columns and indexes don't exist)
    add_index :folio_files, :creator, using: :gin unless index_exists?(:folio_files, :creator)
    add_index :folio_files, :keywords, using: :gin unless index_exists?(:folio_files, :keywords)
    add_index :folio_files, :subject_codes, using: :gin unless index_exists?(:folio_files, :subject_codes)
    add_index :folio_files, :supplemental_categories, using: :gin unless index_exists?(:folio_files, :supplemental_categories)
    add_index :folio_files, :persons_shown, using: :gin unless index_exists?(:folio_files, :persons_shown)
    add_index :folio_files, :file_metadata_extracted_at unless index_exists?(:folio_files, :file_metadata_extracted_at)
    add_index :folio_files, [:gps_latitude, :gps_longitude] unless index_exists?(:folio_files, [:gps_latitude, :gps_longitude])
  end
end
