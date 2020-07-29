# frozen_string_literal: true

module Folio::CellLightbox
  include Folio::ImageHelper

  LIGHTBOX_SIZE = '1920x1080>'

  def lightbox(placement)
    lightbox_from_image(placement.file).merge(
      'data-lightbox-title' => placement.try(:title),
    )
  end

  def lightbox_from_image(file)
    thumb = file.thumb(LIGHTBOX_SIZE)
    {
      'data-lightbox-src' => thumb.url,
      'data-lightbox-webp-src' => thumb.webp_url,
      'data-lightbox-width' => thumb.width,
      'data-lightbox-height' => thumb.height,
    }
  end

  def lightbox_image_data(placements, json: true)
    data = placements.map do |placement|
      thumb = placement.file.thumb(LIGHTBOX_SIZE)

      {
        src: thumb.url,
        webp_src: thumb.webp_url,
        w: thumb.width,
        h: thumb.height,
        title: placement.try(:title),
      }
    end

    if json
      ERB::Util.html_escape data.to_json
    else
      data
    end
  end
end
