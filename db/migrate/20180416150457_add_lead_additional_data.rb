class AddLeadAdditionalData < ActiveRecord::Migration[5.1]
  def change
    add_column :folio_leads, :additional_data, :json
  end
end
