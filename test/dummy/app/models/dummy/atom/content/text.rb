# frozen_string_literal: true

class Dummy::Atom::Content::Text < Folio::Atom::Base
  ALLOWED_ALIGNS = %w[left center]
  ALLOWED_THEMES = %w[light dark]
  ALLOWED_OUTLINES = [nil, "gray", "blue", "red", "green", "orange"]
  ALLOWED_HIGHLIGHTS = [nil, "background"]

  ATTACHMENTS = %i[]

  STRUCTURE = {
    content: :richtext,
    alignment: ALLOWED_ALIGNS,
    theme: ALLOWED_THEMES,
    outline: ALLOWED_OUTLINES,
    highlight: ALLOWED_HIGHLIGHTS,
  }

  ASSOCIATIONS = {}

  after_initialize do
    self.alignment ||= "left"
    self.theme ||= "light"
  end

  validates :content,
            presence: true

  def alignment_with_fallback
    alignment.presence || "left"
  end

  def theme_with_fallback
    theme.presence || "light"
  end

  def self.default_atom_values
    {
      alignment: "left",
      theme: "light",
    }
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
