# frozen_string_literal: true

class Folio::Tiptap::Content
  def initialize(record:)
    @record = record
  end

  def convert_and_sanitize_value(value)
    return { ok: true, value: nil } if value.blank?

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

    {
      ok: true,
      value: traverse_and_scrub(hash_value.deep_dup),
    }
  end

  private
    def sanitize_folio_tiptap_node(data)
      {
        "type" => data["type"],
        "attrs" => sanitize_tiptap_node_attrs(data["attrs"]),
      }
    end

    def sanitize_tiptap_node_attrs(attrs, expected_class: nil)
      return traverse_and_scrub(attrs) unless attrs.is_a?(Hash)

      node_klass = attrs["type"].safe_constantize
      return traverse_and_scrub(attrs) if expected_class && node_klass != expected_class

      {
        "type" => attrs["type"],
        "version" => attrs["version"].is_a?(Integer) ? attrs["version"] : 1,
        "data" => sanitize_tiptap_node_data(attrs["data"], node_klass),
      }
    end

    def sanitize_tiptap_node_data(data, node_klass)
      return {} unless data.is_a?(Hash)

      data.to_h do |key, value|
        [key, sanitize_tiptap_node_value(value, tiptap_node_attr_config(node_klass, key))]
      end
    end

    def sanitize_tiptap_node_value(value, config)
      case config&.dig(:type)
      when :embed
        Folio::Embed.sanitize_value(value)
      when :url_json
        sanitize_url_json_value(value)
      when :rich_text
        sanitize_rich_text_value(value)
      when :nested_nodes
        sanitize_nested_nodes_value(value, config[:node_class])
      else
        traverse_and_scrub(value)
      end
    end

    def sanitize_nested_nodes_value(value, node_class)
      return traverse_and_scrub(value) unless value.is_a?(Array)

      value.map do |attrs|
        sanitize_tiptap_node_attrs(attrs, expected_class: node_class)
      end
    end

    def sanitize_rich_text_value(value)
      return traverse_and_scrub(value) unless value.is_a?(String)

      parsed = JSON.parse(value) rescue nil
      return traverse_and_scrub(value) unless parsed

      traverse_and_scrub(parsed).to_json
    end

    def sanitize_url_json_value(value)
      from_string = value.is_a?(String)
      parsed = if from_string
        JSON.parse(value) rescue nil
      elsif value.is_a?(Hash)
        value
      end

      return traverse_and_scrub(value) unless parsed.is_a?(Hash)

      sanitized = parsed.slice(*Folio::Tiptap::ALLOWED_URL_JSON_KEYS).transform_values do |url_value|
        traverse_and_scrub(url_value)
      end

      sanitized["href"] = sanitize_href(sanitized["href"]) if sanitized["href"]
      sanitized["record_id"] = Integer(sanitized["record_id"], exception: false) if sanitized.key?("record_id")
      sanitized.compact!

      from_string ? sanitized.to_json : sanitized
    end

    def sanitize_link_hash(data)
      data.to_h do |key, value|
        if key == "attrs"
          [key, sanitize_link_attrs(value)]
        else
          [key, traverse_and_scrub(value)]
        end
      end
    end

    def sanitize_link_attrs(attrs)
      return traverse_and_scrub(attrs) unless attrs.is_a?(Hash)

      attrs.to_h do |key, value|
        if key == "href"
          [key, sanitize_href(value)]
        else
          [key, traverse_and_scrub(value)]
        end
      end
    end

    def traverse_and_scrub(data)
      if data.is_a?(Hash)
        if data["type"] == "folioTiptapNode" && data["attrs"].present? && data["attrs"]["type"].is_a?(String)
          return sanitize_folio_tiptap_node(data)
        end

        if data["type"] == "link" && data["attrs"].is_a?(Hash) && data["attrs"]["href"]
          return sanitize_link_hash(data)
        end

        data.transform_values { |value| traverse_and_scrub(value) }
      elsif data.is_a?(Array)
        data.map { |item| traverse_and_scrub(item) }
      elsif data.is_a?(String)
        scrub(data)
      else
        data
      end
    end

    def scrub(string)
      scrubbed = Loofah.fragment(string).text(encode_special_chars: false)

      if scrubbed != string
        Rails.logger.warn "Scrubbed HTML from tiptap value: #{string} -> #{scrubbed}"
      end

      scrubbed
    end

    def sanitize_href(string)
      Folio::HtmlSanitization::Sanitizer.sanitize_href(string)
    end

    def tiptap_node_attr_config(node_klass, key)
      return unless node_klass && node_klass < Folio::Tiptap::Node

      node_klass.structure[key.to_sym]
    end
end
