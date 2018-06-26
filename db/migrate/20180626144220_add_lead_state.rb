class AddLeadState < ActiveRecord::Migration[5.1]
  def change
    add_column :folio_leads, :state, :string, default: :submitted
  end
end
