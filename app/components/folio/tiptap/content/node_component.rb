# frozen_string_literal: true

class Folio::Tiptap::Content::NodeComponent < ApplicationComponent
  NODES = YAML.load_file(File.join(__dir__, "node_component.yml"))["nodes"].freeze

  def initialize(record:, prosemirror_node:)
    @record = record
    @prosemirror_node = prosemirror_node

    @node_definition = NODES[@prosemirror_node["type"]]
  end

  private
    def resolve_tag_name(tag)
      if @node_definition["level_based"] && @prosemirror_node["attrs"] && @prosemirror_node["attrs"]["level"]
        level = @prosemirror_node["attrs"]["level"]
        "h#{level}"
      else
        tag
      end
    end

    def resolve_tag_attributes
      attrs = {}

      # Include static attributes from node definition
      if @node_definition["attrs"]
        @node_definition["attrs"].each do |key, value|
          attrs[key.to_sym] = value
        end
      end

      # Include dynamic attributes from prosemirror node
      if @node_definition["has_attrs"] && @prosemirror_node["attrs"]
        @prosemirror_node["attrs"].each do |key, value|
          next if key == "level" # Skip level for headings as it's used for tag name
          attrs[key.to_sym] = value
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
        content_tag(resolve_tag_name(tags.first)) do
          render_nested_tags(tags[1..-1], top: false, &block)
        end
      end
    end
end
