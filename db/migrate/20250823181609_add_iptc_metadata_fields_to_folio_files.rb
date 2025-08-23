class AddIptcMetadataFieldsToFolioFiles < ActiveRecord::Migration[7.1]
  def change
    # Core descriptive fields
    add_column :folio_files, :headline, :string
    add_column :folio_files, :creator, :jsonb, default: []  # Array of creators
    add_column :folio_files, :caption_writer, :string
    add_column :folio_files, :credit_line, :string
    add_column :folio_files, :source, :string
    
    # Rights management
    add_column :folio_files, :copyright_notice, :text
    add_column :folio_files, :copyright_marked, :boolean, default: false
    add_column :folio_files, :usage_terms, :text
    add_column :folio_files, :rights_usage_info, :string  # URL
    
    # Classification (JSONB arrays for multi-value fields)
    add_column :folio_files, :keywords, :jsonb, default: []
    add_column :folio_files, :intellectual_genre, :string
    add_column :folio_files, :subject_codes, :jsonb, default: []
    add_column :folio_files, :scene_codes, :jsonb, default: []
    add_column :folio_files, :event, :string  # Single event string
    
    # Legacy fields (for backwards compatibility)
    add_column :folio_files, :category, :string
    add_column :folio_files, :urgency, :integer
    
    # People and objects (JSONB arrays)
    add_column :folio_files, :persons_shown, :jsonb, default: []
    add_column :folio_files, :persons_shown_details, :jsonb, default: []
    add_column :folio_files, :organizations_shown, :jsonb, default: []
    
    # Location data
    add_column :folio_files, :location_created, :jsonb, default: []  # Array of structs
    add_column :folio_files, :location_shown, :jsonb, default: []    # Array of structs
    add_column :folio_files, :sublocation, :string  # Neighborhood/venue
    add_column :folio_files, :city, :string
    add_column :folio_files, :state_province, :string
    add_column :folio_files, :country, :string
    add_column :folio_files, :country_code, :string, limit: 2  # ISO 3166-1 alpha-2
    
    # Technical metadata
    add_column :folio_files, :camera_make, :string
    add_column :folio_files, :camera_model, :string
    add_column :folio_files, :lens_info, :string
    add_column :folio_files, :capture_date, :datetime
    add_column :folio_files, :capture_date_offset, :string  # Store original timezone
    add_column :folio_files, :gps_latitude, :decimal, precision: 10, scale: 6
    add_column :folio_files, :gps_longitude, :decimal, precision: 10, scale: 6
    add_column :folio_files, :orientation, :integer
    
    # Indexes for common searches (GIN for JSONB arrays)
    add_index :folio_files, :creator, using: :gin
    add_index :folio_files, :keywords, using: :gin
    add_index :folio_files, :subject_codes, using: :gin
    add_index :folio_files, :persons_shown, using: :gin
    add_index :folio_files, :source
    add_index :folio_files, :country_code
    add_index :folio_files, :capture_date
    add_index :folio_files, [:gps_latitude, :gps_longitude]
  end
end
