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

      unless valid_data?(embed_data)
        record.errors.add(attribute_name, :invalid)
      end
    end

    def self.valid_data?(embed_data)
      return false if embed_data.blank?
      return false unless embed_data.is_a?(Hash)
      return false unless embed_data["active"] == true

      return true if embed_data["html"].present?
      return true if embed_data["type"].in?(SUPPORTED_TYPES) && embed_data["url"].present?

      false
    end

    def self.hash_strong_params_keys
      %i[
        active
        html
        type
        url
      ]
    end

    def self.normalize_setter_value(value)
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
