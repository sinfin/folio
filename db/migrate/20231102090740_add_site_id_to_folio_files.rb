# frozen_string_literal: true

class AddSiteIdToFolioFiles < ActiveRecord::Migration[7.0]
  def change
    add_reference :folio_files, :site, null: true, foreign_key: { to_table: :folio_sites }
    change_column_null :folio_files, :site_id, false, (Folio::Site.first&.id || 0)
  end
end
