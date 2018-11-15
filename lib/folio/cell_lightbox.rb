# frozen_string_literal: true

module Folio::CellLightbox
  include Folio::ImageHelper

  LIGHTBOX_SIZE = '1920x1080>'

  def lightbox(placement)
    thumb = placement.image.thumb(LIGHTBOX_SIZE)
    {
      'data-lightbox-src': thumb.url,
      'data-lightbox-width': thumb.width,
      'data-lightbox-height': thumb.height,
      'data-lightbox-title': placement.title,
    }
  end

  def lightbox_image_data(placements, json: true)
    data = placements.map do |placement|
      thumb = placement.image.thumb(LIGHTBOX_SIZE)

      {
        src: thumb.url,
        w: thumb.width,
        h: thumb.height,
        title: placement.title,
      }
    end

    if json
      ERB::Util.html_escape data.to_json
    else
      data
    end
  end
end
