# frozen_string_literal: true

class AddCreatedByFolioUserToFiles < ActiveRecord::Migration[8.0]
  def change
    add_reference :folio_files, :created_by_folio_user, null: true, foreign_key: { to_table: :folio_users, on_delete: :nullify }
  end
end
