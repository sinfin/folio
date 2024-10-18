# frozen_string_literal: true

class AddFolioAuditedDataToPages < ActiveRecord::Migration[7.1]
  def change
    add_column :folio_pages, :folio_audited_atoms_data, :jsonb
    add_column :folio_pages, :folio_audited_file_placements_data, :jsonb
  end
end
