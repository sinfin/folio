# frozen_string_literal: true

class CreateFolioLeads < ActiveRecord::Migration[5.1]
  def change
    create_table :folio_leads do |t|
      t.string :email
      t.string :phone
      t.text :note

      t.timestamps
    end
  end
end
