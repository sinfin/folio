# frozen_string_literal: true

class CreateFolioAddresses < ActiveRecord::Migration[6.0]
  def change
    create_table :folio_addresses do |t|
      t.string :name

      t.string :address_line_1
      t.string :address_line_2

      t.string :zip
      t.string :city

      t.string :country_code
      t.string :state

      t.string :identification_number
      t.string :vat_identification_number

      t.string :phone
      t.string :email

      t.string :type, index: true

      t.timestamps
    end

    add_column :folio_users, :use_secondary_address, :boolean, default: false
    add_reference :folio_users, :primary_address
    add_reference :folio_users, :secondary_address
  end
end
