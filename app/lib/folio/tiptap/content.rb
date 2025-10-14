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

    {
      ok: true,
      value: traverse_and_scrub(hash_value.deep_dup),
    }
  end

  private
    def sanitize_href(string)
      Folio::HtmlSanitization::Sanitizer.sanitize_href(string)
    end

    def sanitize_folio_tiptap_node(data)
      @embed_keys ||= {}

      if @embed_keys[data["attrs"]["type"]].nil?
        node_klass = data["attrs"]["type"].safe_constantize

        if node_klass && node_klass < Folio::Tiptap::Node
          node_klass_embed_keys = node_klass.structure.filter_map do |key, config|
            if config[:type] == :embed
              key.to_s
            end
          end

          @embed_keys[data["attrs"]["type"]] = node_klass_embed_keys.presence
        end

        @embed_keys[data["attrs"]["type"]] ||= false
      end

      if @embed_keys[data["attrs"]["type"]]
        mapped_data = data["attrs"]["data"].map do |key, value|
          if @embed_keys[data["attrs"]["type"]].include?(key)
            [key, Folio::Embed.sanitize_value(value)]
          else
            [key, traverse_and_scrub(value)]
          end
        end

        {
          "type" => data["type"],
          "attrs" => {
            "type" => data["attrs"]["type"],
            "version" => data["version"].is_a?(Integer) ? data["version"] : 1,
            "data" => mapped_data.to_h,
          }
        }
      else
        # regular scrub
        data.transform_values { |v| traverse_and_scrub(v) }
      end
    end

    def sanitize_link_hash(data)
      mapped = data.map do |k, v|
        if k == "attrs"
          mapped_link = v.map do |link_key, link_value|
            if link_key == "href"
              [link_key, sanitize_href(link_value)]
            else
              [link_key, traverse_and_scrub(link_value)]
            end
          end

          [k, mapped_link.to_h]
        else
          [k, traverse_and_scrub(v)]
        end
      end

      mapped.to_h
    end

    def traverse_and_scrub(data)
      if data.is_a?(Hash)
        if data["type"] == "folioTiptapNode" && data["attrs"].present? && data["attrs"]["type"].is_a?(String)
          return sanitize_folio_tiptap_node(data)
        end

        # Handle link marks with href sanitization
        if data["type"] == "link" && data["attrs"].is_a?(Hash) && data["attrs"]["href"]
          return sanitize_link_hash(data)
        end

        data.transform_values { |v| traverse_and_scrub(v) }
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
end
