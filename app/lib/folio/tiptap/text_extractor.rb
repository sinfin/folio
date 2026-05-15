# frozen_string_literal: true

class Folio::Tiptap::TextExtractor
  DEFAULT_IGNORED_NODE_TYPES = %w[hardBreak horizontalRule].freeze

  TEXTUAL_NODE_ATTR_TYPES = %i[string text rich_text].freeze

  def self.extract(value, additional_ignored_node_types: [])
    new(additional_ignored_node_types:).extract(value)
  end

  def initialize(additional_ignored_node_types: [])
    @ignored_node_types = (DEFAULT_IGNORED_NODE_TYPES + Array(additional_ignored_node_types)).to_set
    @parts = []
  end

  def extract(value)
    @parts.clear
    walk(unwrap(value))
    @parts.join(" ").gsub(/\s+/, " ").strip
  end

  private
    def unwrap(value)
      return nil if value.blank?

      if value.is_a?(Hash)
        content_key = Folio::Tiptap::TIPTAP_CONTENT_JSON_STRUCTURE[:content]
        value.key?(content_key) ? value[content_key] : value
      else
        value
      end
    end

    def walk(node)
      case node
      when Array
        node.each { |child| walk(child) }
      when Hash
        type = node["type"]
        return if type && @ignored_node_types.include?(type)

        if type == "text"
          text = node["text"]
          @parts << text if text.is_a?(String) && text.present?
        elsif type == "folioTiptapNode"
          walk_folio_tiptap_node(node)
        else
          walk(node["content"])
        end
      end
    end

    def walk_folio_tiptap_node(node)
      attrs = node["attrs"]
      return unless attrs.is_a?(Hash)

      class_name = attrs["type"]
      return if class_name.blank?
      return if @ignored_node_types.include?(class_name)

      instance = begin
        Folio::Tiptap::Node.new_from_attributes(attrs)
      rescue ArgumentError => e
        Rails.logger.error("Folio::Tiptap::TextExtractor: #{e.message}")
        return
      end

      instance.class.structure.each do |key, config|
        next unless TEXTUAL_NODE_ATTR_TYPES.include?(config[:type])

        value = instance.public_send(key)
        next if value.blank?

        case config[:type]
        when :string, :text
          @parts << value.to_s if value.is_a?(String)
        when :rich_text
          walk(unwrap(value)) if value.is_a?(Hash)
        end
      end
    end
end
