# frozen_string_literal: true

class AddFolioAuditedDataToPages < ActiveRecord::Migration[7.1]
  def change
    add_column :folio_pages, :folio_audited_data, :jsonb
  end
end
