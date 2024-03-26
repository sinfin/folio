# frozen_string_literal: true

class AddAasmStateToFolioFiles < ActiveRecord::Migration[7.0]
  def up
    add_column :folio_files, :aasm_state, :string
    execute("UPDATE folio_files SET aasm_state = 'ready';")
  end

  def down
    remove_column :folio_files, :aasm_state
  end
end
