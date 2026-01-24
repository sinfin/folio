# frozen_string_literal: true

module Folio
  module Mcp
    class TiptapSchemaGenerator
      def generate
        nodes = {}

        tiptap_node_classes.each do |klass|
          next unless klass.respond_to?(:structure)

          node_name = extract_node_name(klass)
          next if node_name.blank?

          nodes[node_name] = {
            ruby_class: klass.name,
            group: extract_group(klass),
            icon: extract_icon(klass),
            description: generate_description(klass),
            attributes: generate_attributes(klass),
            example: generate_example(klass, node_name)
          }
        end

        {
          nodes: nodes,
          groups: generate_groups,
          field_types: field_type_docs
        }
      end

      private
        def tiptap_node_classes
          if defined?(Folio::Tiptap::Node)
            Folio::Tiptap::Node.descendants.reject { |k| k.name&.include?("Test") }
          else
            []
          end
        end

        def extract_node_name(klass)
          if klass.respond_to?(:tiptap_node_name)
            klass.tiptap_node_name
          else
            klass.name.demodulize.camelize(:lower)
          end
        end

        def extract_group(klass)
          return klass.tiptap_config[:group] if klass.respond_to?(:tiptap_config)

          # Infer from namespace
          parts = klass.name.split("::")
          if parts.include?("Cards")
            "cards"
          elsif parts.include?("Contents")
            "content"
          elsif parts.include?("Images")
            "images"
          elsif parts.include?("Listings")
            "listings"
          else
            "other"
          end
        end

        def extract_icon(klass)
          klass.try(:tiptap_config)&.dig(:icon) || "block"
        end

        def generate_description(klass)
          if klass.respond_to?(:description)
            klass.description
          else
            "#{klass.name.demodulize.titleize} node"
          end
        end

        def generate_attributes(klass)
          return {} unless klass.respond_to?(:structure)

          klass.structure.transform_values do |type_def|
            type, options = parse_type(type_def)
            {
              type: type,
              translatable: Folio::Mcp::TRANSLATABLE_FIELD_TYPES.include?(type),
              **options
            }.compact
          end
        end

        def parse_type(type_def)
          case type_def
          when Symbol
            [type_def, {}]
          when Array
            [:enum, { values: type_def }]
          when Hash
            if type_def[:type]
              [type_def[:type], type_def.except(:type)]
            else
              [:object, type_def]
            end
          else
            [:unknown, {}]
          end
        end

        def generate_example(klass, node_name)
          {
            type: node_name,
            attrs: {}
          }
        end

        def generate_groups
          {
            cards: { label: "Cards", description: "Card components for highlighting content" },
            content: { label: "Content", description: "Basic content blocks" },
            images: { label: "Images", description: "Image galleries and displays" },
            listings: { label: "Listings", description: "Dynamic content listings" },
            other: { label: "Other", description: "Other content types" }
          }
        end

        def field_type_docs
          {
            string: { translatable: true, description: "Plain text string" },
            text: { translatable: true, description: "Longer plain text" },
            rich_text: { translatable: true, description: "Formatted text with Tiptap structure" },
            url: { translatable: false, description: "URL/link" },
            integer: { translatable: false, description: "Number" },
            image: { translatable: false, description: "Single image reference (use file ID)" },
            images: { translatable: false, description: "Multiple image references" },
            documents: { translatable: false, description: "Document file references" },
            enum: { translatable: false, description: "Fixed set of allowed values" }
          }
        end
    end
  end
end
