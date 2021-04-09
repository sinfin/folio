# frozen_string_literal: true

class Dummy::Atom::Card < Folio::Atom::Base
  self.abstract_class = true

  ATTACHMENTS = %i[cover]

  STRUCTURE = {
    title: :string,
    content: :richtext,
    button_label: :string,
    href: :url,
  }

  ASSOCIATIONS = {}

  validates :href,
            presence: true

  def self.console_icon
    :view_compact
  end

  def to_cell_hash
    {
      cover_placement: cover_placement,
      title: title,
      content: content,
      button_label: try(:button_label),
      href: href,
      large: is_a?(Dummy::Atom::Card::Large),
      medium: is_a?(Dummy::Atom::Card::Medium),
      small: is_a?(Dummy::Atom::Card::Small),
    }
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
