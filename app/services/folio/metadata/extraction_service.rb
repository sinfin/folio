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

    # Use Dragonfly's built-in metadata extraction (works for local + S3)
    metadata = @image.file.metadata
    return unless metadata.present?

    # Map and store metadata
    map_and_store_metadata(@image, metadata)

    Rails.logger.info "Successfully extracted and mapped metadata for image ##{@image.id}"
  rescue => e
    Rails.logger.error "Failed to extract metadata for #{@image.file_name}: #{e.message}"
    Rails.logger.error e.backtrace.join("\n") if Rails.env.development?
end

  private
    def should_extract?(image, force)
      # Use class method for basic validation
      return false unless image.is_a?(Folio::File::Image)
      return false unless self.class.should_extract?(image)

      # Instance-specific logic: skip if already extracted (unless forced)
      return false if !force && image.file_metadata_extracted_at.present?

      true
    end

    def map_and_store_metadata(image, raw_metadata)
      # Store raw metadata in JSON column
      image.file_metadata = raw_metadata
      image.file_metadata_extracted_at = Time.current

      # Map using existing field mapper (with encoding fixes)
      mapped_data = Folio::Metadata::IptcFieldMapper.map_metadata(raw_metadata)

      # Store processed metadata in JSON for getters
      store_processed_metadata_for_getters(image, mapped_data)

      # Update database fields from mapped data
      update_database_fields(image, mapped_data)

      # Save changes (without tags first)
      image.save! if image.changed?

      # Handle tags separately - if they fail, continue anyway
      handle_tags_separately(image, mapped_data)
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
          else
            # Check if current value has mojibake and new value is better quality
            current_quality = Folio::Metadata::IptcFieldMapper.send(:score_cs, current_value.to_s)
            new_quality = Folio::Metadata::IptcFieldMapper.send(:score_cs, value.to_s)

            if new_quality > current_quality
              Rails.logger.info "Updating #{db_field} due to better encoding quality (#{current_quality} -> #{new_quality})"
              image.send("#{db_field}=", value)
            end
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

    def handle_tags_separately(image, mapped_data)
      return unless Rails.application.config.respond_to?(:folio_image_metadata_merge_keywords_to_tags) &&
                    Rails.application.config.folio_image_metadata_merge_keywords_to_tags &&
                    mapped_data[:keywords].present?

      existing_tags = image.tag_list || []
      new_keywords = mapped_data[:keywords].map(&:to_s).map(&:strip).reject(&:blank?)
      merged_tags = (existing_tags + new_keywords).uniq { |tag| tag.downcase }

      # 1. Try to save all tags at once
      begin
        image.tag_list = merged_tags
        image.save!
        Rails.logger.info "Successfully added #{merged_tags.size} tags to image ##{image.id}"
        return
      rescue => e
        Rails.logger.warn "Failed to save all tags for image ##{image.id}: #{e.message}. Trying one by one..."
      end

      # 2. If that fails, try one by one and ignore failures
      successful_tags = existing_tags.dup
      new_keywords.each do |tag|
        test_tags = successful_tags + [tag]
        image.tag_list = test_tags
        image.save!
        successful_tags << tag
      rescue => e
        Rails.logger.warn "Skipping problematic tag '#{tag}' for image ##{image.id}: #{e.message}"
      end

      Rails.logger.info "Successfully added #{successful_tags.size - existing_tags.size} of #{new_keywords.size} new tags to image ##{image.id}"
    end
end
