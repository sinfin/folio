# frozen_string_literal: true

class AddTitleToContentTemplates < ActiveRecord::Migration[6.1]
  def change
    add_column :folio_content_templates, :title, :string
  end
end
