# frozen_string_literal: true

class Folio::Page::Merger < Folio::Merger
  def structure
    [
      { key: :cover_placement, as: :file_placement },
      { key: :publishable_and_featured, as: :publishable_and_featured },
      :title,
      :slug,
      :perex,
      { key: :tags, as: :tags },
      { key: :atoms, as: :atoms },
    ]
  end
end
