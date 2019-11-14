# frozen_string_literal: true

class AddAtomDataForSearchColumn < ActiveRecord::Migration[5.2]
  def change
    add_column :folio_atoms, :data_for_search, :text

    Folio::Atom::Base.find_each do |atom|
      data_for_search = atom.data
                            .try(:values)
                            .try(:join, "\n")
                            .presence
      atom.update_column(:data_for_search, data_for_search)
    end
  end
end
