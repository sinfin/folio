# frozen_string_literal: true

class Folio::Metadata::ExtractionJob < Folio::ApplicationJob
  queue_as :slow

  discard_on ActiveJob::DeserializationError

  unique :until_and_while_executing

  def perform(image, force: false, user_id: nil)
    @user_id = user_id
    return unless image.is_a?(Folio::File::Image)

    # Use the extraction service
    Folio::Metadata::ExtractionService.new(image).extract!(force: force, user_id: user_id)

    # Broadcast update for live refresh in console using MessageBus
    broadcast_file_update(image) if @user_id
  end

  private
    def broadcast_file_update(image)
      # Broadcast file update via MessageBus for live UI refresh
      return unless defined?(MessageBus)
      return unless @user_id

      message_data = {
        type: "Folio::File::MetadataExtracted",
        file: {
          id: image.id,
          type: image.class.name,
          attributes: serialize_file_attributes(image)
        }
      }

      MessageBus.publish(Folio::MESSAGE_BUS_CHANNEL, message_data.to_json, user_ids: [@user_id])
      Rails.logger.debug "Broadcasted metadata update for file ##{image.id} to user_ids: [#{@user_id}]"

      # Also broadcast generic file update for global listeners (parity with subtitles jobs)
      begin
        super(image)
      rescue NoMethodError
        # Parent has no broadcast method; ignore
      end
    end

    def serialize_file_attributes(image)
      # Return essential attributes for UI update including mapped_metadata for React
      {
        id: image.id,
        file_metadata_extracted_at: image.file_metadata_extracted_at&.iso8601,
        headline: image.headline,
        author: image.author,
        description: image.description,
        capture_date: image.capture_date&.iso8601,
        gps_latitude: image.gps_latitude,
        gps_longitude: image.gps_longitude,
        # Essential: Include mapped_metadata for ReadOnlyMetadataDisplay React component
        mapped_metadata: image.respond_to?(:mapped_metadata) ? image.mapped_metadata : {}
      }
    rescue => e
      Rails.logger.error "Failed to serialize file attributes for ##{image.id}: #{e.message}"
      {}
    end
end
