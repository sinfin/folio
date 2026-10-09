# frozen_string_literal: true

module Folio::Metadata
  class AudioFieldMapper
    # Maps file_metadata JSON string keys to symbolic mapped_metadata keys
    METADATA_FIELDS = %w[
      title
      artist
      album
      track
      codec_name
      bitrate_kbps
      sample_rate_hz
      channels
      duration_seconds
      artwork_present
    ].freeze

    # Maps mapped_metadata symbolic keys to DB columns (only if blank)
    DB_FIELD_MAPPING = {
      artist: :author,
      title: :headline,
    }.freeze

    class << self
      def map_metadata(file_metadata)
        file_metadata.to_h.slice(*METADATA_FIELDS).compact.symbolize_keys
      end

      def update_database_fields(audio_file, mapped_data)
        db_updates = {}

        DB_FIELD_MAPPING.each do |source, db_field|
          value = mapped_data[source]
          next if value.blank?
          next if audio_file.send(db_field).present?

          db_updates[db_field] = value
        end

        return if db_updates.empty?

        audio_file.update_columns(db_updates)
        audio_file.assign_attributes(db_updates)
      end
    end
  end
end
