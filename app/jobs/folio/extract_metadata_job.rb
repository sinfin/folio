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

    Rails.logger.info "Extracting metadata for image ##{image.id} (#{image.file_name}) asynchronously"

    # Use our UTF-8 corrected extraction logic
    metadata = extract_raw_metadata_with_exiftool(image)
    return unless metadata.present?

    # Use the same logic as synchronous extraction
    image.map_iptc_metadata(metadata)
    image.save! if image.changed?

    Rails.logger.info "Successfully extracted and mapped metadata for image ##{image.id}"

    # Broadcast update for live refresh in console using MessageBus
    broadcast_file_update(image)

  rescue => e
    Rails.logger.error "Metadata extraction failed for file ##{image.id}: #{e.message}"
    Rails.logger.error e.backtrace.join("\n") if Rails.env.development?

    # Don't retry automatically - metadata extraction is not critical
    # Applications can implement retry logic in their error handling
  end

  private
    def broadcast_file_update(image)
      # Broadcast file update via MessageBus for live UI refresh
      return unless defined?(MessageBus)
      return if message_bus_user_ids.blank?

      message_data = {
        type: "Folio::File::MetadataExtracted",
        file: {
          id: image.id,
          type: image.class.name,
          attributes: serialize_file_attributes(image)
        }
      }

      MessageBus.publish(Folio::MESSAGE_BUS_CHANNEL, message_data.to_json, user_ids: message_bus_user_ids)
      Rails.logger.debug "Broadcasted metadata update for file ##{image.id} to user_ids: #{message_bus_user_ids}"

      # Also broadcast generic file update for global listeners (parity with subtitles jobs)
      begin
        super(image)
      rescue NoMethodError
        # Parent has no broadcast method; ignore
      end
    end

    def serialize_file_attributes(image)
      # Return essential attributes for UI update
      {
        id: image.id,
        headline: image.headline,
        creator: image.creator,
        credit_line: image.credit_line,
        copyright_notice: image.copyright_notice,
        keywords_from_metadata: image.keywords_from_metadata,
        headline_from_metadata: image.headline_from_metadata,
        file_metadata_extracted_at: image.file_metadata_extracted_at&.iso8601,
        # Add other metadata fields as needed
      }
    rescue => e
      Rails.logger.error "Failed to serialize file attributes for ##{image.id}: #{e.message}"
      {}
    end

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

      base_options = Rails.application.config.folio_image_metadata_exiftool_options || ["-G1", "-struct", "-n"]
      charset_options = ["-charset", "iptc=utf8"]
      command = ["exiftool", "-j", *base_options, *charset_options, file_path]

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
