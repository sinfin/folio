# frozen_string_literal: true

module Folio::MetadataExtraction
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

    did_merge_or_update = map_iptc_metadata(metadata)
    # Ensure we persist even if only tag_list changed (acts-as-taggable virtual attr)
    save if changed? || did_merge_or_update
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
      updated = false

      # ✅ Editable database columns (uses IptcFieldMapper results)
      if headline.blank? && mapped_data[:headline].present?
        self.headline = mapped_data[:headline]
        updated = true
      end
      if author.blank? && mapped_data[:creator].present?
        self.author = Array(mapped_data[:creator]).join(", ")
        updated = true
      end
      if description.blank?
        new_desc = mapped_data[:description] || mapped_data[:headline]
        if new_desc.present?
          self.description = new_desc
          updated = true
        end
      end
      if attribution_copyright.blank? && mapped_data[:copyright_notice].present?
        self.attribution_copyright = mapped_data[:copyright_notice]
        updated = true
      end
      if attribution_source.blank?
        src = mapped_data[:credit_line] || mapped_data[:source]
        if src.present?
          self.attribution_source = src
          updated = true
        end
      end

      # ✅ Essential business columns (indexed/queryable)
      if capture_date.blank? && mapped_data[:capture_date].present?
        self.capture_date = mapped_data[:capture_date]
        updated = true
      end
      if gps_latitude.blank? && mapped_data[:gps_latitude].present?
        self.gps_latitude = mapped_data[:gps_latitude]
        updated = true
      end
      if gps_longitude.blank? && mapped_data[:gps_longitude].present?
        self.gps_longitude = mapped_data[:gps_longitude]
        updated = true
      end

      # ✅ Merge keywords with existing tag_list system (no new column needed)
      should_merge = !(Rails.application.config.respond_to?(:folio_image_metadata_merge_keywords_to_tags) &&
                       Rails.application.config.folio_image_metadata_merge_keywords_to_tags == false)
      if should_merge && respond_to?(:tag_list=) && mapped_data[:keywords].present?
        begin
          # Normalize: strings, stripped, lowercase for consistency
          existing_tags = Array(tag_list.to_a).map { |t| t.to_s.strip.downcase }.reject(&:blank?)
          keywords = Array(mapped_data[:keywords]).map { |t| t.to_s.strip.downcase }.reject(&:blank?)

          # Case-insensitive union preserving order (existing first)
          seen = {}
          combined = []
          (existing_tags + keywords).each do |t|
            key = t
            next if key.blank? || seen[key]
            seen[key] = true
            combined << t
          end

          if combined != existing_tags
            self.tag_list = combined
            updated = true
          end
        rescue => e
          Rails.logger.warn("Failed to merge keywords into tag_list for #{file_name}: #{e.message}")
        end
      end

      updated
    end

  # Thin orchestration layer - delegate to metadata extractor service
  public

    # Single point of access to metadata extraction service (app-configurable)
    def metadata_extractor(locale: nil)
      # Use provided locale or current I18n.locale
      effective_locale = locale || I18n.locale

      # Cache extractor per locale to avoid recreation
      @metadata_extractors ||= {}
      @metadata_extractors[effective_locale] ||= begin
        extractor_class = if Rails.application.config.respond_to?(:folio_image_metadata_extractor_class)
          Rails.application.config.folio_image_metadata_extractor_class
        else
          Folio::Metadata::Extractor
        end
        extractor_class ||= Folio::Metadata::Extractor
        extractor_class.new(self, locale: effective_locale)
      end
    end

    # Dynamic delegation to metadata extractor for all metadata fields
    def method_missing(method_name, *args, &block)
      if metadata_method?(method_name)
        # Image files: delegate to extractor service
        if is_a?(Folio::File::Image)
          metadata_extractor.public_send(method_name, *args, &block)
        else
          # Non-image files: return appropriate fallback
          metadata_fallback_value(method_name)
        end
      else
        super
      end
    end

    def respond_to_missing?(method_name, include_private = false)
      metadata_method?(method_name) || super
    end

    # Explicit aliases for backward compatibility (work with dynamic methods)
    def source
      source_from_metadata
    end

    def keywords
      keywords_from_metadata
    end

    def persons_shown
      persons_shown_from_metadata
    end

    def organizations_shown
      organizations_shown_from_metadata
    end

    private
      # Check if method should be delegated to metadata extractor
      def metadata_method?(method_name)
        # Universal check: works with custom fields from config too!
        method_str = method_name.to_s
        field_name = method_str.gsub("_from_metadata", "").to_sym

        # Check against effective mappings (includes custom app fields)
        mapper_fields = Folio::Metadata::IptcFieldMapper.effective_field_mappings
        mapper_fields.key?(field_name) ||
        method_str.end_with?("_from_metadata") ||
        known_metadata_methods.include?(method_name) ||
        (is_a?(Folio::File::Image) && metadata_extractor.respond_to?(method_name))
      end

      # Return appropriate fallback value for non-image metadata methods
      def metadata_fallback_value(method_name)
        method_str = method_name.to_s

        # Array methods return empty array
        if method_str.include?("codes") || %w[creator keywords persons_shown organizations_shown].include?(method_str)
          []
        # Boolean methods return nil/false
        elsif method_str.include?("marked") || method_str.include?("required")
          nil
        # Everything else returns nil
        else
          nil
        end
      end

      # Known metadata method names for universal fallback
      def known_metadata_methods
        @known_metadata_methods ||= [
          :creator, :credit_line, :copyright_notice, :copyright_marked, :usage_terms,
          :rights_usage_info, :subject_codes, :scene_codes, :location_created,
          :location_shown, :orientation, :camera_make, :camera_model, :lens_info,
          :city, :country, :country_code, :intellectual_genre, :event, :caption_writer,
          :urgency, :category, :sublocation, :state_province, :focal_length, :aperture,
          :shutter_speed, :iso_speed, :flash, :white_balance, :metering_mode,
          :exposure_mode, :exposure_compensation, :software, :source, :keywords,
          :headline_from_metadata, :description_from_metadata, :capture_date_from_metadata,
          :source_from_metadata, :keywords_from_metadata, :persons_shown_from_metadata,
          :organizations_shown_from_metadata
        ].to_set
      end

  private
    def extract_raw_metadata_with_exiftool
      return unless file.present?

      file_path = nil
      if file.respond_to?(:path) && file.path && File.exist?(file.path)
        file_path = file.path
      elsif file.respond_to?(:temp_object)
        begin
          tmp = file.temp_object
          file_path = tmp.path if tmp && tmp.respond_to?(:path) && tmp.path && File.exist?(tmp.path)
        rescue
          file_path = nil
        end
      end

      return unless file_path

      require "open3"

      base_options = Rails.application.config.folio_image_metadata_exiftool_options || ["-G1", "-struct", "-n"]
      command = ["exiftool", "-j", *base_options, file_path]
      stdout, stderr, status = Open3.capture3(*command)
      return JSON.parse(stdout).first if status.success?
      Rails.logger.warn "ExifTool error for #{file_name}: #{stderr}"
      # If initial read failed or produced mojibake, try IPTC charset candidates
      begin
        candidates = Array(Rails.application.config.folio_image_metadata_iptc_charset_candidates)
        candidates.each do |cs|
          opt = ["-charset", "iptc=#{cs}"]
          stdout, stderr, status = Open3.capture3("exiftool", "-j", *(base_options + opt), file_path)
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
