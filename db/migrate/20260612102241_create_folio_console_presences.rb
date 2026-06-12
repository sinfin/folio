# frozen_string_literal: true

class CreateFolioConsolePresences < ActiveRecord::Migration[8.0]
  def change
    create_table :folio_console_presences do |t|
      t.references :user,
                   null: false,
                   foreign_key: { to_table: :folio_users },
                   index: false
      t.string :record_type, null: false
      t.bigint :record_id, null: false
      t.datetime :updated_at, null: false
    end

    add_index :folio_console_presences,
              %i[record_type record_id updated_at],
              name: "index_folio_console_presences_on_record_and_freshness"
    add_index :folio_console_presences,
              %i[user_id record_type record_id],
              unique: true,
              name: "index_folio_console_presences_on_user_and_record"
  end
end
