class CreateFolioSites < ActiveRecord::Migration[5.1]
  def change
    create_table :folio_sites do |t|

      t.string   :title
      t.string   :domain, index: true

      t.string   :locale, default: :en
      t.jsonb   :locales, index: true

      t.timestamps
    end
  end
end
