# frozen_string_literal: true

class Dummy::Atom::ImageAndContent < Folio::Atom::Base
  ALLOWED_THUMB_SIZES = {
    "origin" => "648x",
    "1x1" => "648x648#",
    "3x2" => "648x432#",
    "16x9" => "648x365#",
    "4x3" => "648x486#",
    "9x16" => "648x1152#",
    "3x4" => "648x864#",
    "2x3" => "648x972#",
  }

  ATTACHMENTS = %i[cover]

  STRUCTURE = {
    title: :string,
    subtitle: :string,
    content: :richtext,
    image_ratio: ALLOWED_THUMB_SIZES.keys,
    vertically_centered_content: :boolean,
    button_label: :string,
    url: :url,
    open_in_new_tab: :boolean,
    image_side: %w[left right],
    wrapper: %w[none background outline],
    color_mode: %w[light dark],
  }

  ASSOCIATIONS = {}

  validates :cover_placement,
            presence: true

  validate :validate_one_of_contents

  validate :validate_color_mode

  def thumb_size_with_fallback
    ALLOWED_THUMB_SIZES[image_ratio.presence || "1x1"]
  end

  def self.default_atom_values
    { image_ratio: "1x1" }
  end

  private
    def validate_one_of_contents
      if title.blank? && content.blank? && button_label.blank?
        errors.add(:content, :blank)
      elsif button_label.present? && url.blank?
        errors.add(:url, :blank)
      end
    end

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
