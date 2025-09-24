# frozen_string_literal: true

module Folio
  module Embed
    SUPPORTED_TYPES = %w[
      instagram
    ]

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
      return nil if embed_data["type"].in?(SUPPORTED_TYPES) && embed_data["url"].present?

      :blank
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
