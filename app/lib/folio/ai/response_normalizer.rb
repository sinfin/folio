# frozen_string_literal: true

class Folio::Ai::ResponseNormalizer
  DEFAULT_SUGGESTION_COUNT = 3

  def initialize(raw_response:, field:, suggestion_count: DEFAULT_SUGGESTION_COUNT)
    @raw_response = raw_response
    @field = field
    @suggestion_count = suggestion_count
  end

  def call
    suggestions = normalized_items.first(suggestion_count).filter_map.with_index do |item, index|
      normalize_suggestion(item, index)
    end

    raise Folio::Ai::ResponseInvalidError, "AI provider returned no suggestions" if suggestions.blank?

    suggestions
  end

  private
    attr_reader :raw_response,
                :field,
                :suggestion_count

    def normalized_items
      case parsed_response
      when Hash
        Array(parsed_response["suggestions"] || parsed_response[:suggestions])
      when Array
        parsed_response
      else
        raise Folio::Ai::ResponseInvalidError, "AI provider response has invalid format"
      end
    end

    def parsed_response
      return raw_response unless raw_response.is_a?(String)

      JSON.parse(raw_response)
    rescue JSON::ParserError => e
      raise Folio::Ai::ResponseInvalidError, "AI provider response is not valid JSON: #{e.message}"
    end

    def normalize_suggestion(item, index)
      data = normalize_item(item)
      text = data[:text].to_s.strip

      return if text.blank?

      Folio::Ai::Suggestion.new(key: data[:key].presence || (index + 1),
                                text:,
                                char_count: data[:char_count],
                                meta: suggestion_meta(data[:meta], text))
    end

    def normalize_item(item)
      case item
      when Hash
        item.symbolize_keys.slice(:key, :text, :char_count, :meta)
      else
        { text: item }
      end
    end

    def suggestion_meta(meta, text)
      meta = (meta || {}).deep_symbolize_keys

      if field.character_limit.present? && text.length > field.character_limit
        meta[:over_limit] = true
        meta[:character_limit] = field.character_limit
      end

      meta
    end
end
