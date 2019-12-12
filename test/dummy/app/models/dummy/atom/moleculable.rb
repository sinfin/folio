# frozen_string_literal: true

class Dummy::Atom::Moleculable < Folio::Atom::Base
  ATTACHMENTS = %i[
    cover
    images
  ]

  STRUCTURE = {
    title: :string,
  }

  ASSOCIATIONS = {
    page: %i[Folio::Page],
  }

  def self.molecule_cell_name
    'dummy/molecule/moleculables'
  end
end

# == Schema Information
#
# Table name: folio_atoms
#
#  id             :bigint(8)        not null, primary key
#  type           :string
#  content        :text
#  position       :integer
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  placement_type :string
#  placement_id   :bigint(8)
#  model_type     :string
#  model_id       :bigint(8)
#  title          :string
#  perex          :text
#
# Indexes
#
#  index_folio_atoms_on_model_type_and_model_id          (model_type,model_id)
#  index_folio_atoms_on_placement_type_and_placement_id  (placement_type,placement_id)
#
