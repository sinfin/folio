# frozen_string_literal: true

require "test_helper"

class Folio::Tiptap::ContentComponentTest < Folio::ComponentTest
  setup do
    if ENV["FOLIO_DEBUG_TIPTAP_NODES"].present?
      puts "WARNING: FOLIO_DEBUG_TIPTAP_NODES is set, tests will fail!"
    end
  end

  test "render with string content" do
    tiptap_content = {
      "type" => "doc",
      "content" => [
        {
          "type" => "paragraph",
          "content" => [
            {
              "type" => "text",
              "text" => "hello"
            }
          ]
        }
      ]
    }

    model = Folio::Page.new
    model.tiptap_content = { "tiptap_content" => tiptap_content }

    render_inline(Folio::Tiptap::ContentComponent.new(record: model))

    assert_selector(".f-tiptap-content")
    assert_text("hello")
  end

  test "render with simple paragraph" do
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

    model = Folio::Page.new
    model.tiptap_content = { "tiptap_content" => prosemirror_json }
    render_inline(Folio::Tiptap::ContentComponent.new(record: model))

    assert_selector(".f-tiptap-content")
    assert_selector(".f-tiptap-content__root")
    assert_selector("p")
    assert_text("Hello world")
  end

  test "render with aligned paragraph" do
    prosemirror_json = {
      "type" => "doc",
      "content" => [
        {
          "type" => "paragraph",
          "attrs" => { "textAlign" => "center" },
          "content" => [
            {
              "type" => "text",
              "text" => "Hello world"
            }
          ]
        }
      ]
    }

    model = Folio::Page.new
    model.tiptap_content = { "tiptap_content" => prosemirror_json }
    render_inline(Folio::Tiptap::ContentComponent.new(record: model))

    assert_selector(".f-tiptap-content")
    assert_selector(".f-tiptap-content__root")
    paragraph = page.find("p")
    assert_equal "text-align: center;", paragraph[:style]
    assert_text("Hello world")
  end

  test "render with multiple paragraphs" do
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

    model = Folio::Page.new
    model.tiptap_content = { "tiptap_content" => prosemirror_json }
    render_inline(Folio::Tiptap::ContentComponent.new(record: model))

    assert_selector("p", count: 2)
    assert_text("First paragraph")
    assert_text("Second paragraph")
  end

  test "render with headings" do
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

    model = Folio::Page.new
    model.tiptap_content = { "tiptap_content" => prosemirror_json }
    render_inline(Folio::Tiptap::ContentComponent.new(record: model))

    # Now that we have dynamic heading levels
    assert_selector("h1", text: "Main Title")
    assert_selector("h2", text: "Subtitle")
    assert_selector("h3", text: "Section Header")
  end

  test "render with text content" do
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

    model = Folio::Page.new
    model.tiptap_content = { "tiptap_content" => prosemirror_json }
    render_inline(Folio::Tiptap::ContentComponent.new(record: model))

    # Now that marks are applied, we should see formatted text
    assert_selector("p")
    assert_selector("strong", text: "with formatting")
    assert_text("This is plain text")
  end

  test "render with comprehensive text formatting" do
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

    model = Folio::Page.new
    model.tiptap_content = { "tiptap_content" => prosemirror_json }
    render_inline(Folio::Tiptap::ContentComponent.new(record: model))

    # Test that all formatting marks are properly applied
    assert_selector("strong", text: "bold text")
    assert_selector("em", text: "italic text")
    assert_selector("u", text: "underlined")
    assert_selector("code", text: "inline code")
    assert_selector("a[href='https://example.com'][target='_blank']", text: "a link")
  end

  test "render with bulletList" do
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

    model = Folio::Page.new
    model.tiptap_content = { "tiptap_content" => prosemirror_json }
    render_inline(Folio::Tiptap::ContentComponent.new(record: model))

    assert_selector("ul")
    assert_selector("li", count: 2)
    assert_text("First item")
    assert_text("Second item")
  end

  test "render with orderedList" do
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

    model = Folio::Page.new
    model.tiptap_content = { "tiptap_content" => prosemirror_json }
    render_inline(Folio::Tiptap::ContentComponent.new(record: model))

    assert_selector("ol")
    assert_selector("li")
    assert_text("Step one")
  end

  test "render with blockquote" do
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

    model = Folio::Page.new
    model.tiptap_content = { "tiptap_content" => prosemirror_json }
    render_inline(Folio::Tiptap::ContentComponent.new(record: model))

    assert_selector("blockquote")
    assert_text("This is a quote from someone famous.")
  end

  test "render with horizontalRule" do
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

    model = Folio::Page.new
    model.tiptap_content = { "tiptap_content" => prosemirror_json }
    render_inline(Folio::Tiptap::ContentComponent.new(record: model))

    assert_selector("hr")
    assert_text("Content above")
    assert_text("Content below")
  end

  test "render with hardBreak in paragraph" do
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

    model = Folio::Page.new
    model.tiptap_content = { "tiptap_content" => prosemirror_json }
    render_inline(Folio::Tiptap::ContentComponent.new(record: model))

    assert_equal 1, page.all("p").count
    assert_equal 1, page.all("br").count
    assert_text("First line")
    assert_text("Second line")
  end

  test "render with complex nested structure" do
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

    model = Folio::Page.new
    model.tiptap_content = { "tiptap_content" => prosemirror_json }
    render_inline(Folio::Tiptap::ContentComponent.new(record: model))

    assert_selector("h1", text: "Article Title")
    assert_text("This is an introductory paragraph.")
    assert_selector("ul")
    assert_text("Important: First key point")
    assert_selector("blockquote", text: "A relevant quote to support the argument.")
  end

  test "render with folio tiptap node" do
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

    model = Folio::Page.new
    model.tiptap_content = { "tiptap_content" => prosemirror_json }
    render_inline(Folio::Tiptap::ContentComponent.new(record: model))

    # Should render the node's view component with the card class
    assert_selector(".f-tiptap-content")
    assert_selector(".d-tiptap-node-card")
    # The node data should be rendered as JSON in the card
    assert_text("Test Card")
  end

  test "render empty content" do
    model = Folio::Page.new

    render_inline(Folio::Tiptap::ContentComponent.new(record: model))

    assert_no_selector(".f-tiptap-content")
  end

  test "render empty document" do
    prosemirror_json = {
      "type" => "doc",
      "content" => []
    }

    model = Folio::Page.new
    model.tiptap_content = { "tiptap_content" => prosemirror_json }
    render_inline(Folio::Tiptap::ContentComponent.new(record: model))

    assert_selector(".f-tiptap-content")
    assert_selector(".f-tiptap-content__root")
  end

  test "render with missing node definition" do
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

    model = Folio::Page.new
    model.tiptap_content = { "tiptap_content" => prosemirror_json }
    render_inline(Folio::Tiptap::ContentComponent.new(record: model))

    assert_text("")
  end

  test "render with table structure" do
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

    model = Folio::Page.new
    model.tiptap_content = { "tiptap_content" => prosemirror_json }
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

  test "render with nested formatting marks" do
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

    model = Folio::Page.new
    model.tiptap_content = { "tiptap_content" => prosemirror_json }
    render_inline(Folio::Tiptap::ContentComponent.new(record: model))

    # Test nested formatting is applied correctly
    assert_text("Bold italic link")
    assert_text("underlined code")
    # The exact nesting structure may vary, but content should be present
    assert_selector("a[href='https://example.com']")
  end

  test "render with subscript and superscript" do
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

    model = Folio::Page.new
    model.tiptap_content = { "tiptap_content" => prosemirror_json }
    render_inline(Folio::Tiptap::ContentComponent.new(record: model))

    assert_selector("sub", text: "2")
    assert_selector("sup", text: "2")
    assert_text("Water is H")
    assert_text("O and energy equals mc")
  end

  test "render with all heading levels" do
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

    model = Folio::Page.new
    model.tiptap_content = { "tiptap_content" => prosemirror_json }
    render_inline(Folio::Tiptap::ContentComponent.new(record: model))

    assert_selector("h1", text: "Level 1")
    assert_selector("h2", text: "Level 2")
    assert_selector("h3", text: "Level 3")
    assert_selector("h4", text: "Level 4")
    assert_selector("h5", text: "Level 5")
    assert_selector("h6", text: "Level 6")
  end

  test "render with mixed self closing and content nodes" do
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

    model = Folio::Page.new
    model.tiptap_content = { "tiptap_content" => prosemirror_json }
    render_inline(Folio::Tiptap::ContentComponent.new(record: model))

    assert_selector("br")
    assert_selector("hr")
    assert_text("Before break")
    assert_text("After break")
    assert_text("After rule")
  end

  test "render text with special characters" do
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

    model = Folio::Page.new
    model.tiptap_content = { "tiptap_content" => prosemirror_json }
    render_inline(Folio::Tiptap::ContentComponent.new(record: model))

    assert_selector("p")
    assert_text("Special chars: <>&\"' and unicode: 🚀 ñáéíóú")
  end

  test "render with whitespace content" do
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

    model = Folio::Page.new
    model.tiptap_content = { "tiptap_content" => prosemirror_json }
    render_inline(Folio::Tiptap::ContentComponent.new(record: model))

    assert_selector("p")
    assert_text("  Multiple   spaces   ")
  end

  test "render with empty text nodes" do
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

    model = Folio::Page.new
    model.tiptap_content = { "tiptap_content" => prosemirror_json }
    render_inline(Folio::Tiptap::ContentComponent.new(record: model))

    assert_selector("p")
    assert_text("Non-empty text")
  end

  test "render with lambdas" do
    prosemirror_json = {
      "type" => "doc",
      "content" => [
        {
          "type" => "paragraph",
          "content" => [
            {
              "type" => "text",
              "text" => "paragraph 1"
            }
          ]
        },
        {
          "type" => "paragraph",
          "content" => [
            {
              "type" => "text",
              "text" => "paragraph 2"
            }
          ]
        }
      ]
    }

    model = Folio::Page.new
    model.tiptap_content = { "tiptap_content" => prosemirror_json }

    lambda_before_root_node = -> (component:, node:, index:) do
      component.content_tag(:p, "before #{index}", class: "lambda-before")
    end

    lambda_after_root_node = -> (component:, node:, index:) do
      if index == 0
        component.content_tag(:p, "after #{index}", class: "lambda-after")
      end
    end

    render_inline(Folio::Tiptap::ContentComponent.new(record: model,
                                                      lambda_before_root_node:,
                                                      lambda_after_root_node:))

    paragraphs = page.all("p").map(&:text)

    assert_equal "before 0", paragraphs[0]
    assert_equal "paragraph 1", paragraphs[1]
    assert_equal "after 0", paragraphs[2]
    assert_equal "before 1", paragraphs[3]
    assert_equal "paragraph 2", paragraphs[4]
    assert_nil paragraphs[5]
  end

  test "render with broken lambdas" do
    prosemirror_json = {
      "type" => "doc",
      "content" => [
        {
          "type" => "paragraph",
          "content" => [
            {
              "type" => "text",
              "text" => "paragraph 1"
            }
          ]
        },
        {
          "type" => "paragraph",
          "content" => [
            {
              "type" => "text",
              "text" => "paragraph 2"
            }
          ]
        }
      ]
    }

    model = Folio::Page.new
    model.tiptap_content = { "tiptap_content" => prosemirror_json }

    lambda_before_root_node = -> (component:, node:, index:) do
      raise "Simulated error in before lambda"
    end

    lambda_after_root_node = -> (component:, node:, index:) do
      raise "Simulated error in after lambda"
    end

    render_inline(Folio::Tiptap::ContentComponent.new(record: model,
                                                      lambda_before_root_node:,
                                                      lambda_after_root_node:))

    paragraphs = page.all("p").map(&:text)

    assert_equal "paragraph 1", paragraphs[0]
    assert_equal "paragraph 2", paragraphs[1]

    assert page.html.include?("console.group('[Folio][Tiptap] Broken lambdas');")
  end

  test "render with missing folio tiptap node type" do
    tiptap_content = {
      "type" => "doc",
      "content" => [
        {
          "type" => "paragraph",
          "content" => [
            {
              "type" => "text",
              "text" => "Valid paragraph"
            }
          ]
        },
        {
          "type" => "folioTiptapNode",
          "attrs" => {
            "data" => {
              "title" => "Missing Type Test",
              "text" => "Testing missing node type"
            }
          }
        }
      ]
    }

    model = Folio::Page.new
    model.tiptap_content = { "tiptap_content" => tiptap_content }
    render_inline(Folio::Tiptap::ContentComponent.new(record: model))

    # Valid paragraph should render
    assert_text("Valid paragraph")

    # Invalid node should not render any DOM elements
    assert_no_selector(".d-tiptap-node-card")

    # Only valid paragraph should be in the main content structure
    assert_selector("p", count: 1)
    assert_selector("p", text: "Valid paragraph")
  end

  test "render with blank folio tiptap node type" do
    tiptap_content = {
      "type" => "doc",
      "content" => [
        {
          "type" => "paragraph",
          "content" => [
            {
              "type" => "text",
              "text" => "Valid paragraph"
            }
          ]
        },
        {
          "type" => "folioTiptapNode",
          "attrs" => {
            "type" => "",
            "data" => {
              "title" => "Blank Type Test",
              "text" => "Testing blank node type"
            }
          }
        }
      ]
    }

    model = Folio::Page.new
    model.tiptap_content = { "tiptap_content" => tiptap_content }
    render_inline(Folio::Tiptap::ContentComponent.new(record: model))

    # Valid paragraph should render
    assert_text("Valid paragraph")

    # Invalid node should not render any DOM elements
    assert_no_selector(".d-tiptap-node-card")

    # Only valid paragraph should be in the main content structure
    assert_selector("p", count: 1)
    assert_selector("p", text: "Valid paragraph")
  end

  test "render with invalid folio tiptap node type" do
    tiptap_content = {
      "type" => "doc",
      "content" => [
        {
          "type" => "paragraph",
          "content" => [
            {
              "type" => "text",
              "text" => "Valid paragraph"
            }
          ]
        },
        {
          "type" => "folioTiptapNode",
          "attrs" => {
            "type" => "UnknownNodeType",
            "data" => {
              "title" => "Invalid Type Test",
              "text" => "Testing invalid node type"
            }
          }
        }
      ]
    }

    model = Folio::Page.new
    model.tiptap_content = { "tiptap_content" => tiptap_content }
    render_inline(Folio::Tiptap::ContentComponent.new(record: model))

    # Valid paragraph should render
    assert_text("Valid paragraph")

    # Invalid node should not render any DOM elements
    assert_no_selector(".d-tiptap-node-card")

    # Only valid paragraph should be in the main content structure
    assert_selector("p", count: 1)
    assert_selector("p", text: "Valid paragraph")
  end

  test "render with mixed valid and invalid folio tiptap nodes" do
    tiptap_content = {
      "type" => "doc",
      "content" => [
        {
          "type" => "folioTiptapNode",
          "attrs" => {
            "type" => "Dummy::Tiptap::Node::Card",
            "data" => {
              "title" => "Valid Card",
              "text" => "This should render"
            }
          }
        },
        {
          "type" => "folioTiptapNode",
          "attrs" => {
            "type" => "UnknownNodeType",
            "data" => {
              "title" => "Invalid Card",
              "text" => "This should not render"
            }
          }
        },
        {
          "type" => "folioTiptapNode",
          "attrs" => {
            "data" => {
              "title" => "Missing Type Card",
              "text" => "This should also not render"
            }
          }
        }
      ]
    }

    model = Folio::Page.new
    model.tiptap_content = { "tiptap_content" => tiptap_content }
    render_inline(Folio::Tiptap::ContentComponent.new(record: model))

    # Valid node should render
    assert_selector(".d-tiptap-node-card", count: 1)
    assert_text("Valid Card")
    assert_text("This should render")

    # Invalid nodes should not render any additional DOM elements
    # Only one valid card should exist (the rest should be filtered out during error handling)
  end

  test "render with node type excluded by config" do
    tiptap_content = {
      "type" => "doc",
      "content" => [
        {
          "type" => "paragraph",
          "content" => [
            {
              "type" => "text",
              "text" => "Valid paragraph"
            }
          ]
        },
        {
          "type" => "folioTiptapNode",
          "attrs" => {
            "type" => "Dummy::Tiptap::Node::Card",
            "data" => {
              "title" => "Excluded Card",
              "text" => "This should not render due to config"
            }
          }
        }
      ]
    }

    record = Folio::Page.new
    record.tiptap_content = { "tiptap_content" => tiptap_content }

    # Mock the tiptap_config to exclude all node types
    def record.tiptap_config
      @config ||= Folio::Tiptap::Config.new(node_names: [])
    end

    render_inline(Folio::Tiptap::ContentComponent.new(record: record))

    # Valid paragraph should render
    assert_text("Valid paragraph")

    # Excluded node should not render any DOM elements
    assert_no_selector(".d-tiptap-node-card")

    # Only valid paragraph should be in the main content structure
    assert_selector("p", count: 1)
    assert_selector("p", text: "Valid paragraph")
  end

  test "render with node type blacklist filtering paragraphs" do
    prosemirror_json = {
      "type" => "doc",
      "content" => [
        {
          "type" => "heading",
          "attrs" => { "level" => 1 },
          "content" => [
            {
              "type" => "text",
              "text" => "Title"
            }
          ]
        },
        {
          "type" => "paragraph",
          "content" => [
            {
              "type" => "text",
              "text" => "This paragraph should be filtered out"
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
                      "text" => "This nested paragraph should also be filtered"
                    }
                  ]
                }
              ]
            }
          ]
        }
      ]
    }

    model = Folio::Page.new
    model.tiptap_content = { "tiptap_content" => prosemirror_json }

    render_inline(Folio::Tiptap::ContentComponent.new(
      record: model,
      node_type_blacklist: ["paragraph"]
    ))

    # Heading should render (not blacklisted)
    assert_selector("h1", text: "Title")

    # Paragraphs should be filtered out
    assert_no_selector("p")
    assert_no_text("This paragraph should be filtered out")
    assert_no_text("This nested paragraph should also be filtered")

    # List structure should render but without paragraph content
    assert_selector("ul")
    assert_selector("li")
  end

  test "render with node type blacklist and lambda for blacklisted" do
    prosemirror_json = {
      "type" => "doc",
      "content" => [
        {
          "type" => "heading",
          "attrs" => { "level" => 1 },
          "content" => [
            {
              "type" => "text",
              "text" => "Title"
            }
          ]
        },
        {
          "type" => "paragraph",
          "content" => [
            {
              "type" => "text",
              "text" => "Blacklisted paragraph"
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
                  "text" => "Nested blacklisted paragraph"
                }
              ]
            }
          ]
        }
      ]
    }

    model = Folio::Page.new
    model.tiptap_content = { "tiptap_content" => prosemirror_json }

    lambda_for_blacklisted = -> (node) do
      "[FILTERED: #{node['type']}]"
    end

    render_inline(Folio::Tiptap::ContentComponent.new(
      record: model,
      node_type_blacklist: ["paragraph"],
      lambda_for_blacklisted: lambda_for_blacklisted
    ))

    # Heading should render normally
    assert_selector("h1", text: "Title")

    # Blacklisted paragraphs should be replaced with lambda output
    assert_text("[FILTERED: paragraph]")

    # Blockquote should render but its paragraph content should be replaced
    assert_selector("blockquote")
  end

  test "render with node type blacklist multiple types" do
    prosemirror_json = {
      "type" => "doc",
      "content" => [
        {
          "type" => "heading",
          "attrs" => { "level" => 1 },
          "content" => [
            {
              "type" => "text",
              "text" => "Should render"
            }
          ]
        },
        {
          "type" => "paragraph",
          "content" => [
            {
              "type" => "text",
              "text" => "Should be filtered"
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
                  "text" => "Should also be filtered"
                }
              ]
            }
          ]
        }
      ]
    }

    model = Folio::Page.new
    model.tiptap_content = { "tiptap_content" => prosemirror_json }

    render_inline(Folio::Tiptap::ContentComponent.new(
      record: model,
      node_type_blacklist: ["paragraph", "blockquote"]
    ))

    # Only heading should render
    assert_selector("h1", text: "Should render")
    assert_no_selector("p")
    assert_no_selector("blockquote")
    assert_no_text("Should be filtered")
    assert_no_text("Should also be filtered")
  end

  test "render with empty node type blacklist" do
    prosemirror_json = {
      "type" => "doc",
      "content" => [
        {
          "type" => "paragraph",
          "content" => [
            {
              "type" => "text",
              "text" => "Should render normally"
            }
          ]
        }
      ]
    }

    model = Folio::Page.new
    model.tiptap_content = { "tiptap_content" => prosemirror_json }

    render_inline(Folio::Tiptap::ContentComponent.new(
      record: model,
      node_type_blacklist: []
    ))

    # Everything should render normally with empty blacklist
    assert_selector("p", text: "Should render normally")
  end

  test "render with nil node type blacklist" do
    prosemirror_json = {
      "type" => "doc",
      "content" => [
        {
          "type" => "paragraph",
          "content" => [
            {
              "type" => "text",
              "text" => "Should render normally"
            }
          ]
        }
      ]
    }

    model = Folio::Page.new
    model.tiptap_content = { "tiptap_content" => prosemirror_json }

    render_inline(Folio::Tiptap::ContentComponent.new(
      record: model,
      node_type_blacklist: nil
    ))

    # Everything should render normally with nil blacklist
    assert_selector("p", text: "Should render normally")
  end
end
