class AddSiteTurboMode < ActiveRecord::Migration[5.2]
  def change
    add_column :folio_sites, :turbo_mode, :boolean, default: false
  end
end
