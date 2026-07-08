# frozen_string_literal: true

class Folio::Ai::BatchResponseNormalizer
  def initialize(raw_response:,
                 fields:,
                 suggestion_count: 1)
    @raw_response = raw_response
    @fields = normalize_fields(fields)
    @suggestion_count = suggestion_count
  end

  def call
    suggestions_by_field = normalized_suggestions_by_field

    fields.each_with_object({}) do |(key, field), hash|
      items = suggestions_by_field[key]
      raise Folio::Ai::ResponseInvalidError, "AI provider omitted suggestions for #{key}" if items.blank?

      hash[key] = Folio::Ai::ResponseNormalizer.new(raw_response: items,
                                                    field:,
                                                    suggestion_count:).call
    end
  end

  private
    attr_reader :raw_response,
                :fields,
                :suggestion_count

    def normalize_fields(value)
      case value
      when Hash
        value.transform_keys(&:to_s)
      else
        Array(value).index_by { |field| field.key.to_s }
      end
    end

    def normalized_suggestions_by_field
      source = response_source

      case source
      when Hash
        normalize_hash_source(source)
      when Array
        normalize_array_source(source)
      else
        raise Folio::Ai::ResponseInvalidError, "AI provider response has invalid batch format"
      end
    end

    def response_source
      case parsed_response
      when Hash
        parsed_response["suggestions_by_field"] ||
          parsed_response["suggestionsByField"] ||
          parsed_response["fields"] ||
          parsed_response["suggestions"] ||
          parsed_response
      else
        parsed_response
      end
    end

    def parsed_response
      return raw_response unless raw_response.is_a?(String)

      JSON.parse(raw_response)
    rescue JSON::ParserError => e
      raise Folio::Ai::ResponseInvalidError, "AI provider response is not valid JSON: #{e.message}"
    end

    def normalize_hash_source(source)
      source.each_with_object({}) do |(key, value), hash|
        field_key = key.to_s
        next unless fields.key?(field_key)

        hash[field_key] = normalize_items(value)
      end
    end

    def normalize_array_source(source)
      source.each_with_object({}) do |item, hash|
        data = normalize_item_hash(item)
        field_key = field_key_for(data)
        next if field_key.blank?
        next unless fields.key?(field_key)

        hash[field_key] = normalize_items(data["suggestions"] || data[:suggestions] || data["items"] || data[:items] || data)
      end
    end

    def normalize_items(value)
      case value
      when Hash
        items = value["suggestions"] || value[:suggestions] || value["items"] || value[:items]
        return normalize_items(items) if items

        if value.key?("text") || value.key?(:text)
          [value]
        else
          Array(value.values).presence || [value]
        end
      when Array
        value
      else
        [value]
      end
    end

    def normalize_item_hash(item)
      item.respond_to?(:to_h) ? item.to_h.with_indifferent_access : {}
    end

    def field_key_for(data)
      (data["key"] || data[:key] || data["field_key"] || data[:field_key] || data["field"] || data[:field]).to_s
    end
end
