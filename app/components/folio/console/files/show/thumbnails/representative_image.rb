# frozen_string_literal: true

module Folio::Console::Files::Show::Thumbnails::RepresentativeImage
  module_function

  def representative_thumbnail_size_key(keys, preferred_ratio: nil)
    candidates = if preferred_ratio
      keys.select { |key| thumbnail_size_key_ratio(key) == preferred_ratio }
    else
      keys
    end

    (candidates.presence || keys).max_by { |key| thumbnail_area(key) }
  end

  # Resolved preview URL for the largest generated size among keys, preferring
  # an exact ratio where requested. Uses the same CDN / temporary-url rewriting
  # as detail thumbnails. Doader placeholder URLs are skipped unless
  # include_doader (waiting state after a crop reset, where a temporary URL is
  # the only thing available).
  def representative_url(file:, keys:, preferred_ratio: nil, include_doader: false)
    candidates = keys.select do |key|
      thumb = file.thumbnail_sizes[key]
      next false unless thumb.is_a?(Hash) && thumb[:url].present?

      include_doader || !thumb[:url].include?("doader.com")
    end

    return nil if candidates.empty?

    key = representative_thumbnail_size_key(candidates, preferred_ratio:)
    url = file.thumbnail_sizes[key][:url]

    if url.include?("doader.com")
      file.temporary_url(key)
    else
      Folio::S3.cdn_url_rewrite(url)
    end
  end

  def thumbnail_area(key)
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

  def thumbnail_size_key_ratio(key)
    width, height = Folio::Console::Files::ThumbnailGroups.parse_crop_key(key)
    return unless width && height

    gcd = width.gcd(height)
    "#{width / gcd}:#{height / gcd}"
  end
end
