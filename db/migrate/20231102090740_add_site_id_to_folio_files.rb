# frozen_string_literal: true

class AddSiteIdToFolioFiles < ActiveRecord::Migration[7.0]
  def up
    unless column_exists?(:folio_files, :site_id)
      add_reference :folio_files, :site, null: true, foreign_key: { to_table: :folio_sites }
      change_column_null :folio_files, :site_id, false, (Folio::Site.first&.id || 0)
    end
  end

  def down
    remove_reference :folio_files, :site, if_exists: true
  end
end
