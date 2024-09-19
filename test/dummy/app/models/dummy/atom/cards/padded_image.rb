# frozen_string_literal: true

class Dummy::Atom::Cards::PaddedImage < Folio::Atom::Base
  ATTACHMENTS = %i[cover]

  STRUCTURE = {
    title: :string,
    description: :text,
    url: :url,
  }

  ASSOCIATIONS = {}

  MOLECULE = true

  FORM_LAYOUT = :aside_attachments

  validates :title,
            :cover_placement,
            :url,
            presence: true

  def self.console_insert_row
    2
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
