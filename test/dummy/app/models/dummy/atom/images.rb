# frozen_string_literal: true

class Dummy::Atom::Images < Folio::Atom::Base
  ATTACHMENTS = %i[images]

  STRUCTURE = {
    title: :string,
    same_width: :boolean,
  }

  ASSOCIATIONS = {}

  validates :image_placements,
            presence: true

  def self.cell_name
    "dummy/atom/images"
  end

  def self.console_icon
    :image
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
#
# Indexes
#
#  index_folio_atoms_on_placement_type_and_placement_id  (placement_type,placement_id)
#
