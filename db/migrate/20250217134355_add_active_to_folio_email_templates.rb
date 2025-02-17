# frozen_string_literal: true

class AddActiveToFolioEmailTemplates < ActiveRecord::Migration[7.1]
  def change
    add_column :folio_email_templates, :active, :boolean, default: true
  end
end
