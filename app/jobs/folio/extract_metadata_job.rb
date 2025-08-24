# frozen_string_literal: true

class Folio::ExtractMetadataJob < ApplicationJob
  queue_as :low

  def perform(image, force: false)
    return unless image.is_a?(Folio::File::Image)
    return unless image.should_extract_metadata?

    # Skip if metadata already extracted (unless forced)
    if !force && image.respond_to?(:file_metadata_extracted_at) && image.file_metadata_extracted_at.present?
      return
    end

    Rails.logger.info "Extracting metadata for image ##{image.id} (#{image.file_name})"

    metadata = extract_raw_metadata_with_exiftool(image)
    return unless metadata.present?

    mapped_fields = Folio::Metadata::IptcFieldMapper.map_metadata(metadata)

    # Only update blank fields (preserve user edits)
    update_fields = {}
    skip_fields = Rails.application.config.folio_image_metadata_skip_fields || []

    mapped_fields.each do |field, value|
      next if skip_fields.include?(field)

      # Check if field is blank (handles both nil and empty arrays/strings)
      current_value = image.send(field) rescue nil
      is_blank = current_value.blank? || (current_value.is_a?(Array) && current_value.empty?)

      if is_blank && value.present?
        update_fields[field] = value
      end
    end

    if update_fields.any?
      if image.respond_to?(:file_metadata_extracted_at)
        update_fields[:file_metadata_extracted_at] = Time.current
      end

      image.update!(update_fields)
      Rails.logger.info "Updated #{update_fields.keys.count} metadata fields for image ##{image.id}"

      # Broadcast update for live refresh in console
      broadcast_file_update(image) if respond_to?(:broadcast_file_update, true)
    else
      Rails.logger.debug "No metadata updates needed for image ##{image.id}"
    end

    # Cache raw metadata for future use
    if image.respond_to?(:file_metadata) && !image.file_metadata.present?
      image.update_column(:file_metadata, metadata)
    end

  rescue => e
    Rails.logger.error "Metadata extraction failed for file ##{image.id}: #{e.message}"
    Rails.logger.error e.backtrace.join("\n") if Rails.env.development?

    # Don't retry automatically - metadata extraction is not critical
    # Applications can implement retry logic in their error handling
  end

  private
    def extract_raw_metadata_with_exiftool(image)
      return unless image.file.present?

      file_path = case image.file
                  when String
                    image.file
                  else
                    image.file.respond_to?(:path) ? image.file.path : nil
      end

      return unless file_path && File.exist?(file_path)

      require "open3"

      options = Rails.application.config.folio_image_metadata_exiftool_options || ["-G1", "-struct", "-n"]
      command = ["exiftool", "-j", *options, file_path]

      stdout, stderr, status = Open3.capture3(*command)

      if status.success?
        JSON.parse(stdout).first
      else
        Rails.logger.warn "ExifTool error for #{image.file_name}: #{stderr}"
        nil
      end
    rescue JSON::ParserError => e
      Rails.logger.error "Failed to parse ExifTool output for #{image.file_name}: #{e.message}"
      nil
    end
end
