# frozen_string_literal: true

class AddFolioTiptapContentToPages < ActiveRecord::Migration[7.1]
  def change
    add_column :folio_pages, :tiptap_content, :jsonb
  end
end
