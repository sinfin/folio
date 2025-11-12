# frozen_string_literal: true

require "test_helper"

class Folio::Tiptap::Content::ProseMirrorNodeComponentTest < Folio::Tiptap::NodeComponentTest
  setup do
    if ENV["FOLIO_DEBUG_TIPTAP_NODES"].present?
      puts "WARNING: FOLIO_DEBUG_TIPTAP_NODES is set, tests will fail!"
    end
  end

  test "render simple text node" do
    prose_mirror_node = {
      "type" => "text",
      "text" => "Hello world"
    }

    render_inline(Folio::Tiptap::Content::ProseMirrorNodeComponent.new(record: Folio::Page.new, prose_mirror_node:, tiptap_content_information: tiptap_content_information(record: Folio::Page.new)))

    # Text nodes render the TextComponent directly, which just outputs text
    assert_text("Hello world")
  end

  test "render paragraph node" do
    prose_mirror_node = {
      "type" => "paragraph",
      "content" => [
        {
          "type" => "text",
          "text" => "This is a paragraph"
        }
      ]
    }

    render_inline(Folio::Tiptap::Content::ProseMirrorNodeComponent.new(record: Folio::Page.new, prose_mirror_node:, tiptap_content_information: tiptap_content_information(record: Folio::Page.new)))

    assert_selector("p")
    assert_text("This is a paragraph")
  end

  test "render aligned paragraph node" do
    prose_mirror_node = {
      "type" => "paragraph",
      "attrs" => { "textAlign" => "center" },
      "content" => [
        {
          "type" => "text",
          "text" => "This is a paragraph"
        }
      ]
    }

    render_inline(Folio::Tiptap::Content::ProseMirrorNodeComponent.new(record: Folio::Page.new, prose_mirror_node:, tiptap_content_information: tiptap_content_information(record: Folio::Page.new)))

    assert_selector("p")
    assert_text("This is a paragraph")

    paragraph = page.find("p")
    assert_equal "text-align: center;", paragraph[:style]
  end

  test "render aligned heading node" do
    prose_mirror_node = {
      "type" => "heading",
      "attrs" => { "textAlign" => "center", "level" => 2 },
      "content" => [
        {
          "type" => "text",
          "text" => "This is a heading"
        }
      ]
    }

    render_inline(Folio::Tiptap::Content::ProseMirrorNodeComponent.new(record: Folio::Page.new, prose_mirror_node:, tiptap_content_information: tiptap_content_information(record: Folio::Page.new)))

    assert_selector("h2")
    assert_text("This is a heading")

    heading = page.find("h2")
    assert_equal "text-align: center;", heading[:style]
  end

  test "render heading node level 1" do
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

    render_inline(Folio::Tiptap::Content::ProseMirrorNodeComponent.new(record: Folio::Page.new, prose_mirror_node:, tiptap_content_information: tiptap_content_information(record: Folio::Page.new)))

    # Now that we have dynamic heading levels
    assert_selector("h1", text: "Main Heading")
  end

  test "render heading node with different level" do
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

    render_inline(Folio::Tiptap::Content::ProseMirrorNodeComponent.new(record: Folio::Page.new, prose_mirror_node:, tiptap_content_information: tiptap_content_information(record: Folio::Page.new)))

    # Now that we have dynamic heading levels
    assert_selector("h3", text: "Sub Heading")
  end

  test "render blockquote node" do
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

    render_inline(Folio::Tiptap::Content::ProseMirrorNodeComponent.new(record: Folio::Page.new, prose_mirror_node:, tiptap_content_information: tiptap_content_information(record: Folio::Page.new)))

    assert_selector("blockquote")
    assert_text("This is a quoted text")
  end

  test "render bulletList node" do
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

    render_inline(Folio::Tiptap::Content::ProseMirrorNodeComponent.new(record: Folio::Page.new, prose_mirror_node:, tiptap_content_information: tiptap_content_information(record: Folio::Page.new)))

    assert_selector("ul")
    assert_selector("li", count: 2)
    assert_text("First item")
    assert_text("Second item")
  end

  test "render orderedList node" do
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

    render_inline(Folio::Tiptap::Content::ProseMirrorNodeComponent.new(record: Folio::Page.new, prose_mirror_node:, tiptap_content_information: tiptap_content_information(record: Folio::Page.new)))

    assert_selector("ol")
    assert_selector("li")
    assert_text("Step one")
  end

  test "render doc node with class" do
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

    render_inline(Folio::Tiptap::Content::ProseMirrorNodeComponent.new(record: Folio::Page.new, prose_mirror_node:, tiptap_content_information: tiptap_content_information(record: Folio::Page.new)))

    assert_selector("div.f-tiptap-content__root")
    assert_text("Document content")
  end

  test "render folio tiptap node" do
    prose_mirror_node = {
      "type" => "folioTiptapNode",
      "attrs" => {
        "type" => "Dummy::Tiptap::Node::Card",
        "data" => { "title" => "Test Card", "content" => "Custom content" }
      }
    }

    render_inline(Folio::Tiptap::Content::ProseMirrorNodeComponent.new(record: Folio::Page.new, prose_mirror_node:, tiptap_content_information: tiptap_content_information(record: Folio::Page.new)))

    # Should render the FolioTiptapNodeComponent with the card
    assert_selector(".d-tiptap-node-card")
    assert_text("Test Card")
  end

  test "render nested structure" do
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

    render_inline(Folio::Tiptap::Content::ProseMirrorNodeComponent.new(record: Folio::Page.new, prose_mirror_node:, tiptap_content_information: tiptap_content_information(record: Folio::Page.new)))

    assert_selector("ul")
    assert_selector("li p")
    assert_text("Item with formatted text")
  end

  test "render unsupported node type" do
    prose_mirror_node = {
      "type" => "unsupported_node",
      "content" => [
        {
          "type" => "text",
          "text" => "This should be hidden, as it causes an error"
        }
      ]
    }

    render_inline(Folio::Tiptap::Content::ProseMirrorNodeComponent.new(record: Folio::Page.new, prose_mirror_node:, tiptap_content_information: tiptap_content_information(record: Folio::Page.new)))

    assert_text("")
  end

  test "render listItem node" do
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

    render_inline(Folio::Tiptap::Content::ProseMirrorNodeComponent.new(record: Folio::Page.new, prose_mirror_node:, tiptap_content_information: tiptap_content_information(record: Folio::Page.new)))

    assert_selector("li")
    assert_text("List item content")
  end

  test "render empty content array" do
    prose_mirror_node = {
      "type" => "paragraph",
      "content" => []
    }

    render_inline(Folio::Tiptap::Content::ProseMirrorNodeComponent.new(record: Folio::Page.new, prose_mirror_node:, tiptap_content_information: tiptap_content_information(record: Folio::Page.new)))

    assert_selector("p")
    assert_selector("p br")
    # Should render empty paragraph with trailing break
  end

  test "render paragraph trailing break when empty" do
    prose_mirror_node = {
      "type" => "paragraph"
    }

    render_inline(Folio::Tiptap::Content::ProseMirrorNodeComponent.new(record: Folio::Page.new, prose_mirror_node:, tiptap_content_information: tiptap_content_information(record: Folio::Page.new)))

    assert_selector("p")
    assert_selector("p br")
  end



  test "render multiple text nodes in paragraph" do
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

    render_inline(Folio::Tiptap::Content::ProseMirrorNodeComponent.new(record: Folio::Page.new, prose_mirror_node:, tiptap_content_information: tiptap_content_information(record: Folio::Page.new)))

    assert_selector("p")
    assert_text("First partsecond part")
  end

  test "render complex structure with multiple levels" do
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

    render_inline(Folio::Tiptap::Content::ProseMirrorNodeComponent.new(record: Folio::Page.new, prose_mirror_node:, tiptap_content_information: tiptap_content_information(record: Folio::Page.new)))

    assert_selector("blockquote")
    assert_selector("blockquote p")
    assert_text("Quoted paragraph with multiple text nodes")
  end

  test "component initialization with all parameters" do
    prose_mirror_node = {
      "type" => "paragraph",
      "content" => [
        {
          "type" => "text",
          "text" => "Test initialization"
        }
      ]
    }

    component = Folio::Tiptap::Content::ProseMirrorNodeComponent.new(record: Folio::Page.new, prose_mirror_node:, tiptap_content_information:)

    # Component should initialize without errors
    render_inline(component)
    assert_selector("p", text: "Test initialization")
  end

  test "render folio tiptap columns" do
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

    render_inline(Folio::Tiptap::Content::ProseMirrorNodeComponent.new(record: Folio::Page.new, prose_mirror_node:, tiptap_content_information: tiptap_content_information(record: Folio::Page.new)))

    assert_selector(".f-tiptap-columns")
    assert_selector(".f-tiptap-columns .f-tiptap-column:first-child", text: "First part")
    assert_selector(".f-tiptap-columns .f-tiptap-column:last-child", text: "Second part")
  end

  test "render folio tiptap float" do
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

    render_inline(Folio::Tiptap::Content::ProseMirrorNodeComponent.new(record: Folio::Page.new, prose_mirror_node:, tiptap_content_information: tiptap_content_information(record: Folio::Page.new)))

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

    render_inline(Folio::Tiptap::Content::ProseMirrorNodeComponent.new(record: Folio::Page.new, prose_mirror_node:, tiptap_content_information: tiptap_content_information(record: Folio::Page.new)))

    assert_selector(".f-tiptap-float")
    assert_selector(".f-tiptap-float[data-f-tiptap-float-size='large']")
    assert_selector(".f-tiptap-float[data-f-tiptap-float-side='right']")
    assert_selector(".f-tiptap-float .f-tiptap-float__aside", text: "Aside part")
    assert_selector(".f-tiptap-float .f-tiptap-float__main", text: "Main part")
  end

  test "render folio tiptap styled paragraph" do
    prose_mirror_node = {
      "type" => "folioTiptapStyledParagraph",
      "content" => [
        {
          "type" => "text",
          "text" => "hello",
        },
      ]
    }

    render_inline(Folio::Tiptap::Content::ProseMirrorNodeComponent.new(record: Folio::Page.new, prose_mirror_node:, tiptap_content_information: tiptap_content_information(record: Folio::Page.new)))

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

    render_inline(Folio::Tiptap::Content::ProseMirrorNodeComponent.new(record: Folio::Page.new, prose_mirror_node:, tiptap_content_information: tiptap_content_information(record: Folio::Page.new)))

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

    render_inline(Folio::Tiptap::Content::ProseMirrorNodeComponent.new(record: Folio::Page.new, prose_mirror_node:, tiptap_content_information: tiptap_content_information(record: Folio::Page.new)))

    assert_no_selector("p.f-tiptap-styled-paragraph[data-f-tiptap-styled-paragraph-variant='large']")
    assert_selector("p.f-tiptap-styled-paragraph[data-f-tiptap-styled-paragraph-variant='small']")
  end

  test "render folio tiptap styled paragraph with custom tag and class" do
    record = Folio::Page.new

    # Mock the tiptap_config to include styled paragraph variants
    def record.tiptap_config
      @config ||= Folio::Tiptap::Config.new(
        styled_paragraph_variants: [
          {
            variant: "custom-heading",
            tag: "h6",
            class_name: "custom-heading",
            title: { cs: "Mezititulek", en: "Custom heading" }
          },
          {
            variant: "small",
            title: { cs: "Malý text", en: "Small text" }
          }
        ]
      )
    end

    # Test custom tag and class
    prose_mirror_node = {
      "type" => "folioTiptapStyledParagraph",
      "content" => [
        {
          "type" => "text",
          "text" => "Custom heading content",
        },
      ],
      "attrs" => {
        "variant" => "custom-heading",
      }
    }

    render_inline(Folio::Tiptap::Content::ProseMirrorNodeComponent.new(record:, prose_mirror_node:, tiptap_content_information: tiptap_content_information(record:)))

    # Should render as h6 with both base class and custom class
    assert_selector("h6.f-tiptap-styled-paragraph.custom-heading[data-f-tiptap-styled-paragraph-variant='custom-heading']")
    assert_text("Custom heading content")
    assert_no_selector("p")
  end

  test "render folio tiptap styled paragraph with variant not in config" do
    record = Folio::Page.new

    # Mock the tiptap_config with only one variant
    def record.tiptap_config
      @config ||= Folio::Tiptap::Config.new(
        styled_paragraph_variants: [
          {
            variant: "small",
            title: { cs: "Malý text", en: "Small text" }
          }
        ]
      )
    end

    # Test variant that's not in config - should fallback to default p tag
    prose_mirror_node = {
      "type" => "folioTiptapStyledParagraph",
      "content" => [
        {
          "type" => "text",
          "text" => "Unknown variant content",
        },
      ],
      "attrs" => {
        "variant" => "unknown-variant",
      }
    }

    render_inline(Folio::Tiptap::Content::ProseMirrorNodeComponent.new(record:, prose_mirror_node:, tiptap_content_information: tiptap_content_information(record:)))

    # Should fallback to default p tag with base class only
    assert_selector("p.f-tiptap-styled-paragraph[data-f-tiptap-styled-paragraph-variant='unknown-variant']")
    assert_text("Unknown variant content")
  end

  test "render folio tiptap styled paragraph with empty config" do
    record = Folio::Page.new

    # Mock the tiptap_config with empty styled paragraph variants
    def record.tiptap_config
      @config ||= Folio::Tiptap::Config.new(styled_paragraph_variants: [])
    end

    prose_mirror_node = {
      "type" => "folioTiptapStyledParagraph",
      "content" => [
        {
          "type" => "text",
          "text" => "Default content",
        },
      ],
      "attrs" => {
        "variant" => "some-variant",
      }
    }

    render_inline(Folio::Tiptap::Content::ProseMirrorNodeComponent.new(record:, prose_mirror_node:, tiptap_content_information: tiptap_content_information(record:)))

    # Should fallback to default p tag
    assert_selector("p.f-tiptap-styled-paragraph[data-f-tiptap-styled-paragraph-variant='some-variant']")
    assert_text("Default content")
  end

  test "render table node" do
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

    render_inline(Folio::Tiptap::Content::ProseMirrorNodeComponent.new(record: Folio::Page.new, prose_mirror_node:, tiptap_content_information: tiptap_content_information(record: Folio::Page.new)))

    assert_selector(".f-tiptap-table-wrapper")
    assert_selector(".f-tiptap-table-wrapper table")
    assert_selector("th", count: 2)
    assert_selector("td", count: 2)
    assert_text("Header 1")
    assert_text("Header 2")
    assert_text("Cell 1")
    assert_text("Cell 2")
  end

  test "render simple table with single cell" do
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

    render_inline(Folio::Tiptap::Content::ProseMirrorNodeComponent.new(record: Folio::Page.new, prose_mirror_node:, tiptap_content_information: tiptap_content_information(record: Folio::Page.new)))

    assert_selector(".f-tiptap-table-wrapper")
    assert_selector(".f-tiptap-table-wrapper table")
    assert_selector("td", count: 1)
    assert_text("Single cell")
  end

  test "render table with empty cells" do
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

    render_inline(Folio::Tiptap::Content::ProseMirrorNodeComponent.new(record: Folio::Page.new, prose_mirror_node:, tiptap_content_information: tiptap_content_information(record: Folio::Page.new)))

    assert_selector(".f-tiptap-table-wrapper")
    assert_selector(".f-tiptap-table-wrapper table")
    assert_selector("td", count: 2)
    assert_text("Not empty")
  end

  test "render folio tiptap styled wrap" do
    prose_mirror_node = {
      "type" => "folioTiptapStyledWrap",
      "attrs" => {
        "variant" => "gray-box"
      },
      "content" => [
        {
          "type" => "paragraph",
          "content" => [
            {
              "type" => "text",
              "text" => "text"
            }
          ]
        }
      ]
    }

    render_inline(Folio::Tiptap::Content::ProseMirrorNodeComponent.new(record: Folio::Page.new, prose_mirror_node:, tiptap_content_information: tiptap_content_information(record: Folio::Page.new)))

    assert_selector("div.f-tiptap-styled-wrap[data-f-tiptap-styled-wrap-variant='gray-box'] p")
  end

  test "component handles invalid folio tiptap node type" do
    prose_mirror_node = {
      "type" => "folioTiptapNode",
      "attrs" => {
        "type" => "unknown",
        "data" => {
          "title" => "UI Component Test",
          "text" => "Testing the UI card component rendering"
        }
      }
    }

    render_inline(Folio::Tiptap::Content::ProseMirrorNodeComponent.new(record: Folio::Page.new, prose_mirror_node:, tiptap_content_information: tiptap_content_information(record: Folio::Page.new)))
    assert_text("")
  end

  test "component handles missing folio tiptap node type" do
    prose_mirror_node = {
      "type" => "folioTiptapNode",
      "attrs" => {
        "data" => {
          "title" => "Missing Type Test",
          "text" => "Testing missing node type"
        }
      }
    }

    render_inline(Folio::Tiptap::Content::ProseMirrorNodeComponent.new(record: Folio::Page.new, prose_mirror_node:, tiptap_content_information: tiptap_content_information(record: Folio::Page.new)))
    assert_text("")
  end

  test "component handles blank folio tiptap node type" do
    prose_mirror_node = {
      "type" => "folioTiptapNode",
      "attrs" => {
        "type" => "",
        "data" => {
          "title" => "Blank Type Test",
          "text" => "Testing blank node type"
        }
      }
    }

    render_inline(Folio::Tiptap::Content::ProseMirrorNodeComponent.new(record: Folio::Page.new, prose_mirror_node:, tiptap_content_information: tiptap_content_information(record: Folio::Page.new)))
    assert_text("")
  end

  test "component handles nil folio tiptap node type" do
    prose_mirror_node = {
      "type" => "folioTiptapNode",
      "attrs" => {
        "type" => nil,
        "data" => {
          "title" => "Nil Type Test",
          "text" => "Testing nil node type"
        }
      }
    }

    render_inline(Folio::Tiptap::Content::ProseMirrorNodeComponent.new(record: Folio::Page.new, prose_mirror_node:, tiptap_content_information: tiptap_content_information(record: Folio::Page.new)))
    assert_text("")
  end

  test "component handles node type excluded by config" do
    prose_mirror_node = {
      "type" => "folioTiptapNode",
      "attrs" => {
        "type" => "Dummy::Tiptap::Node::Card",
        "data" => {
          "title" => "Excluded Type Test",
          "text" => "Testing node type excluded by config"
        }
      }
    }

    record = Folio::Page.new

    # Mock the tiptap_config to exclude all node types
    def record.tiptap_config
      @config ||= Folio::Tiptap::Config.new(node_names: [])
    end

    render_inline(Folio::Tiptap::Content::ProseMirrorNodeComponent.new(record:, prose_mirror_node:, tiptap_content_information: tiptap_content_information(record:)))
    assert_text("")
  end

  test "render with node type blacklist filtering specific nodes" do
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
                  "text" => "This paragraph should be filtered"
                }
              ]
            }
          ]
        },
        {
          "type" => "listItem",
          "content" => [
            {
              "type" => "heading",
              "attrs" => { "level" => 2 },
              "content" => [
                {
                  "type" => "text",
                  "text" => "This heading should render"
                }
              ]
            }
          ]
        }
      ]
    }

    render_inline(Folio::Tiptap::Content::ProseMirrorNodeComponent.new(
      record: Folio::Page.new,
      prose_mirror_node: prose_mirror_node,
      tiptap_content_information:,
      node_type_blacklist: ["paragraph"]
    ))

    # List structure should render
    assert_selector("ul")
    assert_selector("li", count: 2)

    # Paragraph should be filtered out
    assert_no_selector("p")
    assert_no_text("This paragraph should be filtered")

    # Heading should render normally
    assert_selector("h2", text: "This heading should render")
  end

  test "render with node type blacklist and lambda for blacklisted" do
    prose_mirror_node = {
      "type" => "blockquote",
      "content" => [
        {
          "type" => "paragraph",
          "content" => [
            {
              "type" => "text",
              "text" => "Blacklisted paragraph content"
            }
          ]
        },
        {
          "type" => "heading",
          "attrs" => { "level" => 3 },
          "content" => [
            {
              "type" => "text",
              "text" => "Normal heading"
            }
          ]
        }
      ]
    }

    lambda_for_blacklisted = -> (node) do
      "<span class='filtered-node'>FILTERED: #{node['type']}</span>".html_safe
    end

    render_inline(Folio::Tiptap::Content::ProseMirrorNodeComponent.new(
      record: Folio::Page.new,
      prose_mirror_node: prose_mirror_node,
      tiptap_content_information:,
      node_type_blacklist: ["paragraph"],
      lambda_for_blacklisted: lambda_for_blacklisted
    ))

    # Blockquote should render
    assert_selector("blockquote")

    # Paragraph should be replaced with lambda output
    assert_selector(".filtered-node", text: "FILTERED: paragraph")
    assert_no_text("Blacklisted paragraph content")

    # Heading should render normally
    assert_selector("h3", text: "Normal heading")
  end

  test "render with node type blacklist propagated to nested children" do
    prose_mirror_node = {
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
                      "text" => "Nested paragraph to filter"
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
                              "text" => "Deeply nested paragraph to filter"
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
      ]
    }

    render_inline(Folio::Tiptap::Content::ProseMirrorNodeComponent.new(
      record: Folio::Page.new,
      prose_mirror_node: prose_mirror_node,
      tiptap_content_information:,
      node_type_blacklist: ["paragraph"]
    ))

    # List structures should render
    assert_selector("ul")
    assert_selector("li")

    # All paragraphs should be filtered, including deeply nested ones
    assert_no_selector("p")
    assert_no_text("Nested paragraph to filter")
    assert_no_text("Deeply nested paragraph to filter")
  end

  test "render with node type blacklist complex nested structure" do
    prose_mirror_node = {
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
          "type" => "blockquote",
          "content" => [
            {
              "type" => "paragraph",
              "content" => [
                {
                  "type" => "text",
                  "text" => "Quote paragraph to filter"
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
                          "text" => "List paragraph to filter"
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

    lambda_for_blacklisted = -> (node) do
      "[FILTERED]"
    end

    render_inline(Folio::Tiptap::Content::ProseMirrorNodeComponent.new(
      record: Folio::Page.new,
      prose_mirror_node: prose_mirror_node,
      tiptap_content_information:,
      node_type_blacklist: ["paragraph"],
      lambda_for_blacklisted: lambda_for_blacklisted
    ))

    # Heading should render
    assert_selector("h1", text: "Main Title")

    # Blockquote structure should render
    assert_selector("blockquote")

    # All paragraphs should be replaced with lambda output
    assert_text("[FILTERED]")
    assert_no_text("Quote paragraph to filter")
    assert_no_text("List paragraph to filter")

    # List structure should still render
    assert_selector("ul")
    assert_selector("li")
  end

  test "render with node type blacklist no effect when empty" do
    prose_mirror_node = {
      "type" => "paragraph",
      "content" => [
        {
          "type" => "text",
          "text" => "Should render normally"
        }
      ]
    }

    render_inline(Folio::Tiptap::Content::ProseMirrorNodeComponent.new(
      record: Folio::Page.new,
      prose_mirror_node: prose_mirror_node,
      tiptap_content_information:,
      node_type_blacklist: []
    ))

    # Should render normally with empty blacklist
    assert_selector("p", text: "Should render normally")
  end

  test "render with node type blacklist no effect when nil" do
    prose_mirror_node = {
      "type" => "paragraph",
      "content" => [
        {
          "type" => "text",
          "text" => "Should render normally"
        }
      ]
    }

    render_inline(Folio::Tiptap::Content::ProseMirrorNodeComponent.new(
      record: Folio::Page.new,
      prose_mirror_node: prose_mirror_node,
      tiptap_content_information:,
      node_type_blacklist: nil
    ))

    # Should render normally with nil blacklist
    assert_selector("p", text: "Should render normally")
  end
end
