class AddAtomTitle < ActiveRecord::Migration[5.1]
  def change
    add_column :folio_atoms, :title, :string
  end
end
