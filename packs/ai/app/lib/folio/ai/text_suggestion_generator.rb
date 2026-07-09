# frozen_string_literal: true

# Builds provider prompts from site prompts, user instructions, form state, and
# model data, then normalizes provider JSON into suggestion hashes.

class Folio::Ai::TextSuggestionGenerator
  CONTEXT_MARKER = "Context JSON:"

  def initialize(record:, site:, record_key:, field:, form_snapshot:, provider:, site_prompt: nil, instructions: nil, suggestion_count: Folio::Ai::DEFAULT_SUGGESTION_COUNT)
    @record = record
    @site = site
    @record_key = record_key.to_s
    @field = field.symbolize_keys
    @form_snapshot = normalize_form_snapshot(form_snapshot)
    @provider = provider
    @site_prompt = site_prompt.to_s.strip.presence
    @instructions = instructions.to_s.strip.presence
    @suggestion_count = suggestion_count.to_i.positive? ? suggestion_count.to_i : Folio::Ai::DEFAULT_SUGGESTION_COUNT
  end

  def call
    parse_response(provider.complete(prompt:, suggestion_count:)).first(suggestion_count)
  end

  def prompt
    <<~TEXT.squish
      Generate #{suggestion_count} text suggestions for the requested form field.
      Return only valid JSON in this shape: {"suggestions":[{"text":"..."}]}.
      Use the form snapshot as the source of truth.
      #{CONTEXT_MARKER}
      #{JSON.pretty_generate(prompt_data)}
    TEXT
  end

  private
    attr_reader :record,
                :site,
                :record_key,
                :field,
                :form_snapshot,
                :provider,
                :site_prompt,
                :instructions,
                :suggestion_count

    def prompt_data
      {
        field: field_data,
        prompt: site_prompt,
        instructions:,
        form_snapshot:,
        additional_data: additional_data.presence,
      }.compact
    end

    def field_data
      field.slice(:key, :character_limit).merge(label: field_label).compact
    end

    def field_label
      field[:label].presence ||
        record.class.human_attribute_name(field.fetch(:key)) ||
        field.fetch(:key).humanize
    end

    def additional_data
      return unless record.respond_to?(:folio_ai_additional_data)

      record.folio_ai_additional_data(field_key: field.fetch(:key),
                                      form_snapshot:)
    end

    def normalize_form_snapshot(value)
      raw_hash(value).each_with_object({}) do |(key, item), hash|
        normalized = normalize_form_snapshot_value(item)
        hash[key.to_s] = normalized if normalized.present?
      end
    end

    def raw_hash(value)
      value = value.to_unsafe_h if value.respond_to?(:to_unsafe_h)
      value.respond_to?(:to_h) ? value.to_h : {}
    end

    def normalize_form_snapshot_value(value)
      case value
      when Hash
        value
      when Array
        value.compact_blank
      else
        value.to_s.strip
      end
    end

    def parse_response(raw_response)
      suggestions = response_items(raw_response).filter_map.with_index do |item, index|
        suggestion_from(item, index)
      end

      raise Folio::Ai::ResponseError, "AI provider returned no suggestions" if suggestions.blank?

      suggestions
    end

    def response_items(raw_response)
      parsed = JSON.parse(raw_response.to_s)

      case parsed
      when Hash
        Array(parsed["suggestions"])
      when Array
        parsed
      else
        raise Folio::Ai::ResponseError, "AI provider response has invalid format"
      end
    rescue JSON::ParserError
      raise Folio::Ai::ResponseError, "AI provider response is not valid JSON"
    end

    def suggestion_from(item, index)
      data = item.is_a?(Hash) ? item.symbolize_keys : { text: item }
      text = data[:text].to_s.strip
      return if text.blank?

      {
        key: data[:key].presence || index + 1,
        text:,
        character_count: text.length,
        character_limit: field[:character_limit],
        over_character_limit: over_character_limit?(text),
      }.compact
    end

    def over_character_limit?(text)
      field[:character_limit].present? && text.length > field[:character_limit].to_i
    end
end
