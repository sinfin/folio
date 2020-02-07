# frozen_string_literal: true

class Folio::Page::Merger < Folio::Merger
  def structure
    [
      { key: :publishable_and_featured, as: :publishable_and_featured },
      :title,
      :slug,
      :perex,
      :featured,
      { key: :tags, as: :tags },
      { key: :atoms, as: :atoms }
    ]
  end
end
