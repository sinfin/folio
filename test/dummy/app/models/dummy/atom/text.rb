# frozen_string_literal: true

class Dummy::Atom::Text < Folio::Atom::Base
  ATTACHMENTS = %i[]

  STRUCTURE = {
    content: :richtext,
    highlight: [nil, "red", "gray"],
  }

  ASSOCIATIONS = {}

  validates :content,
            presence: true

  def self.cell_name
    "dummy/atom/text"
  end

  def self.console_icon
    :format_align_left
  end

  def self.console_insert_row
    0
  end

  def self.splittable_by_attribute
    :content
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
