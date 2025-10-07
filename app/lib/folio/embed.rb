# frozen_string_literal: true

module Folio
  module Embed
    SUPPORTED_TYPES = {
      "instagram" => %r{https://(?:www\.)?instagram\.com/(?:p|reel)/([a-zA-Z0-9\-_]+)/?},
      "pinterest" => %r{https://(?:\w+\.)?pinterest\.com/pin/(?:[^/]*--)?([0-9]+)/?},
      "twitter" => %r{https://(?:www\.)?(?:twitter\.com|x\.com)/[a-zA-Z0-9\-_]+/status/([0-9]+)/?},
      "youtube" => %r{https://(?:www\.youtube\.com/watch\?v=|youtu\.be/)([a-zA-Z0-9\-_]+)/?},
    }

    TYPE_REGEX = Regexp.new(
      "^(" +
      SUPPORTED_TYPES.map do |type, regex|
        "(?<#{type}>#{regex.source})"
      end.join("|") +
      ")$",
      Regexp::EXTENDED
    )

    def self.validate_record(record:, attribute_name: :embed_data)
      embed_data = record.send(attribute_name)

      if embed_data.blank?
        record.errors.add(attribute_name, :blank)
        return
      end

      if invalid_reason = invalid_reason_for(embed_data)
        record.errors.add(attribute_name, invalid_reason)
      end
    end

    def self.invalid_reason_for(embed_data)
      return :blank if embed_data.blank?
      return :invalid unless embed_data.is_a?(Hash)
      return :blank unless embed_data["active"] == true

      return nil if embed_data["html"].present?

      type = embed_data["type"].presence
      if type.in?(SUPPORTED_TYPES.keys)
        if SUPPORTED_TYPES[type].match?(embed_data["url"])
          return nil
        else
          return :invalid
        end
      end

      :blank
    end

    def self.url_type(url)
      match = TYPE_REGEX.match(url)
      return nil unless match

      # Find which named capture group matched
      match.named_captures.find { |name, value| value&.present? }&.first
    end

    def self.hash_strong_params_keys
      %i[
        active
        html
        type
        url
      ]
    end

    def self.normalize_value(value)
      if value.is_a?(Hash)
        active = value["active"].in?([true, "true"])

        if active
          {
            "active" => active,
            "html" => value["html"].presence,
            "type" => value["type"].presence,
            "url" => value["url"].presence,
          }.compact
        else
          nil
        end
      else
        nil
      end
    end
  end
end
