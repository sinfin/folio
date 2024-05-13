# frozen_string_literal: true

class AddSiteToConsoleNotes < ActiveRecord::Migration[7.1]
  def up
    unless column_exists?(:folio_console_notes, :site_id)
      add_reference :folio_console_notes, :site, null: true, foreign_key: { to_table: :folio_sites }
      change_column_null :folio_console_notes, :site_id, false, (Folio::Site.first&.id || 0)
    end
  end

  def down
    remove_reference :folio_console_notes, :site, if_exists: true
  end
end
