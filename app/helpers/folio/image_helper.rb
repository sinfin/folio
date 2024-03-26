# frozen_string_literal: true

module Folio::ImageHelper
  def folio_image(placement, size, opts = {})
    cell("folio/image", placement, opts.merge(size:))
  end

  def static_folio_image(key, size, opts = {})
    folio_image({
                  normal: "/images/#{key}.#{opts[:extension] || 'png'}",
                  retina: "/images/#{key}@2x.#{opts[:extension] || 'png'}",
                  webp_normal: "/images/#{key}.webp",
                  webp_retina: "/images/#{key}@2x.webp",
                },
                size,
                class: "g-ui-static-image #{opts[:class]}")
  end
end
