# frozen_string_literal: true

class CreateFolioAiUserInstructions < ActiveRecord::Migration[8.0]
  def change
    create_table :folio_ai_user_instructions do |t|
      t.references :user,
                   null: false,
                   foreign_key: { to_table: :folio_users }
      t.references :site,
                   null: false,
                   foreign_key: { to_table: :folio_sites }
      t.string :integration_key, null: false
      t.string :field_key, null: false
      t.text :instruction, null: false, default: ""

      t.timestamps
    end

    add_index :folio_ai_user_instructions,
              %i[user_id site_id integration_key field_key],
              unique: true,
              name: "index_folio_ai_user_instructions_uniqueness"
  end
end
