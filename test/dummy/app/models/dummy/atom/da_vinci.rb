# frozen_string_literal: true

class Dummy::Atom::DaVinci < Folio::Atom::Base
  ATTACHMENTS = %i[
    cover
    document
  ]

  STRUCTURE = Hash[Folio::Atom::Base::KNOWN_STRUCTURE_TYPES.map { |t| [t, t] }]

  def self.cell_name
    'dummy/atom/da_vinci'
  end

  def self.console_icon
    :palette
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
