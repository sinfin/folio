# frozen_string_literal: true

class Folio::File::Image < Folio::File
  include Folio::Sitemap::Image
  include Folio::File::HasUsageConstraints

  validate_file_format(%w[jpeg png gif svg tiff webp avif heic heif])

  # Metadata extraction after image creation
  after_commit :extract_metadata_async, if: :should_extract_metadata?

  dragonfly_accessor :file do
    after_assign :sanitize_filename
    after_assign { |file| file.metadata }
  end

  # Unified metadata accessor via IptcFieldMapper
  def mapped_metadata
    @mapped_metadata ||= if file_metadata.present?
      Folio::Metadata::IptcFieldMapper.map_metadata(file_metadata)
    else
      {}
    end
  end

  # Shorthand for common fields (backward compatibility)
  def title
    headline.presence || mapped_metadata[:headline]
  end

  def caption
    description.presence || mapped_metadata[:description]
  end

  def keywords
    mapped_metadata[:keywords] || []
  end

  # GPS coordinates helper
  def location_coordinates
    return nil unless gps_latitude.present? && gps_longitude.present?
    [gps_latitude, gps_longitude]
  end

  # Human-friendly geo location for sitemaps and displays
  # Prefers descriptive place fields, falls back to GPS coordinates
  def geo_location
    parts = []

    # Prefer mapped descriptive fields when available
    if mapped_metadata.present?
      parts << mapped_metadata[:sublocation]
      parts << mapped_metadata[:city]
      parts << mapped_metadata[:state_province]
      parts << mapped_metadata[:country]
    end

    human_location = parts.compact.reject(&:blank?).join(", ")
    return human_location if human_location.present?

    # Fallback to numeric coordinates
    if gps_latitude.present? && gps_longitude.present?
      return "#{gps_latitude},#{gps_longitude}"
    end

    nil
  end


  def thumbnailable?
    true
  end

  def self.human_type
    "image"
  end

  # Manual metadata extraction (for existing images)
  def extract_metadata!(force: false, user_id: nil, save: true)
    Folio::Metadata::ExtractionService.new(self).extract!(force: force, user_id: user_id, save: save)
  end

  # Metadata extraction callbacks (delegate to service)
  def should_extract_metadata?
    Folio::Metadata::ExtractionService.should_extract?(self)
  end

  def extract_metadata_async
    Folio::Metadata::ExtractionService.extract_async(self)
  end
end
