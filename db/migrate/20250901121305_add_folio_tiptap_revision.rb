# frozen_string_literal: true

class AddFolioTiptapRevision < ActiveRecord::Migration[7.1]
  def change
    create_table :folio_tiptap_revisions do |t|
      t.belongs_to :placement, polymorphic: true, null: false
      t.belongs_to :user, foreign_key: { to_table: :folio_users }, null: true
      t.belongs_to :superseded_by_user, foreign_key: { to_table: :folio_users }, null: true

      t.jsonb :content, null: false

      t.timestamps
    end
  end
end
