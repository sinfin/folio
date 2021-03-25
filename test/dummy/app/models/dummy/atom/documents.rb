# frozen_string_literal: true

class Dummy::Atom::Documents < Folio::Atom::Base
  ATTACHMENTS = %i[documents]

  STRUCTURE = {
    title: :string,
  }

  ASSOCIATIONS = {}

  validates :document_placements,
            presence: true

  def self.molecule_cell_name
    "dummy/molecule/documents"
  end

  def self.console_icon
    :insert_drive_file
  end
end

# == Schema Information
#
# Table name: folio_atoms
#
#  id              :bigint(8)        not null, primary key
#  type            :string
#  position        :integer
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  placement_type  :string
#  placement_id    :bigint(8)
#  locale          :string
#  data            :jsonb
#  associations    :jsonb
#  data_for_search :text
#
# Indexes
#
#  index_folio_atoms_on_placement_type_and_placement_id  (placement_type,placement_id)
#
