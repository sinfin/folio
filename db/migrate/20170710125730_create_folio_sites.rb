# frozen_string_literal: true

class CreateFolioSites < ActiveRecord::Migration[5.1]
  def change
    create_table :folio_sites do |t|
      t.string   :title
      t.string   :domain, index: true
      t.string   :email
      t.string   :phone

      t.string  :locale, default: :en
      t.string  :locales, array: true, default: []

      t.timestamps
    end
  end
end
