# frozen_string_literal: true

class Folio::Tiptap::Content::ProseMirrorNodeComponent < ApplicationComponent
  NODES = YAML.load_file(File.join(__dir__, "prose_mirror_node_component.yml"))["nodes"].freeze

  def initialize(record:, prose_mirror_node:)
    @record = record
    @prose_mirror_node = prose_mirror_node

    @node_definition = NODES[@prose_mirror_node["type"]]
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

          if value.present?
            attrs[attr_config["data_attribute"]] = value
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
        content_tag(resolve_tag_name(tags.first)) do
          render_nested_tags(tags[1..-1], top: false, &block)
        end
      end
    end
end
