# frozen_string_literal: true

module Folio::ImageMetadataExtraction
  extend ActiveSupport::Concern

  included do
    # Extract metadata asynchronously after file creation
    after_commit :extract_image_metadata_async, on: :create, if: :should_extract_metadata?
  end

  def should_extract_metadata?
    return false unless Rails.application.config.folio_image_metadata_extraction_enabled
    return false unless is_a?(Folio::File::Image)
    return false unless file.present? && (file.respond_to?(:path) || file.is_a?(String))

    # Skip extraction in test mode when explicitly disabled
    return false if Rails.env.test? && ENV["FOLIO_SKIP_METADATA_EXTRACTION"] == "true"

    # Check if we have new IPTC fields (backward compatibility)
    return false unless has_iptc_metadata_fields?

    # Check if exiftool is available
    system("which exiftool > /dev/null 2>&1")
  end

  # Check if we have the essential metadata fields for JSON-based approach
  def has_iptc_metadata_fields?
    # For JSON-based approach: check essential DB columns + JSON metadata storage
    has_attribute?(:headline) && has_attribute?(:file_metadata)
  end

  def extract_image_metadata_async
    if defined?(ActiveJob) && Rails.application.config.active_job.queue_adapter != :test
      Folio::ExtractMetadataJob.perform_later(self)
    else
      # Synchronous extraction for tests or when jobs are disabled
      extract_image_metadata_sync
    end
  end

  def extract_image_metadata_sync
    return unless should_extract_metadata?

    metadata = extract_raw_metadata_with_exiftool
    return unless metadata.present?

    map_iptc_metadata(metadata)
    save if changed?
  rescue => e
    Rails.logger.error "Failed to extract metadata for #{file_name}: #{e.message}"
  end

  # Manual metadata extraction (for existing images)
  def extract_metadata!(force: false)
    if defined?(ActiveJob) && Rails.application.config.active_job.queue_adapter != :test
      Folio::ExtractMetadataJob.perform_later(self, force: force)
    else
      extract_image_metadata_sync
    end
  end

  def map_iptc_metadata(raw_metadata)
    return unless raw_metadata.present?

    # Store raw metadata in JSON column
    self.file_metadata = raw_metadata

    # Set extraction timestamp
    self.file_metadata_extracted_at = Time.current

    # Use IptcFieldMapper with fallbacks and special processing
    mapped_data = Folio::Metadata::IptcFieldMapper.map_metadata(raw_metadata)

    # Store processed (UTF-8) values back to file_metadata for JSON getters
    store_processed_metadata_for_getters(mapped_data)

    # Automatically populate BLANK user fields from mapped data (Phase 3)
    populate_user_fields_from_mapped_data(mapped_data)
  end

  private
    def store_processed_metadata_for_getters(mapped_data)
      # Store processed (UTF-8) values in file_metadata for JSON getters
      # This ensures getters return clean UTF-8 data instead of raw mojibake

      # Only store if we have better/processed data
      if mapped_data[:creator].present?
        self.file_metadata["creator"] = mapped_data[:creator]
      end

      if mapped_data[:headline].present?
        self.file_metadata["headline"] = mapped_data[:headline]
      end

      if mapped_data[:description].present?
        self.file_metadata["description"] = mapped_data[:description]
      end

      if mapped_data[:keywords].present?
        self.file_metadata["keywords"] = mapped_data[:keywords]
      end

      if mapped_data[:credit_line].present?
        self.file_metadata["credit_line"] = mapped_data[:credit_line]
      end

      if mapped_data[:copyright_notice].present?
        self.file_metadata["copyright_notice"] = mapped_data[:copyright_notice]
      end
    end

    def populate_user_fields_from_mapped_data(mapped_data)
      # Only populate blank fields (never overwrite user data)

      # ✅ Editable database columns (uses IptcFieldMapper results)
      self.headline = mapped_data[:headline] if headline.blank? && mapped_data[:headline].present?
      self.author = Array(mapped_data[:creator]).join(", ") if author.blank? && mapped_data[:creator].present?
      self.description = mapped_data[:description] || mapped_data[:headline] if description.blank?
      self.attribution_copyright = mapped_data[:copyright_notice] if attribution_copyright.blank?
      self.attribution_source = mapped_data[:credit_line] || mapped_data[:source] if attribution_source.blank?

      # ✅ Essential business columns (indexed/queryable)
      self.capture_date = mapped_data[:capture_date] if capture_date.blank?
      self.gps_latitude = mapped_data[:gps_latitude] if gps_latitude.blank?
      self.gps_longitude = mapped_data[:gps_longitude] if gps_longitude.blank?

      # ✅ Merge keywords with existing tag_list system (no new column needed)
      if respond_to?(:tag_list=) && mapped_data[:keywords].present?
        begin
          existing_tags = try(:tag_list_array) || []
          new_keywords = Array(mapped_data[:keywords])
          self.tag_list = (existing_tags + new_keywords).uniq
        rescue => e
          Rails.logger.warn("Failed to merge keywords into tag_list for #{file_name}: #{e.message}")
        end
      end
    end

  # JSON-based metadata getters for read-only display
  # These access raw metadata from file_metadata JSON for UI display
  public

    def creator
      # Prefer processed data (UTF-8 fixed) over raw metadata
      creators = file_metadata&.dig("creator") ||                 # ✅ Processed data (UTF-8)
                 file_metadata&.dig("XMP-dc:Creator") ||
                 file_metadata&.dig("XMP-dc:creator") ||          # lowercase variant
                 file_metadata&.dig("IPTC:By-line") ||             # Try IPTC first
                 file_metadata&.dig("By-line") ||                  # Raw fallback (may have mojibake)
                 file_metadata&.dig("Artist")
      case creators
      when Array then creators.compact.reject(&:blank?)
      when String then [creators].compact.reject(&:blank?)
      else []
      end
    end

    def credit_line
      # Prefer processed data (UTF-8 fixed) over raw metadata
      file_metadata&.dig("credit_line") ||                    # ✅ Processed data (UTF-8)
      file_metadata&.dig("XMP-iptcCore:CreditLine") ||
      file_metadata&.dig("XMP-photoshop:Credit") ||
      file_metadata&.dig("IPTC:Credit") ||                    # Try IPTC first
      file_metadata&.dig("Credit")                            # Raw fallback (may have mojibake)
    end

    def copyright_notice
      # Prefer processed data (UTF-8 fixed) over raw metadata
      file_metadata&.dig("copyright_notice") ||               # ✅ Processed data (UTF-8)
      file_metadata&.dig("XMP-photoshop:Copyright") ||
      file_metadata&.dig("XMP-dc:Rights")
    end

    def copyright_marked
      value = file_metadata&.dig("XMP-xmpRights:Marked")
      case value
      when true, "true", "True", 1 then true
      when false, "false", "False", 0 then false
      else nil
      end
    end

    def usage_terms
      file_metadata&.dig("XMP-xmpRights:UsageTerms")
    end

    def rights_usage_info
      file_metadata&.dig("XMP-xmpRights:WebStatement")
    end

    def subject_codes
      codes = file_metadata&.dig("XMP-iptcCore:SubjectCode")
      case codes
      when Array then codes.compact.reject(&:blank?)
      when String then [codes].compact.reject(&:blank?)
      else []
      end
    end

    def scene_codes
      codes = file_metadata&.dig("XMP-iptcCore:Scene")
      case codes
      when Array then codes.compact.reject(&:blank?)
      when String then [codes].compact.reject(&:blank?)
      else []
      end
    end

    def location_created
      file_metadata&.dig("XMP-iptcExt:LocationCreated")
    end

    def location_shown
      file_metadata&.dig("XMP-iptcExt:LocationShown")
    end

    def orientation
      file_metadata&.dig("Orientation")
    end

    def camera_make
      file_metadata&.dig("Make")
    end

    def camera_model
      file_metadata&.dig("Model")
    end

    def lens_info
      file_metadata&.dig("LensModel") ||
      file_metadata&.dig("LensInfo")
    end

  # Public JSON-based metadata getters for UI display and API serialization
  public

    def source_from_metadata
      file_metadata&.dig("XMP-iptcCore:Source") ||
      file_metadata&.dig("XMP-photoshop:Source") ||
      file_metadata&.dig("Source")
    end

    # Alias for backward compatibility
    alias_method :source, :source_from_metadata

    def keywords_from_metadata
      # Prefer processed data (UTF-8 fixed) over raw metadata
      keywords = file_metadata&.dig("keywords") ||            # ✅ Processed data (UTF-8)
                 file_metadata&.dig("XMP-dc:Subject") ||
                 file_metadata&.dig("IPTC:Keywords") ||
                 file_metadata&.dig("Keywords")                # Raw fallback (may have mojibake)
      case keywords
      when Array then keywords.compact.reject(&:blank?)
      when String then [keywords].compact.reject(&:blank?)
      else []
      end
    end

    # Alias for backward compatibility
    alias_method :keywords, :keywords_from_metadata

    def headline_from_metadata
      # Prefer processed data (UTF-8 fixed) over raw metadata
      file_metadata&.dig("headline") ||                      # ✅ Processed data (UTF-8)
      file_metadata&.dig("XMP-photoshop:Headline") ||
      file_metadata&.dig("IPTC:Headline") ||                 # Try IPTC first
      file_metadata&.dig("Headline")                          # Raw fallback (may have mojibake)
    end

    def city
      file_metadata&.dig("XMP-photoshop:City") ||
      file_metadata&.dig("City")
    end

    def country
      file_metadata&.dig("XMP-iptcCore:CountryName") ||
      file_metadata&.dig("Country-PrimaryLocationName") ||
      file_metadata&.dig("Country")
    end

    def country_code
      code = file_metadata&.dig("XMP-iptcCore:CountryCode") ||
             file_metadata&.dig("Country-PrimaryLocationCode")
      return nil unless code.present?

      # Ensure country code is max 2 uppercase letters (ISO 3166-1 alpha-2)
      cleaned = code.to_s.upcase.gsub(/[^A-Z]/, "")[0, 2]
      cleaned.present? ? cleaned : nil
    end

    def intellectual_genre
      file_metadata&.dig("XMP-iptcCore:IntellectualGenre")
    end

    def event
      file_metadata&.dig("XMP-iptcCore:Event") ||
      file_metadata&.dig("XMP-iptcExt:Event")
    end

    def caption_writer
      file_metadata&.dig("XMP-photoshop:CaptionWriter")
    end

    def urgency
      file_metadata&.dig("XMP-photoshop:Urgency") ||
      file_metadata&.dig("Urgency")
    end

    def category
      file_metadata&.dig("XMP-photoshop:Category") ||
      file_metadata&.dig("Category")
    end

    def sublocation
      file_metadata&.dig("XMP-iptcCore:Location")
    end

    def state_province
      file_metadata&.dig("XMP-photoshop:State") ||
      file_metadata&.dig("Province-State")
    end

    # Technical EXIF metadata
    def focal_length
      file_metadata&.dig("FocalLength")
    end

    def aperture
      file_metadata&.dig("FNumber")
    end

    def shutter_speed
      file_metadata&.dig("ExposureTime")
    end

    def iso_speed
      file_metadata&.dig("ISO")
    end

    def flash
      file_metadata&.dig("Flash")
    end

    def white_balance
      file_metadata&.dig("WhiteBalance")
    end

    def metering_mode
      file_metadata&.dig("MeteringMode")
    end

    def exposure_mode
      file_metadata&.dig("ExposureMode")
    end

    def exposure_compensation
      file_metadata&.dig("ExposureCompensation")
    end

    # People and objects metadata
    def persons_shown_from_metadata
      persons = file_metadata&.dig("XMP-iptcExt:PersonInImage")
      case persons
      when Array then persons.compact.reject(&:blank?)
      when String then [persons].compact.reject(&:blank?)
      else []
      end
    end

    alias_method :persons_shown, :persons_shown_from_metadata

    def organizations_shown_from_metadata
      orgs = file_metadata&.dig("XMP-iptcExt:OrganisationInImageName")
      case orgs
      when Array then orgs.compact.reject(&:blank?)
      when String then [orgs].compact.reject(&:blank?)
      else []
      end
    end

    alias_method :organizations_shown, :organizations_shown_from_metadata

  private
    def extract_raw_metadata_with_exiftool
      return unless file.present? && File.exist?(file.path)

      require "open3"

      base_options = Rails.application.config.folio_image_metadata_exiftool_options || ["-G1", "-struct", "-n"]
      command = ["exiftool", "-j", *base_options, file.path]
      stdout, stderr, status = Open3.capture3(*command)
      return JSON.parse(stdout).first if status.success?
      Rails.logger.warn "ExifTool error for #{file_name}: #{stderr}"
      # If initial read failed or produced mojibake, try IPTC charset candidates
      begin
        candidates = Array(Rails.application.config.folio_image_metadata_iptc_charset_candidates)
        candidates.each do |cs|
          opt = ["-charset", "iptc=#{cs}"]
          stdout, stderr, status = Open3.capture3("exiftool", "-j", *(base_options + opt), file.path)
          next unless status.success?
          parsed = JSON.parse(stdout).first
          return parsed if parsed.is_a?(Hash)
        end
      rescue => e
        Rails.logger.warn "ExifTool charset retry failed for #{file_name}: #{e.message}"
      end
      nil
    rescue JSON::ParserError => e
      Rails.logger.error "Failed to parse ExifTool output for #{file_name}: #{e.message}"
      nil
    end
end
