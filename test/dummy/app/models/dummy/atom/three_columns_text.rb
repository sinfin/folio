# frozen_string_literal: true

class Dummy::Atom::ThreeColumnsText < Folio::Atom::Base
  ATTACHMENTS = %i[]

  STRUCTURE = {
    title: :richtext,
    column_1_title: :string,
    column_1: :richtext,
    column_2_title: :string,
    column_2: :richtext,
    column_3_title: :string,
    column_3: :richtext,
    mobile_layout: %w[one two],
    wrapper: %w[none background outline],
    color_mode: %w[light dark],
  }

  ASSOCIATIONS = {}

  validates :column_1,
            :column_2,
            :column_3,
            presence: true

  validate :validate_color_mode

  private
    def validate_color_mode
      if wrapper == "none" && color_mode == "dark"
        errors.add(:color_mode, :color_mode_without_wrapper)
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
