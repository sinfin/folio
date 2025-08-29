# frozen_string_literal: true

class Folio::Tiptap::Content
  def initialize(record:)
    @record = record
  end

  def convert_and_sanitize_value(value)
    return { ok: true, value: nil } if value.nil?

    hash_value = nil

    if value.is_a?(Hash)
      hash_value = value
    elsif value.is_a?(String)
      begin
        hash_value = JSON.parse(value)
      rescue JSON::ParserError
        Rails.logger.error "Did not assign an invalid JSON string: #{value}"
      end
    else
      Rails.logger.error "Did not assign an invalid value type: #{value.class.name} / #{value}"
    end

    return { ok: false } if hash_value.nil?

    content_key = Folio::Tiptap::TIPTAP_CONTENT_JSON_STRUCTURE[:content]
    if hash_value[content_key].is_a?(String)
      begin
        hash_value[content_key] = JSON.parse(hash_value[content_key])
      rescue JSON::ParserError
        hash_value[content_key] = nil
        Rails.logger.error "Did not assign an invalid JSON string: #{value}"
      end
    end

    scrub = lambda do |string|
      scrubbed = Loofah.fragment(string).text(encode_special_chars: false)

      if scrubbed != string
        Rails.logger.warn "Scrubbed HTML from tiptap value: #{string} -> #{scrubbed}"
      end

      scrubbed
    end

    traverse_and_scrub = lambda do |hash|
      hash.each do |key, value|
        scrubbed_key = scrub.call(key.to_s)

        case value
        when String
          hash[scrubbed_key] = scrub.call(value)
        when Hash
          hash[scrubbed_key] = traverse_and_scrub.call(value)
        when Array
          hash[scrubbed_key] = value.map do |item|
            if item.is_a?(String)
              scrub.call(item)
            elsif item.is_a?(Hash)
              traverse_and_scrub.call(item)
            else
              item
            end
          end
        when NilClass, TrueClass, FalseClass, Numeric
          hash[scrubbed_key] = value
        else
          Rails.logger.error "Did not scrub an unsupported value type for #{self} / #{field}: #{value.class.name}"
          hash[scrubbed_key] = value
        end
      end
    end

    {
      ok: true,
      value: traverse_and_scrub.call(hash_value),
    }
  end
end
