# frozen_string_literal: true

class Folio::Tiptap::Content::TextComponent < ApplicationComponent
  MARKS = YAML.load_file(File.join(__dir__, "text_component.yml"))["marks"].freeze

  def initialize(record:, prose_mirror_node:)
    @record = record
    @prose_mirror_node = prose_mirror_node
  end

  def text
    @text ||= @prose_mirror_node["text"] || ""
  end

  def marks
    @marks ||= @prose_mirror_node["marks"] || []
  end

  def has_marks?
    marks.any?
  end

  def render_text_with_marks
    if marks.empty?
      text
    else
      apply_marks_with_content_tag(text, marks)
    end
  end

  private
    def apply_marks_with_content_tag(content, marks_to_apply)
      marks_to_apply.reduce(content) do |current_content, mark|
        mark_config = MARKS[mark["type"]]
        next current_content unless mark_config&.dig("tag")

        tag_name = mark_config["tag"]
        attrs = mark_attributes(mark)

        content_tag(tag_name, current_content, attrs)
      end
    end

    def mark_attributes(mark)
      mark_config = MARKS[mark["type"]]
      return {} unless mark_config&.dig("has_attrs") && mark["attrs"]

      if mark_config["attrs"]
        # Use specific allowed attributes
        attrs = {}
        mark_config["attrs"].each do |attr_name|
          if mark["attrs"][attr_name]
            attrs[attr_name] = mark["attrs"][attr_name]
          end
        end
        attrs
      else
        # Use all attributes from the mark
        mark["attrs"]
      end
    end
end
