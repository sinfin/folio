# frozen_string_literal: true

module Folio::CellLightbox
  include Folio::ImageHelper

  LIGHTBOX_SIZE = "2560x2048>"

  def lightbox(placement)
    if placement && placement.file
      lightbox_from_image(placement.file).merge(
        "data-lightbox-title" => placement.try(:title),
      )
    else
      {}
    end
  end

  def lightbox_from_image(file)
    if file
      thumb = file.thumb(LIGHTBOX_SIZE)
      {
        "data-lightbox-src" => thumb.url,
        "data-lightbox-webp-src" => thumb.webp_url,
        "data-lightbox-width" => thumb.width,
        "data-lightbox-height" => thumb.height,
      }
    else
      {}
    end
  end

  def lightbox_from_private_attachment(pa)
    if pa && pa.file_mime_type && pa.file_mime_type.starts_with?("image/")
      {
        "data-lightbox-src" => pa.file.url,
        "data-lightbox-width" => pa.file_width,
        "data-lightbox-height" => pa.file_height,
      }
    else
      {}
    end
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
