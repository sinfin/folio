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

    sanitize_href = lambda do |href_value|
      return nil if href_value.blank?

      # Use Rails' sanitizer to check if href is safe
      test_link = "<a href=\"#{href_value}\">test</a>"
      sanitized_link = ActionController::Base.helpers.sanitize(test_link)

      # If href was stripped, it's unsafe
      if sanitized_link == "<a>test</a>"
        Rails.logger.warn "Removed unsafe href from tiptap link: #{href_value}"
        return nil
      end

      # Extract href from sanitized result
      if match = sanitized_link.match(/href="([^"]*)"/)
        return match[1]
      end

      href_value
    end

    traverse_and_scrub = lambda do |hash|
      hash.each do |key, value|
        scrubbed_key = scrub.call(key.to_s)

        case value
        when String
          # Special handling for href in link marks
          if key == "href" && hash["type"] == "link"
            hash[scrubbed_key] = sanitize_href.call(value)
          else
            hash[scrubbed_key] = scrub.call(value)
          end
        when Hash
          # Check if this is a link mark attrs hash
          if key == "attrs" && hash["type"] == "link" && value.is_a?(Hash) && value["href"]
            # Clone the attrs hash and sanitize href
            sanitized_attrs = value.dup
            sanitized_attrs["href"] = sanitize_href.call(value["href"])
            hash[scrubbed_key] = traverse_and_scrub.call(sanitized_attrs)
          else
            hash[scrubbed_key] = traverse_and_scrub.call(value)
          end
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
