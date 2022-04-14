# frozen_string_literal: true

class Dummy::Atom::Title < Folio::Atom::Base
  ALLOWED_TAGS = %w[H1 H2 H3 H4]

  ATTACHMENTS = %i[]

  STRUCTURE = {
    title: :string,
    tag: ALLOWED_TAGS,
  }

  ASSOCIATIONS = {}

  after_initialize { self.tag ||= "H2" }

  validates :title,
            presence: true

  def tag_with_fallback
    tag.presence || "H2"
  end

  def self.cell_name
    "dummy/atom/title"
  end

  def self.console_icon
    :text_fields
  end

  def self.console_insert_row
    0
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
