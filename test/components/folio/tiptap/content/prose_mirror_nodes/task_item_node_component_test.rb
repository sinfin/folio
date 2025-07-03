# frozen_string_literal: true

require "test_helper"

class Folio::Tiptap::Content::ProseMirrorNodes::TaskItemNodeComponentTest < Folio::ComponentTest
  def test_render_checked_task_item
    prose_mirror_node = {
      "type" => "taskItem",
      "attrs" => {
        "checked" => true
      },
      "content" => [
        {
          "type" => "paragraph",
          "attrs" => {
            "textAlign" => nil,
          },
          "content" => [
            {
              "text" => "Lorem ipsum dolor sit amet",
              "type" => "text"
            }
          ]
        }
      ]
    }

    render_inline(Folio::Tiptap::Content::ProseMirrorNodes::TaskItemNodeComponent.new(
      record: build_mock_record,
      prose_mirror_node:
    ))

    assert_selector('li[data-checked="true"]', text: "Lorem ipsum dolor sit amet")
  end

  def test_render_unchecked_task_item
    prose_mirror_node = {
      "type" => "taskItem",
      "attrs" => {
        "checked" => false
      },
      "content" => [
        {
          "type" => "paragraph",
          "attrs" => {
            "textAlign" => nil,
          },
          "content" => [
            {
              "text" => "Consectetur adipisicing elit",
              "type" => "text"
            }
          ]
        }
      ]
    }

    render_inline(Folio::Tiptap::Content::ProseMirrorNodes::TaskItemNodeComponent.new(
      record: build_mock_record,
      prose_mirror_node:
    ))

    assert_selector('li[data-checked="false"]', text: "Consectetur adipisicing elit")
  end

  private
    def build_mock_record
      Object.new
    end
end
