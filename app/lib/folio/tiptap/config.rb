# frozen_string_literal: true

module Folio
  module Tiptap
    class Config
      attr_accessor :node_names,
                    :styled_paragraph_variants

      def initialize(node_names: nil,
                     styled_paragraph_variants: nil)
        @node_names = node_names || get_all_tiptap_node_names
        @styled_paragraph_variants = styled_paragraph_variants || default_styled_paragraph_variants
      end

      def to_h
        {
          node_names: @node_names,
          styled_paragraph_variants: @styled_paragraph_variants,
        }
      end

      def to_input_json
        h = to_h.without(:node_names)

        h[:nodes] = tiptap_nodes_hash(@node_names)

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
    end
  end
end
