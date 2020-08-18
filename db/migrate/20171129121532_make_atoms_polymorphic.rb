# frozen_string_literal: true

class MakeAtomsPolymorphic < ActiveRecord::Migration[5.1]
  def up
    add_reference :folio_atoms, :placement, polymorphic: true

    Folio::Atom::Base.find_each do |atom|
      atom.placement_id = atom.node_id
      atom.placement_type = "Folio::Page"
      atom.save!
    end

    remove_reference :folio_atoms, :node
 end

  def down
    add_reference :folio_atoms, :node

    Folio::Atom::Base.find_each do |atom|
      atom.node_id = atom.placement_id
      atom.save!
    end

    remove_reference :folio_atoms, :placement, polymorphic: true
  end
end
