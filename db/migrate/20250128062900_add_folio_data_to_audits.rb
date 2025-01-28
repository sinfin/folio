# frozen_string_literal: true

class AddFolioDataToAudits < ActiveRecord::Migration[7.1]
  def change
    add_column :audits, :folio_data, :jsonb
  end
end
