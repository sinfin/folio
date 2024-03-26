# frozen_string_literal: true

class Dummy::Atom::Cards::Large < Folio::Atom::Base
  ATTACHMENTS = %i[cover]

  STRUCTURE = {
    title: :string,
    content: :richtext,
    button_label: :string,
    button_url: :url,
    link_label: :string,
    link_url: :url,
  }

  ASSOCIATIONS = {}

  MOLECULE = true

  FORM_LAYOUT = :aside_attachments

  validates :button_url,
            presence: true,
            if: -> { button_label.present? }

  validates :link_url,
            presence: true,
            if: -> { link_label.present? }

  validate :validate_one_of_contents

  private
    def validate_one_of_contents
      if title.blank? && content.blank?
        errors.add(:content, :blank)
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
