# frozen_string_literal: true

module Folio
  module Mcp
    class TiptapTextExtractor
      TRANSLATABLE_ATTRS = %w[title subtitle content name job label text description perex].freeze
      SKIP_ATTRS = %w[url href id cover images documents file_id video_id audio_id].freeze

      def initialize(tiptap_json)
        @tiptap = tiptap_json.is_a?(String) ? JSON.parse(tiptap_json) : tiptap_json
        # Handle wrapped structure {"tiptap_content": {...}}
        @tiptap = @tiptap["tiptap_content"] if @tiptap.is_a?(Hash) && @tiptap["tiptap_content"]
        @texts = []
      end

      def extract
        traverse(@tiptap, [])
        @texts
      end

      private
        def traverse(node, path)
          return unless node.is_a?(Hash)

          # Extract from attrs
          if node["attrs"]
            node["attrs"].each do |key, value|
              next if SKIP_ATTRS.include?(key)
              next if value.nil? || value == ""

              if translatable_value?(key, value)
                if value.is_a?(Hash) && value["type"] == "doc"
                  # Rich text content - extract nested texts
                  extract_rich_text(value, path + ["attrs", key])
                elsif value.is_a?(String)
                  @texts << {
                    path: (path + ["attrs", key]).join("."),
                    value: value,
                    node_type: node["type"],
                    field: key,
                    context: "#{node['type']} #{key}"
                  }
                end
              end
            end
          end

          # Extract from text nodes
          if node["type"] == "text" && node["text"].present?
            @texts << {
              path: (path + ["text"]).join("."),
              value: node["text"],
              node_type: "text",
              field: "text",
              context: "Text content"
            }
          end

          # Recurse into content array
          if node["content"].is_a?(Array)
            node["content"].each_with_index do |child, i|
              traverse(child, path + ["content", i.to_s])
            end
          end
        end

        def extract_rich_text(doc, base_path)
          return unless doc.is_a?(Hash) && doc["content"].is_a?(Array)

          doc["content"].each_with_index do |node, i|
            traverse(node, base_path + ["content", i.to_s])
          end
        end

        def translatable_value?(key, value)
          return false if value.nil?
          return true if TRANSLATABLE_ATTRS.include?(key)
          return true if value.is_a?(String) && key !~ /(_id|_url|_path|_type|_class)$/

          false
        end
    end
  end
end
