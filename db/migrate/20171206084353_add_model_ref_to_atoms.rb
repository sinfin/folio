# frozen_string_literal: true

class AddModelRefToAtoms < ActiveRecord::Migration[5.1]
  def change
    add_reference :folio_atoms, :model, polymorphic: true
  end
end
