# frozen_string_literal: true

require "test_helper"

class Folio::Tiptap::Content::NodeComponentTest < Folio::ComponentTest
  def test_render_simple_text_node
    prosemirror_node = {
      "type" => "text",
      "text" => "Hello world"
    }

    model = build_mock_record
    render_inline(Folio::Tiptap::Content::NodeComponent.new(record: model, prosemirror_node: prosemirror_node))

    # Text nodes render the TextComponent directly, which just outputs text
    assert_text("Hello world")
  end

  def test_render_paragraph_node
    prosemirror_node = {
      "type" => "paragraph",
      "content" => [
        {
          "type" => "text",
          "text" => "This is a paragraph"
        }
      ]
    }

    model = build_mock_record
    render_inline(Folio::Tiptap::Content::NodeComponent.new(record: model, prosemirror_node: prosemirror_node))

    assert_selector("p")
    assert_text("This is a paragraph")
  end

  def test_render_heading_node_level_1
    prosemirror_node = {
      "type" => "heading",
      "attrs" => { "level" => 1 },
      "content" => [
        {
          "type" => "text",
          "text" => "Main Heading"
        }
      ]
    }

    model = build_mock_record
    render_inline(Folio::Tiptap::Content::NodeComponent.new(record: model, prosemirror_node: prosemirror_node))

    # Now that we have dynamic heading levels
    assert_selector("h1", text: "Main Heading")
  end

  def test_render_heading_node_with_different_level
    prosemirror_node = {
      "type" => "heading",
      "attrs" => { "level" => 3 },
      "content" => [
        {
          "type" => "text",
          "text" => "Sub Heading"
        }
      ]
    }

    model = build_mock_record
    render_inline(Folio::Tiptap::Content::NodeComponent.new(record: model, prosemirror_node: prosemirror_node))

    # Now that we have dynamic heading levels
    assert_selector("h3", text: "Sub Heading")
  end

  def test_render_blockquote_node
    prosemirror_node = {
      "type" => "blockquote",
      "content" => [
        {
          "type" => "paragraph",
          "content" => [
            {
              "type" => "text",
              "text" => "This is a quoted text"
            }
          ]
        }
      ]
    }

    model = build_mock_record
    render_inline(Folio::Tiptap::Content::NodeComponent.new(record: model, prosemirror_node: prosemirror_node))

    assert_selector("blockquote")
    assert_text("This is a quoted text")
  end

  def test_render_bullet_list_node
    prosemirror_node = {
      "type" => "bullet_list",
      "content" => [
        {
          "type" => "list_item",
          "content" => [
            {
              "type" => "paragraph",
              "content" => [
                {
                  "type" => "text",
                  "text" => "First item"
                }
              ]
            }
          ]
        },
        {
          "type" => "list_item",
          "content" => [
            {
              "type" => "paragraph",
              "content" => [
                {
                  "type" => "text",
                  "text" => "Second item"
                }
              ]
            }
          ]
        }
      ]
    }

    model = build_mock_record
    render_inline(Folio::Tiptap::Content::NodeComponent.new(record: model, prosemirror_node: prosemirror_node))

    assert_selector("ul")
    assert_selector("li", count: 2)
    assert_text("First item")
    assert_text("Second item")
  end

  def test_render_ordered_list_node
    prosemirror_node = {
      "type" => "ordered_list",
      "attrs" => { "start" => 1 },
      "content" => [
        {
          "type" => "list_item",
          "content" => [
            {
              "type" => "paragraph",
              "content" => [
                {
                  "type" => "text",
                  "text" => "Step one"
                }
              ]
            }
          ]
        }
      ]
    }

    model = build_mock_record
    render_inline(Folio::Tiptap::Content::NodeComponent.new(record: model, prosemirror_node: prosemirror_node))

    assert_selector("ol")
    assert_selector("li")
    assert_text("Step one")
  end

  def test_render_doc_node_with_class
    prosemirror_node = {
      "type" => "doc",
      "content" => [
        {
          "type" => "paragraph",
          "content" => [
            {
              "type" => "text",
              "text" => "Document content"
            }
          ]
        }
      ]
    }

    model = build_mock_record
    render_inline(Folio::Tiptap::Content::NodeComponent.new(record: model, prosemirror_node: prosemirror_node))

    assert_selector("div.f-tiptap-content__root")
    assert_text("Document content")
  end

  def test_render_folio_tiptap_node
    prosemirror_node = {
      "type" => "folioTiptapNode",
      "attrs" => {
        "type" => "Dummy::Tiptap::Node::Card",
        "data" => { "title" => "Test Card", "content" => "Custom content" }
      }
    }

    model = build_mock_record
    render_inline(Folio::Tiptap::Content::NodeComponent.new(record: model, prosemirror_node: prosemirror_node))

    # Should render the FolioTiptapNodeComponent with the card
    assert_selector(".d-tiptap-node-card")
    assert_text("Test Card")
  end

  def test_render_nested_structure
    prosemirror_node = {
      "type" => "bullet_list",
      "content" => [
        {
          "type" => "list_item",
          "content" => [
            {
              "type" => "paragraph",
              "content" => [
                {
                  "type" => "text",
                  "text" => "Item with formatted text"
                }
              ]
            }
          ]
        }
      ]
    }

    model = build_mock_record
    render_inline(Folio::Tiptap::Content::NodeComponent.new(record: model, prosemirror_node: prosemirror_node))

    assert_selector("ul")
    assert_selector("li p")
    assert_text("Item with formatted text")
  end

  def test_render_unsupported_node_type
    prosemirror_node = {
      "type" => "unsupported_node",
      "content" => [
        {
          "type" => "text",
          "text" => "This should show error"
        }
      ]
    }

    model = build_mock_record
    render_inline(Folio::Tiptap::Content::NodeComponent.new(record: model, prosemirror_node: prosemirror_node))

    assert_selector(".f-tiptap-content-node--error")
    assert_text("TODO missing node_definition")
  end



  def test_render_list_item_node
    prosemirror_node = {
      "type" => "list_item",
      "content" => [
        {
          "type" => "paragraph",
          "content" => [
            {
              "type" => "text",
              "text" => "List item content"
            }
          ]
        }
      ]
    }

    model = build_mock_record
    render_inline(Folio::Tiptap::Content::NodeComponent.new(record: model, prosemirror_node: prosemirror_node))

    assert_selector("li")
    assert_text("List item content")
  end

  def test_render_empty_content_array
    prosemirror_node = {
      "type" => "paragraph",
      "content" => []
    }

    model = build_mock_record
    render_inline(Folio::Tiptap::Content::NodeComponent.new(record: model, prosemirror_node: prosemirror_node))

    assert_selector("p")
    # Should render empty paragraph
  end



  def test_render_multiple_text_nodes_in_paragraph
    prosemirror_node = {
      "type" => "paragraph",
      "content" => [
        {
          "type" => "text",
          "text" => "First part "
        },
        {
          "type" => "text",
          "text" => "second part"
        }
      ]
    }

    model = build_mock_record
    render_inline(Folio::Tiptap::Content::NodeComponent.new(record: model, prosemirror_node: prosemirror_node))

    assert_selector("p")
    assert_text("First part second part")
  end

  def test_render_complex_structure_with_multiple_levels
    prosemirror_node = {
      "type" => "blockquote",
      "content" => [
        {
          "type" => "paragraph",
          "content" => [
            {
              "type" => "text",
              "text" => "Quoted paragraph with "
            },
            {
              "type" => "text",
              "text" => "multiple text nodes"
            }
          ]
        }
      ]
    }

    model = build_mock_record
    render_inline(Folio::Tiptap::Content::NodeComponent.new(record: model, prosemirror_node: prosemirror_node))

    assert_selector("blockquote")
    assert_selector("blockquote p")
    assert_text("Quoted paragraph with multiple text nodes")
  end

  def test_component_initialization_with_all_parameters
    prosemirror_node = {
      "type" => "paragraph",
      "content" => [
        {
          "type" => "text",
          "text" => "Test initialization"
        }
      ]
    }

    model = build_mock_record
    component = Folio::Tiptap::Content::NodeComponent.new(
      record: model,
      prosemirror_node: prosemirror_node
    )

    # Component should initialize without errors
    render_inline(component)
    assert_selector("p", text: "Test initialization")
  end

  private
    def build_mock_record
      Object.new
    end
end
