# frozen_string_literal: true

class Folio::Tiptap::PlainText
  BLOCK_TYPES = %w[
    blockquote
    bulletList
    codeBlock
    heading
    listItem
    orderedList
    paragraph
  ].freeze

  class << self
    def from_value(value)
      new(value).to_s
    end
  end

  def initialize(value)
    @value = value
  end

  def to_s
    return "" if parsed_value.blank?
    return stored_text if stored_text.present?

    normalize_text(extract_text(content_node))
  end

  private
    attr_reader :value

    def parsed_value
      @parsed_value ||= parse_value
    end

    def parse_value
      case value
      when Hash
        value
      when String
        JSON.parse(value)
      else
        {}
      end
    rescue JSON::ParserError
      {}
    end

    def stored_text
      parsed_value[text_key].to_s
    end

    def content_node
      parsed_value[content_key] || parsed_value
    end

    def extract_text(node)
      case node
      when Array
        node.map { |child| extract_text(child) }.join
      when Hash
        extract_hash_text(node)
      else
        ""
      end
    end

    def extract_hash_text(node)
      case node["type"]
      when "text"
        node["text"].to_s
      when "hardBreak"
        "\n"
      else
        text = extract_text(node["content"])
        BLOCK_TYPES.include?(node["type"]) ? "#{text}\n" : text
      end
    end

    def normalize_text(text)
      text.to_s.gsub(/[ \t]+\n/, "\n")
              .gsub(/\n{3,}/, "\n\n")
              .strip
    end

    def content_key
      Folio::Tiptap::TIPTAP_CONTENT_JSON_STRUCTURE[:content]
    end

    def text_key
      Folio::Tiptap::TIPTAP_CONTENT_JSON_STRUCTURE[:text]
    end
end
