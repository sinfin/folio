# frozen_string_literal: true

module Folio::Console::Files::Show::Thumbnails::RepresentativeImage
  module_function

  def representative_thumbnail_size_key(keys, preferred_ratio: nil)
    ranked_thumbnail_size_keys(keys, preferred_ratio:).first
  end

  def ranked_thumbnail_size_keys(keys, preferred_ratio: nil, minimum_width: nil, minimum_height: nil)
    candidates = keys.select do |key|
      thumbnail_covers?(key, minimum_width:, minimum_height:)
    end
    candidates = keys if candidates.empty?

    candidates.sort_by do |key|
      preferred_ratio_rank = preferred_ratio && thumbnail_size_key_ratio(key) != preferred_ratio ? 1 : 0
      [preferred_ratio_rank, -thumbnail_area(key)]
    end
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
    resolved_thumbnail_url(file:, key:)
  end

  def resolved_thumbnail_url(file:, key:)
    thumbnail = file.thumbnail_sizes[key]
    url = thumbnail[:url] || thumbnail["url"]

    if url.include?("doader.com")
      file.temporary_url(key)
    else
      Folio::S3.cdn_url_rewrite(url)
    end
  end

  def thumbnail_covers?(key, minimum_width:, minimum_height:)
    return true unless minimum_width || minimum_height

    width, height = Folio::Console::Files::ThumbnailGroups.parse_crop_key(key)
    return false unless width && height

    (!minimum_width || width >= minimum_width) && (!minimum_height || height >= minimum_height)
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
