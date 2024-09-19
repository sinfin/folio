# frozen_string_literal: true

class Dummy::Atom::Contents::TextWrappingImage < Folio::Atom::Base
  ALLOWED_COVER_RATIOS = %w[origin 1x1 3x2 16x9 4x3 2x3 9x16 3x4]
  ALLOWED_IMAGE_SIDES = %w[left right]
  ALLOWED_THEMES = %w[light dark]
  ALLOWED_HIGHLIGHTS = [nil, "background"]

  ATTACHMENTS = %i[cover]

  STRUCTURE = {
    content: :richtext,
    image_side: ALLOWED_IMAGE_SIDES,
    theme: ALLOWED_THEMES,
    highlight: ALLOWED_HIGHLIGHTS,
    cover_ratio: ALLOWED_COVER_RATIOS,
  }

  ASSOCIATIONS = {}

  validates :cover_placement,
            :content,
            presence: true

  after_initialize do
    self.image_side ||= "left"
    self.theme ||= "light"
    self.cover_ratio ||= "origin"
  end

  def image_side_with_fallback
    image_side.presence || "left"
  end

  def theme_with_fallback
    theme.presence || "light"
  end

  def cover_ratio_with_fallback
    cover_ratio.presence || "origin"
  end

  def self.default_atom_values
    {
      image_side: "left",
      theme: "light",
      cover_ratio: "origin",
    }
  end

  def self.console_insert_row
    CONSOLE_INSERT_ROWS[:contents]
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
