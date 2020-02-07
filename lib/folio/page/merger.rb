# frozen_string_literal: true

class Folio::Page::Merger < Folio::Merger
  def structure
    [
      :title,
      :slug,
      :perex,
      :featured,
      { key: :tags, as: :tags }
    ]
  end
end
