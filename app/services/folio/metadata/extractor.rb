# frozen_string_literal: true

module Folio::Metadata
  class Extractor
    attr_reader :file_record, :locale

    def initialize(file_record, locale: nil)
      @file_record = file_record
      @locale = locale
    end

    # Single entry point for any metadata field
    def get_field(field_name, locale: nil)
      return nil unless file_record.file_metadata.present?

      # Use provided locale, fallback to instance locale, then current I18n.locale
      effective_locale = locale || @locale || I18n.locale

      # Special handling for GPS fields that prefer DB column values
      if [:gps_latitude, :gps_longitude].include?(field_name)
        column_value = file_record[field_name]
        return column_value if column_value.present?
      end

      IptcFieldMapper.get_field(file_record.file_metadata, field_name, file_record, locale: effective_locale)
    end

    # Delegate all metadata methods through single interface
    def method_missing(method_name, *args, &block)
      # Handle _from_metadata suffix methods
      if method_name.to_s.end_with?("_from_metadata")
        field_name = method_name.to_s.gsub("_from_metadata", "").to_sym
        get_field(field_name)
      else
        # Try as direct field name
        result = get_field(method_name)
        return result unless result.nil?

        # Fallback to super if not a metadata field
        super
      end
    end

    def respond_to_missing?(method_name, include_private = false)
      method_name.to_s.end_with?("_from_metadata") ||
      IptcFieldMapper::FIELD_MAPPINGS.key?(method_name) ||
      super
    end

    # Convenience methods for common patterns
    def headline
      get_field(:headline)
    end

    def creator
      get_field(:creator)
    end

    def description
      get_field(:description)
    end

    def credit_line
      get_field(:credit_line)
    end

    def keywords
      get_field(:keywords)
    end

    def source
      get_field(:source)
    end

    # Technical metadata
    def camera_make
      get_field(:camera_make)
    end

    def camera_model
      get_field(:camera_model)
    end

    def software
      get_field(:software)
    end

    def lens_info
      get_field(:lens_info)
    end

    def focal_length
      get_field(:focal_length)
    end

    def aperture
      get_field(:aperture)
    end

    def shutter_speed
      get_field(:shutter_speed)
    end

    def iso_speed
      get_field(:iso_speed)
    end

    def flash
      get_field(:flash)
    end

    def white_balance
      get_field(:white_balance)
    end

    def exposure_mode
      get_field(:exposure_mode)
    end

    def exposure_compensation
      get_field(:exposure_compensation)
    end

    def metering_mode
      get_field(:metering_mode)
    end

    def color_space
      get_field(:color_space)
    end

    def capture_date
      get_field(:capture_date)
    end

    def gps_latitude
      get_field(:gps_latitude)
    end

    def gps_longitude
      get_field(:gps_longitude)
    end

    # Location and rights
    def city
      get_field(:city)
    end

    def country
      get_field(:country)
    end

    def country_code
      get_field(:country_code)
    end

    def copyright_notice
      get_field(:copyright_notice)
    end

    def copyright_marked
      get_field(:copyright_marked)
    end

    def usage_terms
      get_field(:usage_terms)
    end

    def rights_usage_info
      get_field(:rights_usage_info)
    end

    # People and organization
    def persons_shown
      get_field(:persons_shown)
    end

    def organizations_shown
      get_field(:organizations_shown)
    end

    # Classifications
    def subject_codes
      get_field(:subject_codes)
    end

    def scene_codes
      get_field(:scene_codes)
    end

    def intellectual_genre
      get_field(:intellectual_genre)
    end

    def event
      get_field(:event)
    end

    def urgency
      get_field(:urgency)
    end

    def category
      get_field(:category)
    end

    def caption_writer
      get_field(:caption_writer)
    end

    def sublocation
      get_field(:sublocation)
    end

    def state_province
      get_field(:state_province)
    end

    def location_created
      get_field(:location_created)
    end

    def location_shown
      get_field(:location_shown)
    end

    def orientation
      get_field(:orientation)
    end
  end
end
