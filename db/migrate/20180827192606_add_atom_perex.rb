class AddAtomPerex < ActiveRecord::Migration[5.2]
  def change
    add_column :folio_atoms, :perex, :text
  end
end
