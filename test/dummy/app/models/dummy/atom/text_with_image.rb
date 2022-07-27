# frozen_string_literal: true

class Dummy::Atom::TextWithImage < Folio::Atom::Base
  ATTACHMENTS = %i[cover]

  STRUCTURE = {
    content: :richtext,
  }

  ASSOCIATIONS = {}

  validates :cover_placement,
            :content,
            presence: true

  def self.cell_name
    "dummy/atom/text_with_image"
  end

  def self.console_icon
    :crop_5_4
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
