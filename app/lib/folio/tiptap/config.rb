# frozen_string_literal: true

module Folio
  module Tiptap
    class Config
      attr_accessor :node_names,
                    :styled_paragraph_variants,
                    :styled_wrap_variants,
                    :schema,
                    :pages_component_class_name,
                    :heading_levels,
                    :autosave,
                    :embed_node_class_name,
                    :toolbar_groups

      def initialize(node_names: nil,
                     styled_paragraph_variants: nil,
                     styled_wrap_variants: nil,
                     schema: nil,
                     pages_component_class_name: nil,
                     heading_levels: nil,
                     autosave: true,
                     embed_node_class_name: nil,
                     toolbar_groups: nil)
        @node_names = node_names || get_all_tiptap_node_names
        @styled_paragraph_variants = styled_paragraph_variants || default_styled_paragraph_variants
        @styled_wrap_variants = styled_wrap_variants || default_styled_wrap_variants
        @pages_component_class_name = pages_component_class_name
        @heading_levels = heading_levels || default_heading_levels
        @autosave = autosave
        @embed_node_class_name = embed_node_class_name
        @toolbar_groups = toolbar_groups || []

        @schema = schema || build_default_schema
      end

      def to_h
        {
          node_names: @node_names,
          styled_paragraph_variants: @styled_paragraph_variants,
          styled_wrap_variants: @styled_wrap_variants,
          heading_levels: @heading_levels,
          pages_component_class_name: @pages_component_class_name,
          autosave: @autosave,
          embed_node_class_name: @embed_node_class_name,
          toolbar_groups: @toolbar_groups
        }
      end

      def to_input_json
        h = to_h.without(:node_names, :schema, :pages_component_class_name)

        h[:nodes] = tiptap_nodes_hash(@node_names)
        h[:enable_pages] = @pages_component_class_name.present?
        h[:toolbar_groups] = @toolbar_groups if @toolbar_groups.present?

        h.to_json
      end

      private
        def get_all_tiptap_node_names
          Dir[Rails.root.join("app/models/**/tiptap/node/**/*.rb")].map do |path|
            path.gsub("#{Rails.root}/app/models/", "").delete_suffix(".rb").camelize
          end
        end

        def node_name_in_locale(model_name, locale)
          if I18n.available_locales.include?(locale.to_sym)
            I18n.with_locale(locale) { model_name.human }
          else
            I18n.with_locale(I18n.default_locale) { model_name.human }
          end
        end

        def tiptap_nodes_hash(node_names)
          node_names.map do |node_name|
            node_klass = node_name.constantize
            model_name = node_klass.model_name

            {
              title: {
                cs: node_name_in_locale(model_name, :cs),
                en: node_name_in_locale(model_name, :en),
              },
              type: node_name,
              config: node_klass.tiptap_config,
            }
          end
        end

        def default_styled_paragraph_variants
          [
            {
              variant: "large",
              title: {
                cs: "Velký text",
                en: "Large text",
              },
              icon: "arrow-up",
            },
            {
              variant: "small",
              title: {
                cs: "Malý text",
                en: "Small text",
              },
              icon: "arrow-down",
            },
          ]
        end

        def default_styled_wrap_variants
          []
        end

        def default_heading_levels
          [2, 3, 4]
        end

        def build_default_schema
          {
            nodes: {
              "blockquote": {},
              "bulletList": {},
              "codeBlock": {},
              "doc": {},
              "folioTiptapColumn": {
                "attributes" => {
                  "index" => {
                    "type" => "integer",
                  },
                }
              },
              "folioTiptapColumns": {
                "attributes" => {
                  "count" => {
                    "type" => "integer",
                  },
                }
              },
              "folioTiptapFloat": {
                "attributes" => {
                  "side" => {
                    "in" => %w[left right],
                    "default" => "left",
                  },
                  "size" => {
                    "in" => %w[small medium large],
                    "default" => "medium",
                  }
                },
              },
              "folioTiptapFloatAside": {},
              "folioTiptapFloatMain": {},
              "folioTiptapInvalidNode": {},
              "folioTiptapNode": {
                "attributes" => {
                  "version" => {
                    "type" => "string",
                  },
                  "type" => {
                    "type" => "string",
                    "in" => @node_names,
                  },
                  "data" => {
                    "type" => "hash",
                  }
                }
              },
              "folioTiptapStyledParagraph": {
                "attributes" => {
                  "variant" => {
                    "in" => @styled_paragraph_variants.map { |v| v[:variant] },
                  }
                },
                "disabled" => @styled_paragraph_variants.blank?,
              },
              "folioTiptapStyledWrap": {
                "attributes" => {
                  "variant" => {
                    "in" => @styled_wrap_variants.map { |v| v[:variant] },
                  }
                },
                "disabled" => @styled_wrap_variants.blank?,
              },
              "hardBreak": {},
              "heading": {},
              "horizontalRule": {},
              "listItem": {},
              "orderedList": {},
              "paragraph": {},
              "table": {},
              "tableCell": {},
              "tableHeader": {},
              "tableRow": {},
              "text": {},
            }
          }
        end
    end
  end
end
