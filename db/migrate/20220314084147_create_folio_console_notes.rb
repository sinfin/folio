# frozen_string_literal: true

class CreateFolioConsoleNotes < ActiveRecord::Migration[6.1]
  def change
    create_table :folio_console_notes do |t|
      t.text :content

      t.belongs_to :target, polymorphic: true

      t.belongs_to :created_by
      t.belongs_to :closed_by

      t.datetime :closed_at

      t.datetime :due_at

      t.integer :position

      t.timestamps
    end
  end
end
