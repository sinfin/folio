# frozen_string_literal: true

class AddFolioTiptapRevision < ActiveRecord::Migration[7.1]
  def change
    create_table :folio_tiptap_revisions do |t|
      t.belongs_to :placement, polymorphic: true, null: false
      t.belongs_to :user, foreign_key: { to_table: :folio_users }, null: true

      t.jsonb :content, null: false
      t.integer :revision_number, null: false

      t.timestamps
    end

    add_index :folio_tiptap_revisions, [:placement_type, :placement_id, :revision_number],
              name: "index_folio_tiptap_revisions_on_placement_and_revision"
    add_index :folio_tiptap_revisions, :revision_number
  end
end
