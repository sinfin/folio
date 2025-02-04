# frozen_string_literal: true

class AddSiteToFolioContentTemplates < ActiveRecord::Migration[7.1]
  def change
    add_reference :folio_content_templates, :site, foreign_key: { to_table: :folio_sites }, index: true, null: true
  end
end
