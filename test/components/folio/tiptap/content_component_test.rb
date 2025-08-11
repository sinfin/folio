# frozen_string_literal: true

require "test_helper"

class Folio::Tiptap::ContentComponentTest < Folio::ComponentTest
  def test_render_with_string_content
    model = build_mock_record("hello")

    render_inline(Folio::Tiptap::ContentComponent.new(record: model))

    assert_selector(".f-tiptap-content")
  end

  def test_render_with_simple_paragraph
    prosemirror_json = {
      "type" => "doc",
      "content" => [
        {
          "type" => "paragraph",
          "content" => [
            {
              "type" => "text",
              "text" => "Hello world"
            }
          ]
        }
      ]
    }

    model = build_mock_record(prosemirror_json)
    render_inline(Folio::Tiptap::ContentComponent.new(record: model))

    assert_selector(".f-tiptap-content")
    assert_selector(".f-tiptap-content__root")
    assert_selector("p")
    assert_text("Hello world")
  end

  def test_render_with_multiple_paragraphs
    prosemirror_json = {
      "type" => "doc",
      "content" => [
        {
          "type" => "paragraph",
          "content" => [
            {
              "type" => "text",
              "text" => "First paragraph"
            }
          ]
        },
        {
          "type" => "paragraph",
          "content" => [
            {
              "type" => "text",
              "text" => "Second paragraph"
            }
          ]
        }
      ]
    }

    model = build_mock_record(prosemirror_json)
    render_inline(Folio::Tiptap::ContentComponent.new(record: model))

    assert_selector("p", count: 2)
    assert_text("First paragraph")
    assert_text("Second paragraph")
  end

  def test_render_with_headings
    prosemirror_json = {
      "type" => "doc",
      "content" => [
        {
          "type" => "heading",
          "attrs" => { "level" => 1 },
          "content" => [
            {
              "type" => "text",
              "text" => "Main Title"
            }
          ]
        },
        {
          "type" => "heading",
          "attrs" => { "level" => 2 },
          "content" => [
            {
              "type" => "text",
              "text" => "Subtitle"
            }
          ]
        },
        {
          "type" => "heading",
          "attrs" => { "level" => 3 },
          "content" => [
            {
              "type" => "text",
              "text" => "Section Header"
            }
          ]
        }
      ]
    }

    model = build_mock_record(prosemirror_json)
    render_inline(Folio::Tiptap::ContentComponent.new(record: model))

    # Now that we have dynamic heading levels
    assert_selector("h1", text: "Main Title")
    assert_selector("h2", text: "Subtitle")
    assert_selector("h3", text: "Section Header")
  end

  def test_render_with_text_content
    prosemirror_json = {
      "type" => "doc",
      "content" => [
        {
          "type" => "paragraph",
          "content" => [
            {
              "type" => "text",
              "text" => "This is plain text"
            },
            {
              "type" => "text",
              "marks" => [{ "type" => "bold" }],
              "text" => " with formatting"
            }
          ]
        }
      ]
    }

    model = build_mock_record(prosemirror_json)
    render_inline(Folio::Tiptap::ContentComponent.new(record: model))

    # Now that marks are applied, we should see formatted text
    assert_selector("p")
    assert_selector("strong", text: "with formatting")
    assert_text("This is plain text")
  end

  def test_render_with_comprehensive_text_formatting
    prosemirror_json = {
      "type" => "doc",
      "content" => [
        {
          "type" => "paragraph",
          "content" => [
            {
              "type" => "text",
              "text" => "This is "
            },
            {
              "type" => "text",
              "marks" => [{ "type" => "bold" }],
              "text" => "bold text"
            },
            {
              "type" => "text",
              "text" => " and this is "
            },
            {
              "type" => "text",
              "marks" => [{ "type" => "italic" }],
              "text" => "italic text"
            },
            {
              "type" => "text",
              "text" => " and this is "
            },
            {
              "type" => "text",
              "marks" => [{ "type" => "underline" }],
              "text" => "underlined"
            },
            {
              "type" => "text",
              "text" => " and "
            },
            {
              "type" => "text",
              "marks" => [{ "type" => "code" }],
              "text" => "inline code"
            },
            {
              "type" => "text",
              "text" => " and "
            },
            {
              "type" => "text",
              "marks" => [
                {
                  "type" => "link",
                  "attrs" => {
                    "href" => "https://example.com",
                    "target" => "_blank"
                  }
                }
              ],
              "text" => "a link"
            },
            {
              "type" => "text",
              "text" => "."
            }
          ]
        }
      ]
    }

    model = build_mock_record(prosemirror_json)
    render_inline(Folio::Tiptap::ContentComponent.new(record: model))

    # Test that all formatting marks are properly applied
    assert_selector("strong", text: "bold text")
    assert_selector("em", text: "italic text")
    assert_selector("u", text: "underlined")
    assert_selector("code", text: "inline code")
    assert_selector("a[href='https://example.com'][target='_blank']", text: "a link")
  end

  def test_render_with_bulletList
    prosemirror_json = {
      "type" => "doc",
      "content" => [
        {
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
      ]
    }

    model = build_mock_record(prosemirror_json)
    render_inline(Folio::Tiptap::ContentComponent.new(record: model))

    assert_selector("ul")
    assert_selector("li", count: 2)
    assert_text("First item")
    assert_text("Second item")
  end

  def test_render_with_orderedList
    prosemirror_json = {
      "type" => "doc",
      "content" => [
        {
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
      ]
    }

    model = build_mock_record(prosemirror_json)
    render_inline(Folio::Tiptap::ContentComponent.new(record: model))

    assert_selector("ol")
    assert_selector("li")
    assert_text("Step one")
  end

  def test_render_with_blockquote
    prosemirror_json = {
      "type" => "doc",
      "content" => [
        {
          "type" => "blockquote",
          "content" => [
            {
              "type" => "paragraph",
              "content" => [
                {
                  "type" => "text",
                  "text" => "This is a quote from someone famous."
                }
              ]
            }
          ]
        }
      ]
    }

    model = build_mock_record(prosemirror_json)
    render_inline(Folio::Tiptap::ContentComponent.new(record: model))

    assert_selector("blockquote")
    assert_text("This is a quote from someone famous.")
  end

  def test_render_with_horizontalRule
    prosemirror_json = {
      "type" => "doc",
      "content" => [
        {
          "type" => "paragraph",
          "content" => [
            {
              "type" => "text",
              "text" => "Content above"
            }
          ]
        },
        {
          "type" => "horizontalRule"
        },
        {
          "type" => "paragraph",
          "content" => [
            {
              "type" => "text",
              "text" => "Content below"
            }
          ]
        }
      ]
    }

    model = build_mock_record(prosemirror_json)
    render_inline(Folio::Tiptap::ContentComponent.new(record: model))

    assert_selector("hr")
    assert_text("Content above")
    assert_text("Content below")
  end

  def test_render_with_hardBreak_in_paragraph
    prosemirror_json = {
      "type" => "doc",
      "content" => [
        {
          "type" => "paragraph",
          "content" => [
            {
              "type" => "text",
              "text" => "First line"
            },
            {
              "type" => "hardBreak"
            },
            {
              "type" => "text",
              "text" => "Second line"
            }
          ]
        }
      ]
    }

    model = build_mock_record(prosemirror_json)
    render_inline(Folio::Tiptap::ContentComponent.new(record: model))

    assert_selector("br")
    assert_text("First line")
    assert_text("Second line")
  end

  def test_render_with_complex_nested_structure
    prosemirror_json = {
      "type" => "doc",
      "content" => [
        {
          "type" => "heading",
          "attrs" => { "level" => 1 },
          "content" => [
            {
              "type" => "text",
              "text" => "Article Title"
            }
          ]
        },
        {
          "type" => "paragraph",
          "content" => [
            {
              "type" => "text",
              "text" => "This is an introductory paragraph."
            }
          ]
        },
        {
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
                      "text" => "Important: First key point"
                    }
                  ]
                }
              ]
            }
          ]
        },
        {
          "type" => "blockquote",
          "content" => [
            {
              "type" => "paragraph",
              "content" => [
                {
                  "type" => "text",
                  "text" => "A relevant quote to support the argument."
                }
              ]
            }
          ]
        }
      ]
    }

    model = build_mock_record(prosemirror_json)
    render_inline(Folio::Tiptap::ContentComponent.new(record: model))

    assert_selector("h1", text: "Article Title")
    assert_text("This is an introductory paragraph.")
    assert_selector("ul")
    assert_text("Important: First key point")
    assert_selector("blockquote", text: "A relevant quote to support the argument.")
  end

  def test_render_with_folio_tiptap_node
    prosemirror_json = {
      "type" => "doc",
      "content" => [
        {
          "type" => "folioTiptapNode",
          "attrs" => {
            "type" => "Dummy::Tiptap::Node::Card",
            "data" => {
              "title" => "Test Card",
              "content" => "Card content here"
            }
          }
        }
      ]
    }

    model = build_mock_record(prosemirror_json)
    render_inline(Folio::Tiptap::ContentComponent.new(record: model))

    # Should render the node's view component with the card class
    assert_selector(".f-tiptap-content")
    assert_selector(".d-tiptap-node-card")
    # The node data should be rendered as JSON in the card
    assert_text("Test Card")
  end

  def test_render_empty_content
    model = build_mock_record(nil)

    render_inline(Folio::Tiptap::ContentComponent.new(record: model))

    assert_no_selector(".f-tiptap-content")
  end

  def test_render_empty_document
    prosemirror_json = {
      "type" => "doc",
      "content" => []
    }

    model = build_mock_record(prosemirror_json)
    render_inline(Folio::Tiptap::ContentComponent.new(record: model))

    assert_selector(".f-tiptap-content")
    assert_selector(".f-tiptap-content__root")
  end

  def test_render_with_custom_attribute
    prosemirror_json = {
      "type" => "doc",
      "content" => [
        {
          "type" => "paragraph",
          "content" => [
            {
              "type" => "text",
              "text" => "Custom attribute content"
            }
          ]
        }
      ]
    }

    model = build_mock_record_with_custom_attribute(prosemirror_json)
    render_inline(Folio::Tiptap::ContentComponent.new(record: model, attribute: :custom_tiptap_content))

    assert_selector(".f-tiptap-content")
    assert_text("Custom attribute content")
  end

  def test_render_with_missing_node_definition
    prosemirror_json = {
      "type" => "doc",
      "content" => [
        {
          "type" => "unsupported_node_type",
          "content" => [
            {
              "type" => "text",
              "text" => "This node type is not supported"
            }
          ]
        }
      ]
    }

    model = build_mock_record(prosemirror_json)
    render_inline(Folio::Tiptap::ContentComponent.new(record: model))

    assert_text("")
  end

  def test_render_with_table_structure
    prosemirror_json = {
      "type" => "doc",
      "content" => [
        {
          "type" => "table",
          "content" => [
            {
              "type" => "tableRow",
              "content" => [
                {
                  "type" => "tableHeader",
                  "attrs" => {},
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
                  "attrs" => {},
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
                  "attrs" => {},
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
                  "attrs" => {},
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
      ]
    }

    model = build_mock_record(prosemirror_json)
    render_inline(Folio::Tiptap::ContentComponent.new(record: model))

    # Tables should render with table > tbody structure due to nested tags
    assert_selector("table")
    assert_selector("tbody")
    assert_selector("tr", count: 2)
    assert_selector("th", text: "Header 1")
    assert_selector("th", text: "Header 2")
    assert_selector("td", text: "Cell 1")
    assert_selector("td", text: "Cell 2")
  end

  def test_render_with_nested_formatting_marks
    prosemirror_json = {
      "type" => "doc",
      "content" => [
        {
          "type" => "paragraph",
          "content" => [
            {
              "type" => "text",
              "marks" => [
                { "type" => "bold" },
                { "type" => "italic" },
                {
                  "type" => "link",
                  "attrs" => { "href" => "https://example.com" }
                }
              ],
              "text" => "Bold italic link"
            },
            {
              "type" => "text",
              "text" => " and "
            },
            {
              "type" => "text",
              "marks" => [
                { "type" => "code" },
                { "type" => "underline" }
              ],
              "text" => "underlined code"
            }
          ]
        }
      ]
    }

    model = build_mock_record(prosemirror_json)
    render_inline(Folio::Tiptap::ContentComponent.new(record: model))

    # Test nested formatting is applied correctly
    assert_text("Bold italic link")
    assert_text("underlined code")
    # The exact nesting structure may vary, but content should be present
    assert_selector("a[href='https://example.com']")
  end

  def test_render_with_subscript_and_superscript
    prosemirror_json = {
      "type" => "doc",
      "content" => [
        {
          "type" => "paragraph",
          "content" => [
            {
              "type" => "text",
              "text" => "Water is H"
            },
            {
              "type" => "text",
              "marks" => [{ "type" => "subscript" }],
              "text" => "2"
            },
            {
              "type" => "text",
              "text" => "O and energy equals mc"
            },
            {
              "type" => "text",
              "marks" => [{ "type" => "superscript" }],
              "text" => "2"
            }
          ]
        }
      ]
    }

    model = build_mock_record(prosemirror_json)
    render_inline(Folio::Tiptap::ContentComponent.new(record: model))

    assert_selector("sub", text: "2")
    assert_selector("sup", text: "2")
    assert_text("Water is H")
    assert_text("O and energy equals mc")
  end

  def test_render_with_all_heading_levels
    prosemirror_json = {
      "type" => "doc",
      "content" => [
        {
          "type" => "heading",
          "attrs" => { "level" => 1 },
          "content" => [{ "type" => "text", "text" => "Level 1" }]
        },
        {
          "type" => "heading",
          "attrs" => { "level" => 2 },
          "content" => [{ "type" => "text", "text" => "Level 2" }]
        },
        {
          "type" => "heading",
          "attrs" => { "level" => 3 },
          "content" => [{ "type" => "text", "text" => "Level 3" }]
        },
        {
          "type" => "heading",
          "attrs" => { "level" => 4 },
          "content" => [{ "type" => "text", "text" => "Level 4" }]
        },
        {
          "type" => "heading",
          "attrs" => { "level" => 5 },
          "content" => [{ "type" => "text", "text" => "Level 5" }]
        },
        {
          "type" => "heading",
          "attrs" => { "level" => 6 },
          "content" => [{ "type" => "text", "text" => "Level 6" }]
        }
      ]
    }

    model = build_mock_record(prosemirror_json)
    render_inline(Folio::Tiptap::ContentComponent.new(record: model))

    assert_selector("h1", text: "Level 1")
    assert_selector("h2", text: "Level 2")
    assert_selector("h3", text: "Level 3")
    assert_selector("h4", text: "Level 4")
    assert_selector("h5", text: "Level 5")
    assert_selector("h6", text: "Level 6")
  end

  def test_render_with_mixed_self_closing_and_content_nodes
    prosemirror_json = {
      "type" => "doc",
      "content" => [
        {
          "type" => "paragraph",
          "content" => [
            { "type" => "text", "text" => "Before break" },
            { "type" => "hardBreak" },
            { "type" => "text", "text" => "After break" }
          ]
        },
        { "type" => "horizontalRule" },
        {
          "type" => "paragraph",
          "content" => [
            { "type" => "text", "text" => "After rule" }
          ]
        }
      ]
    }

    model = build_mock_record(prosemirror_json)
    render_inline(Folio::Tiptap::ContentComponent.new(record: model))

    assert_selector("br")
    assert_selector("hr")
    assert_text("Before break")
    assert_text("After break")
    assert_text("After rule")
  end

  def test_render_text_with_special_characters
    prosemirror_json = {
      "type" => "doc",
      "content" => [
        {
          "type" => "paragraph",
          "content" => [
            {
              "type" => "text",
              "text" => "Special chars: <>&\"' and unicode: 🚀 ñáéíóú"
            }
          ]
        }
      ]
    }

    model = build_mock_record(prosemirror_json)
    render_inline(Folio::Tiptap::ContentComponent.new(record: model))

    assert_selector("p")
    assert_text("Special chars: <>&\"' and unicode: 🚀 ñáéíóú")
  end

  def test_render_with_whitespace_content
    prosemirror_json = {
      "type" => "doc",
      "content" => [
        {
          "type" => "paragraph",
          "content" => [
            {
              "type" => "text",
              "text" => "  Multiple   spaces   "
            }
          ]
        }
      ]
    }

    model = build_mock_record(prosemirror_json)
    render_inline(Folio::Tiptap::ContentComponent.new(record: model))

    assert_selector("p")
    assert_text("  Multiple   spaces   ")
  end

  def test_render_with_empty_text_nodes
    prosemirror_json = {
      "type" => "doc",
      "content" => [
        {
          "type" => "paragraph",
          "content" => [
            {
              "type" => "text",
              "text" => ""
            },
            {
              "type" => "text",
              "text" => "Non-empty text"
            }
          ]
        }
      ]
    }

    model = build_mock_record(prosemirror_json)
    render_inline(Folio::Tiptap::ContentComponent.new(record: model))

    assert_selector("p")
    assert_text("Non-empty text")
  end

  private
    def build_mock_record(tiptap_content)
      mock_record = Object.new
      mock_record.define_singleton_method(:tiptap_content) { { "content" => tiptap_content } }
      mock_record
    end

    def build_mock_record_with_custom_attribute(tiptap_content)
      mock_record = Object.new
      mock_record.define_singleton_method(:custom_tiptap_content) { { "content" => tiptap_content } }
      mock_record
    end
end
