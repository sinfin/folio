class ExtendLeads < ActiveRecord::Migration[5.1]
  def change
    add_column :folio_leads, :name, :string
    add_column :folio_leads, :url, :string
  end
end
