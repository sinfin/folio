# frozen_string_literal: true

module Folio::ImageMetadataExtraction
  extend ActiveSupport::Concern

  included do
    after_commit :extract_image_metadata, on: :create, if: :should_extract_metadata?
  end

  def should_extract_metadata?
    return false unless Rails.application.config.folio_image_metadata_extraction_enabled
    return false unless is_a?(Folio::File::Image)
    return false unless file.present? && file.respond_to?(:path)
    
    # Check if exiftool is available
    system("which exiftool > /dev/null 2>&1")
  end

  def extract_image_metadata
    return unless should_extract_metadata?
    
    metadata = extract_raw_metadata_with_exiftool
    return unless metadata.present?
    
    map_iptc_metadata(metadata)
    save if changed?
  rescue => e
    Rails.logger.error "Failed to extract metadata for #{file_name}: #{e.message}"
  end

  def map_iptc_metadata(raw_metadata)
    return unless raw_metadata.present?
    
    field_mappings = get_field_mappings
    skip_fields = Rails.application.config.folio_image_metadata_skip_fields || []
    
    field_mappings.each do |field_name, tag_names|
      next if skip_fields.include?(field_name)
      next if self[field_name].present? # Preserve existing data (blank field protection)
      
      value = extract_field_value(raw_metadata, tag_names, field_name)
      next unless value.present?
      
      self[field_name] = value
    end
  end

  private

  def extract_raw_metadata_with_exiftool
    return unless file.present? && File.exist?(file.path)
    
    require 'open3'
    
    options = Rails.application.config.folio_image_metadata_exiftool_options || ["-G1", "-struct", "-n"]
    command = ["exiftool", "-j", *options, file.path]
    
    stdout, stderr, status = Open3.capture3(*command)
    
    if status.success?
      JSON.parse(stdout).first
    else
      Rails.logger.warn "ExifTool error for #{file_name}: #{stderr}"
      nil
    end
  rescue JSON::ParserError => e
    Rails.logger.error "Failed to parse ExifTool output for #{file_name}: #{e.message}"
    nil
  end

  def get_field_mappings
    standard_mappings = Rails.application.config.folio_image_metadata_standard_mappings || {}
    custom_mappings = Rails.application.config.folio_image_metadata_custom_mappings || {}
    
    if Rails.application.config.folio_image_metadata_use_iptc_standard
      standard_mappings.merge(custom_mappings)
    else
      custom_mappings
    end
  end

  def extract_field_value(metadata, tag_names, field_name)
    return nil unless tag_names.is_a?(Array)
    
    # Try each tag in order (precedence: XMP > IPTC-IIM > EXIF)
    tag_names.each do |tag_name|
      value = metadata[tag_name]
      next unless value.present?
      
      return process_field_value(value, field_name)
    end
    
    nil
  end

  def process_field_value(value, field_name)
    case field_name
    when :creator, :keywords, :subject_codes, :scene_codes, :persons_shown, :persons_shown_details, :organizations_shown, :location_created, :location_shown
      # JSONB array fields
      process_array_field(value)
    when :copyright_marked
      # Boolean field
      process_boolean_field(value)
    when :capture_date
      # DateTime field with timezone support
      process_datetime_field(value)
    when :gps_latitude, :gps_longitude
      # GPS coordinates
      process_gps_coordinate(value)
    when :urgency
      # Integer field
      process_integer_field(value)
    when :country_code
      # Country code field - limit to 2 characters (ISO 3166-1 alpha-2)
      process_country_code_field(value)
    else
      # String fields - handle Lang Alt structures for XMP
      process_string_field(value)
    end
  end

  def process_array_field(value)
    case value
    when Array
      value.compact.reject(&:blank?)
    when String
      value.split(/[,;]/).map(&:strip).compact.reject(&:blank?)
    else
      [value.to_s].reject(&:blank?)
    end
  end

  def process_boolean_field(value)
    case value.to_s.downcase
    when 'true', '1', 'yes', 'marked'
      true
    when 'false', '0', 'no', 'unmarked'
      false
    else
      nil
    end
  end

  def process_datetime_field(value)
    return nil unless value.present?
    
    # Handle various date formats from EXIF/XMP
    begin
      # Try parsing as ISO 8601 first
      Time.parse(value.to_s)
    rescue ArgumentError
      # Try other common formats
      begin
        DateTime.strptime(value.to_s, "%Y:%m:%d %H:%M:%S")
      rescue ArgumentError
        nil
      end
    end
  end

  def process_gps_coordinate(value)
    return nil unless value.present?
    
    # Handle GPS coordinates in various formats
    case value
    when Numeric
      value.to_f
    when String
      # Handle formats like "50 deg 5' 23.28\" N" or decimal degrees
      if value.match?(/^\d+\.?\d*$/)
        value.to_f
      else
        # Parse DMS format
        parse_dms_coordinate(value)
      end
    else
      nil
    end
  end

  def process_integer_field(value)
    value.to_i if value.present?
  end

  def process_country_code_field(value)
    return nil unless value.present?
    
    # Only accept valid 2-character ISO 3166-1 alpha-2 codes
    country_code = value.to_s.strip.upcase
    
    # Check if it's exactly 2 alphabetic characters
    if country_code.match?(/^[A-Z]{2}$/)
      country_code
    else
      # Log invalid country code but don't fail the whole extraction
      Rails.logger.warn "Invalid country code '#{country_code}' in image metadata - skipping"
      nil
    end
  end

  def process_string_field(value)
    case value
    when Hash
      # Handle XMP Lang Alt structures
      process_lang_alt_field(value)
    when Array
      # Join multiple values
      value.compact.join(", ")
    else
      value.to_s.presence
    end
  end

  def process_lang_alt_field(lang_alt_hash)
    return nil unless lang_alt_hash.is_a?(Hash)
    
    locale_priority = Rails.application.config.folio_image_metadata_locale_priority || [:en, "x-default"]
    
    # Try locales in priority order
    locale_priority.each do |locale|
      value = lang_alt_hash[locale.to_s]
      return value if value.present?
    end
    
    # Fallback to any available value
    lang_alt_hash.values.compact.first
  end

  def parse_dms_coordinate(dms_string)
    return nil unless dms_string.present?
    
    # Parse degrees, minutes, seconds format
    # e.g., "50 deg 5' 23.28\" N" or "14 deg 25' 15.12\" E"
    match = dms_string.match(/(\d+(?:\.\d+)?)\s*deg\s*(\d+(?:\.\d+)?)\s*'\s*(\d+(?:\.\d+)?)\s*"\s*([NSEW])?/i)
    return nil unless match
    
    degrees, minutes, seconds, hemisphere = match.captures
    
    decimal = degrees.to_f + (minutes.to_f / 60) + (seconds.to_f / 3600)
    
    # Apply hemisphere
    if hemisphere&.upcase.in?(['S', 'W'])
      decimal = -decimal
    end
    
    decimal
  end
end
