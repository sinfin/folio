# frozen_string_literal: true

class Folio::Tiptap::Content::NodeComponent < ApplicationComponent
  NODES = YAML.load_file(File.join(__dir__, "node_component.yml"))["nodes"].freeze

  def initialize(record:, prosemirror_node:)
    @record = record
    @prosemirror_node = prosemirror_node

    @node_definition = NODES[@prosemirror_node["type"]]
  end

  private
    def resolve_tag_name
      tag = @node_definition["tag"]

      if @node_definition["level_based"] && @prosemirror_node["attrs"] && @prosemirror_node["attrs"]["level"]
        level = @prosemirror_node["attrs"]["level"]
        "h#{level}"
      elsif tag.is_a?(Array)
        tag.first
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

    def render_nested_tags(tags)
      tags.reverse.reduce(render_content) do |content, tag|
        content_tag(tag, content)
      end
    end

    def render_content
      return "" unless @prosemirror_node["content"]

      content = ""
      @prosemirror_node["content"].each do |child_node|
        content += render(Folio::Tiptap::Content::NodeComponent.new(record: @record,
                                                                   prosemirror_node: child_node))
      end
      content.html_safe
    end
end
