# frozen_string_literal: true

class Folio::Console::Index::ImagesCell < Folio::ConsoleCell
  include Folio::CellLightbox

  class_name 'f-c-index-images', :cover, :gallery

  def id_class_name
    # needed for separate lightboxes
    "f-c-index-images--id-#{model.class.table_name}-#{model.id}"
  end

  def show
    if options[:cover] || options[:custom]
      render
    else
      render if model.image_placements.present?
    end
  end

  def image(placement)
    image_from(placement,
               Folio::Console::FileSerializer::ADMIN_THUMBNAIL_SIZE,
               lightbox(placement).merge(class: 'f-c-index-images__img'))
  end

  def broken_src
    'data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIyNCIgaGVpZ2h0PSIyNCIgdmlld0JveD0iMCAwIDI0IDI0Ij48cGF0aCBmaWxsPSJub25lIiBkPSJNMCAwaDI0djI0SDB6bTAgMGgyNHYyNEgwem0yMSAxOWMwIDEuMS0uOSAyLTIgMkg1Yy0xLjEgMC0yLS45LTItMlY1YzAtMS4xLjktMiAyLTJoMTRjMS4xIDAgMiAuOSAyIDIiLz48cGF0aCBmaWxsPSJub25lIiBkPSJNMCAwaDI0djI0SDB6Ii8+PHBhdGggZD0iTTIxIDV2Ni41OWwtMy0zLjAxLTQgNC4wMS00LTQtNCA0LTMtMy4wMVY1YzAtMS4xLjktMiAyLTJoMTRjMS4xIDAgMiAuOSAyIDJ6bS0zIDYuNDJsMyAzLjAxVjE5YzAgMS4xLS45IDItMiAySDVjLTEuMSAwLTItLjktMi0ydi02LjU4bDMgMi45OSA0LTQgNCA0IDQtMy45OXoiLz48L3N2Zz4='
  end

  def gallery
    !options[:cover]
  end
end
