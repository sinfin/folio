# frozen_string_literal: true

class Folio::Tiptap::Content::FolioTiptapNodeComponent < ApplicationComponent
  def initialize(record:, prose_mirror_node:, tiptap_content_information:)
    @record = record
    @prose_mirror_node = prose_mirror_node
    @tiptap_content_information = tiptap_content_information

    @node = Folio::Tiptap::Node.new_from_params(ActionController::Parameters.new(@prose_mirror_node["attrs"]))
    validate_node_type!
  end

  def render?
    inner_content.present?
  end

  private
    def inner_content
      return @inner_content if defined?(@inner_content)

      @inner_content = render(node_component)
    end

    def node_component
      @node_component ||= @node.class.view_component_class.new(
        node: @node,
        tiptap_content_information: @tiptap_content_information
      )
    end

    def validate_node_type!
      node_type = @prose_mirror_node.dig("attrs", "type")

      if node_type.blank?
        raise ArgumentError, "Node type is required but was not provided"
      end

      attribute = @tiptap_content_information[:attribute]
      allowed_node_names = @record.tiptap_config(attribute_name: attribute).node_names
      return if allowed_node_names.include?(node_type)

      raise ArgumentError, "Node type '#{node_type}' is not supported. Allowed types: #{allowed_node_names.join(', ')}"
    end
end
