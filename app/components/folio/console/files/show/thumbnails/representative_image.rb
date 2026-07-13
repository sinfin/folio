# frozen_string_literal: true

module Folio::Console::Files::Show::Thumbnails::RepresentativeImage
  module_function

  def representative_thumbnail_size_key(keys)
    keys.max_by do |key|
      dimensions = key.gsub(/[#>^]$/, "")
      width_str, height_str = dimensions.split("x", 2)

      if width_str.nil? || width_str.empty?
        height_str.to_i
      elsif height_str.nil? || height_str.empty?
        width_str.to_i
      else
        width_str.to_i * height_str.to_i
      end
    end
  end

  # Resolved preview URL for the largest generated size among keys, using the
  # same CDN / temporary-url rewriting as the detail thumbnails. Doader
  # placeholder URLs are skipped unless include_doader (waiting state after a
  # crop reset, where the temporary url is the only thing available).
  def representative_url(file:, keys:, include_doader: false)
    candidates = keys.select do |key|
      thumb = file.thumbnail_sizes[key]
      next false unless thumb.is_a?(Hash) && thumb[:url].present?

      include_doader || !thumb[:url].include?("doader.com")
    end

    return nil if candidates.empty?

    key = representative_thumbnail_size_key(candidates)
    url = file.thumbnail_sizes[key][:url]

    if url.include?("doader.com")
      file.temporary_url(key)
    else
      Folio::S3.cdn_url_rewrite(url)
    end
  end
end
