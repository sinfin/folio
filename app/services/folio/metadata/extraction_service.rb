# frozen_string_literal: true

class Folio::Metadata::ExtractionService
  def self.perform_later(image, force: false, user_id: nil)
    Folio::Metadata::ExtractionJob.perform_later(image, force: force, user_id: user_id)
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

    # Use Dragonfly's metadata (now with proper UTF-8 support)
    # For existing images with corrupted cached metadata, use fresh extraction
    metadata = needs_fresh_extraction? ? extract_fresh_metadata : @image.file.metadata
    return unless metadata.present?

    # Map and store metadata
    map_and_store_metadata(@image, metadata)

    Rails.logger.info "Successfully extracted and mapped metadata for image ##{@image.id}"
  rescue => e
    Rails.logger.error "Failed to extract metadata for #{@image.file_name}: #{e.message}"
    Rails.logger.error e.backtrace.join("\n") if Rails.env.development?
end

  # Extraction during file processing (synchronous)
  # NOTE: Dragonfly automatically calls file.metadata via after_assign callback
  # This method is kept for manual processing if needed
  def extract_during_processing!
    Rails.logger.info "Extracting metadata for #{@image.file_name} during processing..."

    # Use the same simplified extraction as the main method
    extract!(force: true)
  end

  private
    def needs_fresh_extraction?
      # Check if cached metadata might be corrupted (from old UTF-8 configuration)
      # If IPTC:Headline is missing but file likely has IPTC data, use fresh extraction
      cached_metadata = @image.file.metadata

      # If no cached metadata at all, force fresh
      return true if cached_metadata.blank?

      # If has metadata but no IPTC:Headline, likely from old analyser
      return true if cached_metadata.present? && !cached_metadata.key?("IPTC:Headline")

      # If IPTC:Headline has mojibake patterns, force fresh
      iptc_headline = cached_metadata["IPTC:Headline"]
      return true if iptc_headline&.match?(/√|ƒ|Ã|Ä|Å|â|ÄŸ|Å¡|Ã­|Ã¡|Ãº|Ã½|Ã©|õ|°/)

      false
    end

    def extract_fresh_metadata
      # Use fresh Dragonfly metadata extraction (bypasses cache)
      # This ensures we always get metadata with current UTF-8 configuration

      file_path = @image.file.path
      content = Dragonfly.app.fetch_file(file_path)
      content.metadata
    rescue => e
      Rails.logger.warn "Fresh Dragonfly extraction failed, falling back to cached: #{e.message}"
      @image.file.metadata
    end

    def should_extract?(image, force)
      return false unless Rails.application.config.folio_image_metadata_extraction_enabled
      return false unless image.is_a?(Folio::File::Image)
      return false unless image.file.present?
      return false if Rails.env.test? && ENV["FOLIO_SKIP_METADATA_EXTRACTION"] == "true"
      return false unless image.has_attribute?(:headline) && image.has_attribute?(:file_metadata)

      # Skip if already extracted (unless forced)
      return false if !force && image.file_metadata_extracted_at.present?

      true
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
      # Map metadata fields to actual database columns
      field_mapping = {
        creator: :author,
        source: :attribution_source,
        copyright_notice: :attribution_copyright,
        # Direct mappings for existing fields
        headline: :headline,
        description: :description,
        capture_date: :capture_date,
        gps_latitude: :gps_latitude,
        gps_longitude: :gps_longitude
      }

      # Update database fields if they're blank (don't override user input)
      mapped_data.each do |field, value|
        next if value.blank?

        # Get the actual database column name
        db_field = field_mapping[field] || field

        # Only update if current field is blank and the setter exists
        if image.respond_to?("#{db_field}=")
          current_value = image.send(db_field)

          # Special handling for author field - overwrite if it contains JSON array string
          if db_field == :author && current_value.present? && current_value.match?(/^\[.*\]$/)
            image.send("#{db_field}=", value)
          elsif current_value.blank?
            image.send("#{db_field}=", value)
          end
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
end
