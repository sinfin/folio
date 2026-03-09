# frozen_string_literal: true

class AddAttributeNameToFolioTiptapRevisions < ActiveRecord::Migration[8.0]
  def change
    add_column :folio_tiptap_revisions, :attribute_name, :string, default: "tiptap_content", null: false
  end
end
