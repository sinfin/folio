# frozen_string_literal: true

class Dummy::Atom::Images::OneAndTwo < Folio::Atom::Base
  ATTACHMENTS = %i[images]

  STRUCTURE = {
    title: :string,
    subtitle: :string,
  }

  ASSOCIATIONS = {}

  validate :validate_image_placements_size

  private
    def validate_image_placements_size
      if image_placements.size != 3
        errors.add(:image_placements, :invalid_count, count: 3)
      end
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
