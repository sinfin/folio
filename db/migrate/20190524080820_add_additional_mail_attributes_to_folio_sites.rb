class AddAdditionalMailAttributesToFolioSites < ActiveRecord::Migration[5.2]
  def change
    add_column :folio_sites, :system_email, :string
    add_column :folio_sites, :system_email_copy, :string
    add_column :folio_sites, :email_from, :string
  end
end
