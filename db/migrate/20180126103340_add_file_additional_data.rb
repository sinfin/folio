class AddFileAdditionalData < ActiveRecord::Migration[5.1]
  def change
    add_column :folio_files, :additional_data, :json
  end
end
