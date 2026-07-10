# frozen_string_literal: true

# Builds provider prompts from site prompts, user instructions, form state, and
# model data, then normalizes provider JSON into field-keyed suggestion hashes.

class Folio::Ai::TextSuggestionGenerator
  CONTEXT_MARKER = "Context JSON:"

  def initialize(record:,
                 site:,
                 record_key:,
                 form_snapshot:,
                 provider:,
                 field: nil,
                 fields: nil,
                 key: nil,
                 site_prompt: nil,
                 instructions: nil,
                 suggestion_count: Folio::Ai::DEFAULT_SUGGESTION_COUNT)
    @record = record
    @site = site
    @record_key = record_key.to_s
    @fields = normalize_fields(fields.presence || [field])
    @key = key.to_s.strip.presence || primary_field.fetch(:key)
    @form_snapshot = normalize_form_snapshot(form_snapshot)
    @provider = provider
    @site_prompt = site_prompt.to_s.strip.presence
    @instructions = instructions.to_s.strip.presence
    @suggestion_count = Folio::Ai.normalize_suggestion_count(suggestion_count)
  end

  def call
    call_by_field.fetch(primary_field.fetch(:key))
  end

  def call_by_field
    @call_by_field ||= parse_response(provider.complete(prompt:, suggestion_count:))
  end

  def prompt
    <<~TEXT.squish
      Generate #{suggestion_count} text #{suggestion_word} for each requested form field.
      Return only valid JSON in this shape: {"suggestions":[{"key":"title","text":"..."}]}.
      For each requested field key, return exactly #{suggestion_count} #{suggestion_word}.
      Use exactly the provided field keys.
      Use the form snapshot as the source of truth.
      #{CONTEXT_MARKER}
      #{JSON.pretty_generate(prompt_data)}
    TEXT
  end

  private
    attr_reader :record,
                :site,
                :record_key,
                :key,
                :fields,
                :form_snapshot,
                :provider,
                :site_prompt,
                :instructions,
                :suggestion_count

    def prompt_data
      {
        key:,
        fields: fields.map { |field| field_data(field) },
        prompt: site_prompt,
        instructions:,
        form_snapshot:,
        additional_data: additional_data.presence,
      }.compact
    end

    def primary_field
      fields.first
    end

    def fields_by_key
      @fields_by_key ||= fields.index_by { |field| field.fetch(:key) }
    end

    def field_data(field)
      field.slice(:key, :character_limit).merge(label: field_label(field)).compact
    end

    def field_label(field)
      field[:label].presence ||
        record.class.human_attribute_name(field.fetch(:key)) ||
        field.fetch(:key).humanize
    end

    def additional_data
      return unless record.respond_to?(:folio_ai_additional_data)

      record.folio_ai_additional_data(field_key: key,
                                      form_snapshot:)
    end

    def normalize_fields(fields)
      Array(fields).filter_map do |field|
        field_hash = raw_hash(field).symbolize_keys
        field_key = field_hash[:key].to_s.strip
        next if field_key.blank?

        field_hash.merge(key: field_key)
      end
    end

    def normalize_form_snapshot(value)
      raw_hash(value).each_with_object({}) do |(snapshot_key, item), hash|
        normalized = normalize_form_snapshot_value(item)
        hash[snapshot_key.to_s] = normalized if normalized.present?
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
      suggestions = response_items(raw_response).each_with_object({}) do |item, hash|
        field_key, text = suggestion_attributes(item)

        hash[field_key] ||= []
        hash[field_key] << suggestion_from(field: fields_by_key.fetch(field_key),
                                           key: hash[field_key].size + 1,
                                           text:)
      end

      fields.to_h do |field|
        field_key = field.fetch(:key)
        field_suggestions = Array(suggestions[field_key]).first(suggestion_count)
        raise Folio::Ai::ResponseError, "AI provider did not return suggestions for: #{field_key}" if field_suggestions.blank?

        [field_key, field_suggestions]
      end
    end

    def response_items(raw_response)
      parsed = JSON.parse(raw_response.to_s)

      return parsed.fetch("suggestions") if parsed.is_a?(Hash) && parsed["suggestions"].is_a?(Array)

      raise Folio::Ai::ResponseError, "AI provider response has invalid format"
    rescue JSON::ParserError
      raise Folio::Ai::ResponseError, "AI provider response is not valid JSON"
    end

    def suggestion_attributes(item)
      data = item.is_a?(Hash) ? item.with_indifferent_access : nil
      raise Folio::Ai::ResponseError, "AI provider suggestion has invalid format" unless data

      field_key = data[:key].to_s.strip
      text = data[:text].to_s.strip
      unless fields_by_key.key?(field_key) && text.present?
        raise Folio::Ai::ResponseError, "AI provider suggestion has invalid format"
      end

      [field_key, text]
    end

    def suggestion_from(field:, key:, text:)
      {
        key:,
        text:,
        character_count: text.length,
        character_limit: field[:character_limit],
        over_character_limit: over_character_limit?(field:, text:),
      }.compact
    end

    def over_character_limit?(field:, text:)
      field[:character_limit].present? && text.length > field[:character_limit].to_i
    end

    def suggestion_word
      suggestion_count == 1 ? "suggestion" : "suggestions"
    end
end
