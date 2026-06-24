# frozen_string_literal: true

class Folio::FileSerializer
  include FastJsonapi::ObjectSerializer

  attributes :file_name,
             :file_width,
             :file_height,
             :file_mime_type,
             :author,
             :attribution_source,
             :attribution_source_url,
             :attribution_copyright,
             :attribution_licence

  attribute :human_type do |object|
    object.class.human_type
  end

  attribute :source_url do |object|
    source_payload_for(object)[:url]
  end

  attribute :extension do |object|
    Mime::Type.lookup(object.file_mime_type).symbol.to_s.upcase
  end

  attribute :player_source_mime_type do |object|
    if object.try(:processing_service) == "mux" && object.ready?
      "application/x-mpegurl"
    elsif (source_mime_type = source_mime_type_for(object))
      normalize_source_mime_type(source_mime_type)
    end
  end

  class << self
    private
      def source_payload_for(object)
        object.source_payload(intent: :cacheable)
      end

      def source_mime_type_for(object)
        source_payload_for(object)[:mime_type]
      end

      def normalize_source_mime_type(source_mime_type)
        source_mime_type.match?(%r{audio/.+-aac-.+}) ? "audio/aac" : source_mime_type
      end
  end
end
