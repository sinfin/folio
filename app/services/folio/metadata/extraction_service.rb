# frozen_string_literal: true

class Folio::Metadata::ExtractionService
  def self.perform_later(image, force: false, user_id: nil)
    Folio::ExtractMetadataJob.perform_later(image, force: force, user_id: user_id)
  end

  def self.should_extract?(image)
    return false unless Rails.application.config.folio_image_metadata_extraction_enabled
    return false unless image.file.present?
    return false if Rails.env.test? && ENV["FOLIO_SKIP_METADATA_EXTRACTION"] == "true"
    image.has_attribute?(:headline) && image.has_attribute?(:file_metadata)
  end

  def self.extract_async(image)
    if defined?(ActiveJob) && Rails.application.config.active_job.queue_adapter != :test
      perform_later(image)
    else
      new(image).extract!
    end
  end

  def initialize(image)
    @image = image
  end

  def extract!(force: false, user_id: nil)
    return unless should_extract?(@image, force)

    Rails.logger.info "Extracting metadata for image ##{@image.id} (#{@image.file_name})"

    # Extract raw metadata using exiftool
    metadata = extract_raw_metadata_with_exiftool
    return unless metadata.present?

    # Map and store metadata
    map_and_store_metadata(@image, metadata)

    Rails.logger.info "Successfully extracted and mapped metadata for image ##{@image.id}"
  rescue => e
    Rails.logger.error "Failed to extract metadata for #{@image.file_name}: #{e.message}"
    Rails.logger.error e.backtrace.join("\n") if Rails.env.development?
  end

  # Extraction during file processing (synchronous)
  def extract_during_processing!
    return unless should_extract_during_processing?(@image)

    Rails.logger.info "Extracting metadata for #{@image.file_name} during processing..."

    # For S3/remote files, we need to download temporarily to extract metadata
    file_path = get_file_path_for_extraction(@image)
    return unless file_path && File.exist?(file_path)

    require "open3"

    base_options = Rails.application.config.folio_image_metadata_exiftool_options || ["-G1", "-struct", "-n"]
    charset_options = ["-charset", "iptc=utf8"]
    command = ["exiftool", "-j", *base_options, *charset_options, file_path]

    Rails.logger.debug "ExifTool command: #{command.join(' ')}"

    stdout, stderr, status = Open3.capture3(*command)

    if status.success?
      raw_metadata = JSON.parse(stdout).first
      if raw_metadata.present?
        map_and_store_metadata(@image, raw_metadata)
        Rails.logger.info "Successfully extracted metadata for #{@image.file_name} with UTF-8 charset"
      else
        Rails.logger.warn "No metadata found for #{@image.file_name}"
      end
    else
      Rails.logger.warn "ExifTool error for #{@image.file_name}: #{stderr}"
    end
  rescue => e
    Rails.logger.error "Failed to extract metadata during processing for #{@image.file_name}: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
  end

  private
    def should_extract?(image, force)
      return false unless Rails.application.config.folio_image_metadata_extraction_enabled
      return false unless image.is_a?(Folio::File::Image)
      return false unless image.file.present?
      return false if Rails.env.test? && ENV["FOLIO_SKIP_METADATA_EXTRACTION"] == "true"

      # Skip if already extracted (unless forced)
      if !force && image.respond_to?(:file_metadata_extracted_at) && image.file_metadata_extracted_at.present?
        return false
      end

      # Check if exiftool is available
      system("which exiftool > /dev/null 2>&1")
    end

    def extract_raw_metadata_with_exiftool
      return unless @image.file.present?

      file_path = case @image.file
                  when String
                    @image.file
                  else
                    @image.file.respond_to?(:path) ? @image.file.path : nil
      end

      return unless file_path && File.exist?(file_path)

      require "open3"

      base_options = Rails.application.config.folio_image_metadata_exiftool_options || ["-G1", "-struct", "-n"]
      charset_options = ["-charset", "iptc=utf8"]
      command = ["exiftool", "-j", *base_options, *charset_options, file_path]

      stdout, stderr, status = Open3.capture3(*command)

      if status.success?
        JSON.parse(stdout).first
      else
        Rails.logger.warn "ExifTool error for #{@image.file_name}: #{stderr}"
        nil
      end
    rescue JSON::ParserError => e
      Rails.logger.error "Failed to parse ExifTool output for #{@image.file_name}: #{e.message}"
      nil
    end

    def map_and_store_metadata(image, raw_metadata)
      # Store raw metadata in JSON column
      image.file_metadata = raw_metadata
      image.file_metadata_extracted_at = Time.current

      # Map using existing field mapper
      mapped_data = Folio::Metadata::IptcFieldMapper.map_metadata(raw_metadata)

      # Store processed metadata in JSON for getters (key part!)
      store_processed_metadata_for_getters(image, mapped_data)

      # Update database fields from mapped data
      update_database_fields(image, mapped_data)

      # Merge keywords into tag_list if configured
      merge_keywords_to_tags(image, mapped_data)

      # Save changes
      image.save! if image.changed?
    end

    def update_database_fields(image, mapped_data)
      # Update database fields if they're blank (don't override user input)
      mapped_data.each do |field, value|
        next if value.blank?

        # Only update if current field is blank
        if image.respond_to?("#{field}=") && image.send(field).blank?
          image.send("#{field}=", value)
        end
      end
    end

    def store_processed_metadata_for_getters(image, mapped_data)
      # Store processed (UTF-8) values in file_metadata for JSON getters
      # This ensures getters return clean UTF-8 data instead of raw mojibake

      mapped_data.each do |field, value|
        next if value.blank?
        image.file_metadata[field.to_s] = value
      end
    end

    def merge_keywords_to_tags(image, mapped_data)
      # Merge keywords into tag_list if configured and available
      if Rails.application.config.respond_to?(:folio_image_metadata_merge_keywords_to_tags) &&
         Rails.application.config.folio_image_metadata_merge_keywords_to_tags &&
         mapped_data[:keywords].present?

        # Get existing tags and merge with new keywords
        existing_tags = image.tag_list || []
        new_keywords = mapped_data[:keywords].map(&:to_s).map(&:strip).reject(&:blank?)

        # Merge and deduplicate (case-insensitive)
        merged_tags = (existing_tags + new_keywords).uniq { |tag| tag.downcase }

        image.tag_list = merged_tags
      end
    end

    def should_extract_during_processing?(image)
      return false unless Rails.application.config.folio_image_metadata_extraction_enabled
      return false unless image.file.present? && (image.file.respond_to?(:path) || image.file.is_a?(String))
      return false if Rails.env.test? && ENV["FOLIO_SKIP_METADATA_EXTRACTION"] == "true"
      return false unless image.has_attribute?(:headline) && image.has_attribute?(:file_metadata)
      return false if image.file_metadata_extracted_at.present?

      # Check if exiftool is available
      system("which exiftool > /dev/null 2>&1")
    end

    def get_file_path_for_extraction(image)
      # During processing, the file should still be available locally via Dragonfly
      if image.file.respond_to?(:path) && image.file.path
        image.file.path
      elsif image.file.respond_to?(:url) && image.file.url
        # For remote files, try to get temp file path from Dragonfly
        begin
          image.file.temp_object.path if image.file.respond_to?(:temp_object) && image.file.temp_object
        rescue
          nil
        end
      end
    end
end
