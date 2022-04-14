# frozen_string_literal: true

class RmAtomsDataForSearch < ActiveRecord::Migration[7.0]
  def change
    remove_column :folio_atoms, :data_for_search, :text
  end
end
