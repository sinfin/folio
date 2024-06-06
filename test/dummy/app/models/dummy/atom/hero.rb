# frozen_string_literal: true

class Dummy::Atom::Hero < Folio::Atom::Base
  ALLOWED_IMAGE_SIZES = %w[container full_width small medium large extra_large]
  ALLOWED_THEMES = %w[light dark]
  ALLOWED_BACKGROUND_OVERLAYS = [nil, "light", "dark"]

  ATTACHMENTS = %i[cover background_cover]

  STRUCTURE = {
    title: :string,
    content: :text,
    date: :date,
    author: :string,
    image_size: ALLOWED_IMAGE_SIZES,
    theme: ALLOWED_THEMES,
    background_overlay: ALLOWED_BACKGROUND_OVERLAYS,
    background_color: :color,
    show_background_color: :boolean,
    show_divider: :boolean,
  }

  ASSOCIATIONS = {}

  after_initialize do
    self.image_size ||= "container"
    self.theme ||= "light"
    self.show_background_color = false if show_background_color.nil?
    self.show_divider = false if show_divider.nil?
  end

  has_one_placement(:background_cover,
                    placement_key: :background_cover_placement,
                    placement: "Folio::FilePlacement::BackgroundCover")

  validate :title_or_content_present

  def image_size_with_fallback
    image_size.presence || "container"
  end

  def theme_with_fallback
    theme.presence || "light"
  end

  def self.default_atom_values
    {
      image_size: "full_width",
      theme: "light",
    }
  end

  def title_or_content_present
    return if title.present? || content.present?

    errors.add(:title, :blank)
    errors.add(:content, :blank)
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
