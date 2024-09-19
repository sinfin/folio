# frozen_string_literal: true

class Dummy::Atom::Contents::Title < Folio::Atom::Base
  ALLOWED_TAGS = %w[H1 H2 H3 H4 H5]
  ALLOWED_FONT_SIZE = %w[fixed adaptive]
  ALLOWED_ALIGNS = %w[left center]
  ALLOWED_HIGHLIGHTS = [nil, "background"]
  ALLOWED_THEME = %w[light dark]

  ATTACHMENTS = %i[]

  STRUCTURE = {
    title: :string,
    tag: ALLOWED_TAGS,
    font_size: ALLOWED_FONT_SIZE,
    alignment: ALLOWED_ALIGNS,
    highlight: ALLOWED_HIGHLIGHTS,
    theme: ALLOWED_THEME,
  }

  ASSOCIATIONS = {}

  after_initialize do
    self.tag ||= "H2"
    self.font_size ||= "fixed"
    self.alignment ||= "left"
    self.theme ||= "light"
  end

  validates :title,
            presence: true

  def tag_with_fallback
    tag.presence || "H2"
  end

  def font_size_with_fallback
    font_size.presence || "fixed"
  end

  def alignment_with_fallback
    alignment.presence || "left"
  end

  def theme_with_fallback
    theme.presence || "light"
  end

  def self.default_atom_values
    {
      tag: "H2",
      font_size: "fixed",
      alignment: "left",
      theme: "light",
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
