# frozen_string_literal: true

class AddBackwardCompatibilityForIptcFields < ActiveRecord::Migration[7.1]
  def up
    # Check if old columns exist before renaming (in case migration is run multiple times)
    if column_exists?(:folio_files, :author) && !column_exists?(:folio_files, :author_legacy)
      rename_column :folio_files, :author, :author_legacy
      add_column :folio_files, :author, :string
    end
    
    if column_exists?(:folio_files, :alt) && !column_exists?(:folio_files, :alt_legacy)
      rename_column :folio_files, :alt, :alt_legacy
      add_column :folio_files, :alt, :string
    end
  end
  
  def down
    # Restore original structure if needed
    if column_exists?(:folio_files, :author_legacy)
      remove_column :folio_files, :author if column_exists?(:folio_files, :author)
      rename_column :folio_files, :author_legacy, :author
    end
    
    if column_exists?(:folio_files, :alt_legacy)
      remove_column :folio_files, :alt if column_exists?(:folio_files, :alt)
      rename_column :folio_files, :alt_legacy, :alt
    end
  end
end
