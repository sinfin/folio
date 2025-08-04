# frozen_string_literal: true

module Folio::Tiptap
  class Config
    attr_accessor :node_names,
                  :single_image_node_name

    def initialize(node_names: nil,
                   single_image_node: nil)
      @node_names = node_names || get_all_tiptap_node_names
      @single_image_node_name = single_image_node
    end

    def to_h
      {
        node_names: @node_names,
        single_image_node_name: @single_image_node_name,
      }
    end

    def to_input_json
      h = to_h.without(:node_names)

      h[:nodes] = tiptap_nodes_hash(@node_names)

      h.to_json
    end

    private
      def get_all_tiptap_node_names
        Folio::Tiptap::Node.recursive_subclasses(include_self: false).map(&:name).without("Folio::Tiptap::Node")
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
          }
        end
      end
  end

  def self.config
    @config ||= Folio::Tiptap::Config.new
  end

  def self.configure
    yield(config)
  end
end
