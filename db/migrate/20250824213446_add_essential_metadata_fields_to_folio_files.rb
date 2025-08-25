# frozen_string_literal: true

class AddEssentialMetadataFieldsToFolioFiles < ActiveRecord::Migration[7.1]
  def change
    # User-editable field for headline/title
    add_column :folio_files, :headline, :string
    add_index :folio_files, :headline

    # Technical metadata - needed for display/sorting
    add_column :folio_files, :capture_date, :datetime
    add_index :folio_files, :capture_date

    # GPS coordinates - needed for geographic queries
    add_column :folio_files, :gps_latitude, :decimal, precision: 10, scale: 6
    add_column :folio_files, :gps_longitude, :decimal, precision: 10, scale: 6
    add_index :folio_files, [:gps_latitude, :gps_longitude]

    # Timestamp for metadata extraction tracking
    add_column :folio_files, :file_metadata_extracted_at, :datetime
    add_index :folio_files, :file_metadata_extracted_at
  end
end
