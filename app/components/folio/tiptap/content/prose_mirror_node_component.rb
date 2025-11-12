# frozen_string_literal: true

class Folio::Tiptap::Content::ProseMirrorNodeComponent < ApplicationComponent
  NODES = YAML.load_file(File.join(__dir__, "prose_mirror_node_component.yml"))["nodes"].freeze

  def initialize(record:,
                 prose_mirror_node:,
                 tiptap_content_information:,
                 lambda_before_node: nil,
                 lambda_after_node: nil,
                 node_type_blacklist: nil,
                 lambda_for_blacklisted: nil)
    @record = record
    @prose_mirror_node = prose_mirror_node
    @lambda_before_node = lambda_before_node
    @lambda_after_node = lambda_after_node
    @node_type_blacklist = node_type_blacklist
    @lambda_for_blacklisted = lambda_for_blacklisted
    @tiptap_content_information = tiptap_content_information

    if @prose_mirror_node["type"] == "folioTiptapPages"
      if record.tiptap_config.pages_component_class_name
        @node_definition = { "component_name" => record.tiptap_config.pages_component_class_name }
      end
    elsif @prose_mirror_node["type"] == "folioTiptapStyledParagraph"
      @node_definition = build_styled_paragraph_definition
    else
      @node_definition = NODES[@prose_mirror_node["type"]]
    end
  end

  def before_render
    return if @node_definition.present?
    raise ArgumentError, "Unknown ProseMirror node type: #{@prose_mirror_node['type']}"
  rescue ArgumentError => e
    rescue_component_error(e)
  end

  def render?
    @node_definition
  end

  private
    def resolve_tag_name(tag)
      if @node_definition["level_based_tag"] && @prose_mirror_node["attrs"] && @prose_mirror_node["attrs"]["level"]
        level = @prose_mirror_node["attrs"]["level"]
        "h#{level}"
      else
        tag
      end
    end

    def resolve_tag_attributes
      attrs = {}

      if @node_definition["static_attrs"]
        @node_definition["static_attrs"].each do |key, value|
          attrs[key] = value
        end
      end

      if @node_definition["attrs"].present?
        @node_definition["attrs"].each do |attr_name, attr_config|
          value = (@prose_mirror_node["attrs"].present? ? @prose_mirror_node["attrs"][attr_name] : nil) || attr_config["default_value"]

          if attr_config["available_values"].present?
            next unless attr_config["available_values"].include?(value)
          end

          if value.present?
            if attr_config["data_attribute"]
              attrs[attr_config["data_attribute"]] = value
            elsif attr_config["style_property"]
              attrs["style"] ||= ""
              spacer = attrs["style"].empty? ? "" : " "
              attrs["style"] += "#{spacer}#{attr_config['style_property']}: #{value};"
            end
          end
        end
      end

      attrs
    end

    def render_nested_tags(tags, top: true, &block)
      if tags.is_a?(String)
        tags = [tags]
      end

      if tags.length == 1
        if top
          content_tag(resolve_tag_name(tags.first), resolve_tag_attributes, &block)
        else
          content_tag(resolve_tag_name(tags.first), &block)
        end
      else
        if top
          content_tag(resolve_tag_name(tags.first), resolve_tag_attributes) do
            render_nested_tags(tags[1..-1], top: false, &block)
          end
        else
          content_tag(resolve_tag_name(tags.first)) do
            render_nested_tags(tags[1..-1], top: false, &block)
          end
        end
      end
    end

    def custom_component_render
      component_klass = @node_definition["component_name"].constantize

      component = component_klass.new(record: @record,
                                      prose_mirror_node: @prose_mirror_node,
                                      tiptap_content_information: @tiptap_content_information)

      render(component)
    end

    def rescue_component_error(e)
      Rails.logger.error("Error rendering ProseMirror node component: #{@prose_mirror_node['type']}")

      if controller_instance = try(:controller)
        variable_name = Folio::Tiptap::ContentComponent::CONTROLLER_VARIABLE_NAME
        data = controller_instance.instance_variable_get(variable_name)

        data ||= {}
        data[:broken_nodes] ||= []
        data[:broken_nodes] << { prose_mirror_node: @prose_mirror_node, error: e }

        controller_instance.instance_variable_set(variable_name, data)
      end

      if Rails.env.development? && ENV["FOLIO_DEBUG_TIPTAP_NODES"]
        raise e
      end
    end

    def call_lambda_if_present(tiptap_content_information:, after: false)
      lambda_to_be_called = after ? @lambda_after_node : @lambda_before_node

      if lambda_to_be_called
        begin
          lambda_to_be_called.call(component: self, tiptap_content_information:)
        rescue StandardError => e
          rescue_lambda_error(e, after:)
        end
      end
    end

    def rescue_lambda_error(e, after: false)
      Rails.logger.error("Error calling Folio::Tiptap::Content::ProseMirrorNodeComponent #{after ? "after" : "before"} lambda")

      if controller_instance = try(:controller)
        variable_name = Folio::Tiptap::ContentComponent::CONTROLLER_VARIABLE_NAME
        data = controller_instance.instance_variable_get(variable_name)

        data ||= {}
        data[:broken_lambdas] ||= {}
        data[:broken_lambdas][after ? :after : :before] ||= { error: e }

        controller_instance.instance_variable_set(variable_name, data)
      end

      if Rails.env.development? && ENV["FOLIO_DEBUG_TIPTAP_NODES"]
        raise e
      end
    end

    def build_styled_paragraph_definition
      variant = @prose_mirror_node.dig("attrs", "variant")
      variant_config = find_variant_config(variant)

      tag = variant_config&.dig(:tag) || variant_config&.dig("tag") || "p"
      css_class = build_styled_paragraph_classes(variant_config)

      definition = {
        "tag" => tag,
        "static_attrs" => {
          "class" => css_class
        }
      }

      if variant.present?
        definition["static_attrs"]["data-f-tiptap-styled-paragraph-variant"] = variant
      end

      definition
    end

    def find_variant_config(variant)
      return nil unless variant.present?
      return nil unless @record.respond_to?(:tiptap_config)
      return nil unless @record.tiptap_config.respond_to?(:styled_paragraph_variants)

      variants = @record.tiptap_config.styled_paragraph_variants
      return nil unless variants.is_a?(Array)

      variants.find { |v| v[:variant] == variant || v["variant"] == variant }
    end

    def build_styled_paragraph_classes(variant_config)
      base_class = "f-tiptap-styled-paragraph"
      custom_class = variant_config&.dig(:class_name) || variant_config&.dig("class_name")

      if custom_class.present?
        "#{base_class} #{custom_class}"
      else
        base_class
      end
    end

    def tiptap_content_information_for_child(child_node:, index:)
      current_depth = @tiptap_content_information[:depth]
      child_depth = current_depth + 1
      case current_depth
      when 0
        # doc node
        @tiptap_content_information.merge(depth: child_depth,
                                          node: child_node,
                                          root_node: child_node,
                                          root_index: index)
      when 1
        # root node - right under doc
        @tiptap_content_information.merge(depth: child_depth,
                                          node: child_node,
                                          root_index: index)
      else
        @tiptap_content_information.merge(depth: child_depth,
                                          node: child_node)
      end
    end
end
