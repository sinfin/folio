# frozen_string_literal: true

require "test_helper"

class Folio::Tiptap::Content::ProseMirrorNodeComponentTest < Folio::ComponentTest
  def test_render_simple_text_node
    prose_mirror_node = {
      "type" => "text",
      "text" => "Hello world"
    }

    render_inline(Folio::Tiptap::Content::ProseMirrorNodeComponent.new(record: build_mock_record, prose_mirror_node:))

    # Text nodes render the TextComponent directly, which just outputs text
    assert_text("Hello world")
  end

  def test_render_paragraph_node
    prose_mirror_node = {
      "type" => "paragraph",
      "content" => [
        {
          "type" => "text",
          "text" => "This is a paragraph"
        }
      ]
    }

    render_inline(Folio::Tiptap::Content::ProseMirrorNodeComponent.new(record: build_mock_record, prose_mirror_node:))

    assert_selector("p")
    assert_text("This is a paragraph")
  end

  def test_render_heading_node_level_1
    prose_mirror_node = {
      "type" => "heading",
      "attrs" => { "level" => 1 },
      "content" => [
        {
          "type" => "text",
          "text" => "Main Heading"
        }
      ]
    }

    render_inline(Folio::Tiptap::Content::ProseMirrorNodeComponent.new(record: build_mock_record, prose_mirror_node:))

    # Now that we have dynamic heading levels
    assert_selector("h1", text: "Main Heading")
  end

  def test_render_heading_node_with_different_level
    prose_mirror_node = {
      "type" => "heading",
      "attrs" => { "level" => 3 },
      "content" => [
        {
          "type" => "text",
          "text" => "Sub Heading"
        }
      ]
    }

    render_inline(Folio::Tiptap::Content::ProseMirrorNodeComponent.new(record: build_mock_record, prose_mirror_node:))

    # Now that we have dynamic heading levels
    assert_selector("h3", text: "Sub Heading")
  end

  def test_render_blockquote_node
    prose_mirror_node = {
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

    render_inline(Folio::Tiptap::Content::ProseMirrorNodeComponent.new(record: build_mock_record, prose_mirror_node:))

    assert_selector("blockquote")
    assert_text("This is a quoted text")
  end

  def test_render_bulletList_node
    prose_mirror_node = {
      "type" => "bulletList",
      "content" => [
        {
          "type" => "listItem",
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
          "type" => "listItem",
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

    render_inline(Folio::Tiptap::Content::ProseMirrorNodeComponent.new(record: build_mock_record, prose_mirror_node:))

    assert_selector("ul")
    assert_selector("li", count: 2)
    assert_text("First item")
    assert_text("Second item")
  end

  def test_render_orderedList_node
    prose_mirror_node = {
      "type" => "orderedList",
      "attrs" => { "start" => 1 },
      "content" => [
        {
          "type" => "listItem",
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

    render_inline(Folio::Tiptap::Content::ProseMirrorNodeComponent.new(record: build_mock_record, prose_mirror_node:))

    assert_selector("ol")
    assert_selector("li")
    assert_text("Step one")
  end

  def test_render_doc_node_with_class
    prose_mirror_node = {
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

    render_inline(Folio::Tiptap::Content::ProseMirrorNodeComponent.new(record: build_mock_record, prose_mirror_node:))

    assert_selector("div.f-tiptap-content__root")
    assert_text("Document content")
  end

  def test_render_folio_tiptap_node
    prose_mirror_node = {
      "type" => "folioTiptapNode",
      "attrs" => {
        "type" => "Dummy::Tiptap::Node::Card",
        "data" => { "title" => "Test Card", "content" => "Custom content" }
      }
    }

    render_inline(Folio::Tiptap::Content::ProseMirrorNodeComponent.new(record: build_mock_record, prose_mirror_node:))

    # Should render the FolioTiptapNodeComponent with the card
    assert_selector(".d-tiptap-node-card")
    assert_text("Test Card")
  end

  def test_render_nested_structure
    prose_mirror_node = {
      "type" => "bulletList",
      "content" => [
        {
          "type" => "listItem",
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

    render_inline(Folio::Tiptap::Content::ProseMirrorNodeComponent.new(record: build_mock_record, prose_mirror_node:))

    assert_selector("ul")
    assert_selector("li p")
    assert_text("Item with formatted text")
  end

  def test_render_unsupported_node_type
    prose_mirror_node = {
      "type" => "unsupported_node",
      "content" => [
        {
          "type" => "text",
          "text" => "This should be hidden, as it causes an error"
        }
      ]
    }

    render_inline(Folio::Tiptap::Content::ProseMirrorNodeComponent.new(record: build_mock_record, prose_mirror_node:))

    assert_text("")
  end

  def test_render_listItem_node
    prose_mirror_node = {
      "type" => "listItem",
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

    render_inline(Folio::Tiptap::Content::ProseMirrorNodeComponent.new(record: build_mock_record, prose_mirror_node:))

    assert_selector("li")
    assert_text("List item content")
  end

  def test_render_empty_content_array
    prose_mirror_node = {
      "type" => "paragraph",
      "content" => []
    }

    render_inline(Folio::Tiptap::Content::ProseMirrorNodeComponent.new(record: build_mock_record, prose_mirror_node:))

    assert_selector("p")
    assert_selector("p br")
    # Should render empty paragraph with trailing break
  end

  def test_render_paragraph_trailing_break_when_empty
    prose_mirror_node = {
      "type" => "paragraph"
    }

    render_inline(Folio::Tiptap::Content::ProseMirrorNodeComponent.new(record: build_mock_record, prose_mirror_node:))

    assert_selector("p")
    assert_selector("p br")
  end



  def test_render_multiple_text_nodes_in_paragraph
    prose_mirror_node = {
      "type" => "paragraph",
      "content" => [
        {
          "type" => "text",
          "text" => "First part"
        },
        {
          "type" => "text",
          "text" => "second part"
        }
      ]
    }

    render_inline(Folio::Tiptap::Content::ProseMirrorNodeComponent.new(record: build_mock_record, prose_mirror_node:))

    assert_selector("p")
    assert_text("First partsecond part")
  end

  def test_render_complex_structure_with_multiple_levels
    prose_mirror_node = {
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

    render_inline(Folio::Tiptap::Content::ProseMirrorNodeComponent.new(record: build_mock_record, prose_mirror_node:))

    assert_selector("blockquote")
    assert_selector("blockquote p")
    assert_text("Quoted paragraph with multiple text nodes")
  end

  def test_component_initialization_with_all_parameters
    prose_mirror_node = {
      "type" => "paragraph",
      "content" => [
        {
          "type" => "text",
          "text" => "Test initialization"
        }
      ]
    }

    component = Folio::Tiptap::Content::ProseMirrorNodeComponent.new(
      record: build_mock_record,
      prose_mirror_node:
    )

    # Component should initialize without errors
    render_inline(component)
    assert_selector("p", text: "Test initialization")
  end

  def test_render_folio_tiptap_columns
    prose_mirror_node = {
      "type" => "folioTiptapColumns",
      "content" => [
        {
          "type" => "folioTiptapColumn",
          "content" => [
            {
              "type" => "text",
              "text" => "First part"
            }
          ]
        },
        {
          "type" => "folioTiptapColumn",
          "content" => [
            {
              "type" => "text",
              "text" => "Second part"
            }
          ]
        }
      ]
    }

    render_inline(Folio::Tiptap::Content::ProseMirrorNodeComponent.new(record: build_mock_record, prose_mirror_node:))

    assert_selector(".f-tiptap-columns")
    assert_selector(".f-tiptap-columns .f-tiptap-column:first-child", text: "First part")
    assert_selector(".f-tiptap-columns .f-tiptap-column:last-child", text: "Second part")
  end

  def test_render_folio_tiptap_float
    prose_mirror_node = {
      "type" => "folioTiptapFloat",
      "content" => [
        {
          "type" => "folioTiptapFloatAside",
          "content" => [
            {
              "type" => "text",
              "text" => "Aside part"
            }
          ]
        },
        {
          "type" => "folioTiptapFloatMain",
          "content" => [
            {
              "type" => "text",
              "text" => "Main part"
            }
          ]
        }
      ]
    }

    render_inline(Folio::Tiptap::Content::ProseMirrorNodeComponent.new(record: build_mock_record, prose_mirror_node:))

    assert_selector(".f-tiptap-float")
    assert_selector(".f-tiptap-float[data-f-tiptap-float-size='medium']")
    assert_selector(".f-tiptap-float[data-f-tiptap-float-side='left']")
    assert_selector(".f-tiptap-float .f-tiptap-float__aside", text: "Aside part")
    assert_selector(".f-tiptap-float .f-tiptap-float__main", text: "Main part")

    prose_mirror_node = {
      "type" => "folioTiptapFloat",
      "attrs" => { "size" => "large", "side" => "right" },
      "content" => [
        {
          "type" => "folioTiptapFloatAside",
          "content" => [
            {
              "type" => "text",
              "text" => "Aside part"
            }
          ]
        },
        {
          "type" => "folioTiptapFloatMain",
          "content" => [
            {
              "type" => "text",
              "text" => "Main part"
            }
          ]
        }
      ]
    }

    render_inline(Folio::Tiptap::Content::ProseMirrorNodeComponent.new(record: build_mock_record, prose_mirror_node:))

    assert_selector(".f-tiptap-float")
    assert_selector(".f-tiptap-float[data-f-tiptap-float-size='large']")
    assert_selector(".f-tiptap-float[data-f-tiptap-float-side='right']")
    assert_selector(".f-tiptap-float .f-tiptap-float__aside", text: "Aside part")
    assert_selector(".f-tiptap-float .f-tiptap-float__main", text: "Main part")
  end

  def test_render_folio_tiptap_styled_paragraph
    prose_mirror_node = {
      "type" => "folioTiptapStyledParagraph",
      "content" => [
        {
          "type" => "text",
          "text" => "hello",
        },
      ]
    }

    render_inline(Folio::Tiptap::Content::ProseMirrorNodeComponent.new(record: build_mock_record, prose_mirror_node:))

    assert_selector("p.f-tiptap-styled-paragraph")
    assert_no_selector("p.f-tiptap-styled-paragraph[data-f-tiptap-styled-paragraph-variant='small']")
    assert_no_selector("p.f-tiptap-styled-paragraph[data-f-tiptap-styled-paragraph-variant='large']")

    prose_mirror_node = {
      "type" => "folioTiptapStyledParagraph",
      "content" => [
        {
          "type" => "text",
          "text" => "hello",
        },
      ],
      "attrs" => {
        "variant" => "large",
      }
    }

    render_inline(Folio::Tiptap::Content::ProseMirrorNodeComponent.new(record: build_mock_record, prose_mirror_node:))

    assert_no_selector("p.f-tiptap-styled-paragraph[data-f-tiptap-styled-paragraph-variant='small']")
    assert_selector("p.f-tiptap-styled-paragraph[data-f-tiptap-styled-paragraph-variant='large']")

    prose_mirror_node = {
      "type" => "folioTiptapStyledParagraph",
      "content" => [
        {
          "type" => "text",
          "text" => "hello",
        },
      ],
      "attrs" => {
        "variant" => "small",
      }
    }

    render_inline(Folio::Tiptap::Content::ProseMirrorNodeComponent.new(record: build_mock_record, prose_mirror_node:))

    assert_no_selector("p.f-tiptap-styled-paragraph[data-f-tiptap-styled-paragraph-variant='large']")
    assert_selector("p.f-tiptap-styled-paragraph[data-f-tiptap-styled-paragraph-variant='small']")
  end

  def test_render_table_node
    prose_mirror_node = {
      "type" => "table",
      "content" => [
        {
          "type" => "tableRow",
          "content" => [
            {
              "type" => "tableHeader",
              "content" => [
                {
                  "type" => "paragraph",
                  "content" => [
                    {
                      "type" => "text",
                      "text" => "Header 1"
                    }
                  ]
                }
              ]
            },
            {
              "type" => "tableHeader",
              "content" => [
                {
                  "type" => "paragraph",
                  "content" => [
                    {
                      "type" => "text",
                      "text" => "Header 2"
                    }
                  ]
                }
              ]
            }
          ]
        },
        {
          "type" => "tableRow",
          "content" => [
            {
              "type" => "tableCell",
              "content" => [
                {
                  "type" => "paragraph",
                  "content" => [
                    {
                      "type" => "text",
                      "text" => "Cell 1"
                    }
                  ]
                }
              ]
            },
            {
              "type" => "tableCell",
              "content" => [
                {
                  "type" => "paragraph",
                  "content" => [
                    {
                      "type" => "text",
                      "text" => "Cell 2"
                    }
                  ]
                }
              ]
            }
          ]
        }
      ]
    }

    render_inline(Folio::Tiptap::Content::ProseMirrorNodeComponent.new(record: build_mock_record, prose_mirror_node:))

    assert_selector(".f-tiptap-table-wrapper")
    assert_selector(".f-tiptap-table-wrapper table")
    assert_selector("th", count: 2)
    assert_selector("td", count: 2)
    assert_text("Header 1")
    assert_text("Header 2")
    assert_text("Cell 1")
    assert_text("Cell 2")
  end

  def test_render_simple_table_with_single_cell
    prose_mirror_node = {
      "type" => "table",
      "content" => [
        {
          "type" => "tableRow",
          "content" => [
            {
              "type" => "tableCell",
              "content" => [
                {
                  "type" => "paragraph",
                  "content" => [
                    {
                      "type" => "text",
                      "text" => "Single cell"
                    }
                  ]
                }
              ]
            }
          ]
        }
      ]
    }

    render_inline(Folio::Tiptap::Content::ProseMirrorNodeComponent.new(record: build_mock_record, prose_mirror_node:))

    assert_selector(".f-tiptap-table-wrapper")
    assert_selector(".f-tiptap-table-wrapper table")
    assert_selector("td", count: 1)
    assert_text("Single cell")
  end

  def test_render_table_with_empty_cells
    prose_mirror_node = {
      "type" => "table",
      "content" => [
        {
          "type" => "tableRow",
          "content" => [
            {
              "type" => "tableCell",
              "content" => []
            },
            {
              "type" => "tableCell",
              "content" => [
                {
                  "type" => "paragraph",
                  "content" => [
                    {
                      "type" => "text",
                      "text" => "Not empty"
                    }
                  ]
                }
              ]
            }
          ]
        }
      ]
    }

    render_inline(Folio::Tiptap::Content::ProseMirrorNodeComponent.new(record: build_mock_record, prose_mirror_node:))

    assert_selector(".f-tiptap-table-wrapper")
    assert_selector(".f-tiptap-table-wrapper table")
    assert_selector("td", count: 2)
    assert_text("Not empty")
  end

  private
    def build_mock_record
      Object.new
    end
end
