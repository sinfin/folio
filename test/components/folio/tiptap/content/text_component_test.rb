# frozen_string_literal: true

require "test_helper"

class Folio::Tiptap::Content::TextComponentTest < Folio::ComponentTest
  def test_render_simple_text
    prosemirror_node = {
      "type" => "text",
      "text" => "Hello world"
    }

    model = build_mock_record
    render_inline(Folio::Tiptap::Content::TextComponent.new(record: model, prosemirror_node: prosemirror_node))

    assert_text("Hello world")
  end

  def test_render_text_with_bold_mark
    prosemirror_node = {
      "type" => "text",
      "marks" => [{ "type" => "bold" }],
      "text" => "Bold text"
    }

    model = build_mock_record
    render_inline(Folio::Tiptap::Content::TextComponent.new(record: model, prosemirror_node: prosemirror_node))

    # TextComponent now renders text with marks applied
    assert_selector("strong", text: "Bold text")
  end

  def test_render_text_with_italic_mark
    prosemirror_node = {
      "type" => "text",
      "marks" => [{ "type" => "italic" }],
      "text" => "Italic text"
    }

    model = build_mock_record
    render_inline(Folio::Tiptap::Content::TextComponent.new(record: model, prosemirror_node: prosemirror_node))

    # TextComponent now renders text with marks applied
    assert_selector("em", text: "Italic text")
  end

  def test_render_text_with_underline_mark
    prosemirror_node = {
      "type" => "text",
      "marks" => [{ "type" => "underline" }],
      "text" => "Underlined text"
    }

    model = build_mock_record
    render_inline(Folio::Tiptap::Content::TextComponent.new(record: model, prosemirror_node: prosemirror_node))

    # TextComponent now renders text with marks applied
    assert_selector("u", text: "Underlined text")
  end

  def test_render_text_with_strike_mark
    prosemirror_node = {
      "type" => "text",
      "marks" => [{ "type" => "strike" }],
      "text" => "Strikethrough text"
    }

    model = build_mock_record
    render_inline(Folio::Tiptap::Content::TextComponent.new(record: model, prosemirror_node: prosemirror_node))

    # TextComponent now renders text with marks applied
    assert_selector("strike", text: "Strikethrough text")
  end

  def test_render_text_with_code_mark
    prosemirror_node = {
      "type" => "text",
      "marks" => [{ "type" => "code" }],
      "text" => "console.log('hello')"
    }

    model = build_mock_record
    render_inline(Folio::Tiptap::Content::TextComponent.new(record: model, prosemirror_node: prosemirror_node))

    # TextComponent now renders text with marks applied
    assert_selector("code", text: "console.log('hello')")
  end

  def test_render_text_with_subscript_mark
    prosemirror_node = {
      "type" => "text",
      "marks" => [{ "type" => "subscript" }],
      "text" => "2"
    }

    model = build_mock_record
    render_inline(Folio::Tiptap::Content::TextComponent.new(record: model, prosemirror_node: prosemirror_node))

    # TextComponent now renders text with marks applied
    assert_selector("sub", text: "2")
  end

  def test_render_text_with_superscript_mark
    prosemirror_node = {
      "type" => "text",
      "marks" => [{ "type" => "superscript" }],
      "text" => "2"
    }

    model = build_mock_record
    render_inline(Folio::Tiptap::Content::TextComponent.new(record: model, prosemirror_node: prosemirror_node))

    # TextComponent now renders text with marks applied
    assert_selector("sup", text: "2")
  end

  def test_render_text_with_link_mark
    prosemirror_node = {
      "type" => "text",
      "marks" => [
        {
          "type" => "link",
          "attrs" => {
            "href" => "https://example.com",
            "target" => "_blank",
            "title" => "Example Link"
          }
        }
      ],
      "text" => "Visit our website"
    }

    model = build_mock_record
    render_inline(Folio::Tiptap::Content::TextComponent.new(record: model, prosemirror_node: prosemirror_node))

    # TextComponent now renders text with marks applied
    assert_selector("a[href='https://example.com'][target='_blank']", text: "Visit our website")
  end

  def test_render_text_with_multiple_marks
    prosemirror_node = {
      "type" => "text",
      "marks" => [
        { "type" => "bold" },
        { "type" => "italic" },
        { "type" => "underline" }
      ],
      "text" => "Bold, italic, and underlined"
    }

    model = build_mock_record
    render_inline(Folio::Tiptap::Content::TextComponent.new(record: model, prosemirror_node: prosemirror_node))

    # TextComponent now renders text with nested marks applied
    # The exact nesting may vary based on implementation
    assert_text("Bold, italic, and underlined")
  end

  def test_render_text_with_link_and_formatting_marks
    prosemirror_node = {
      "type" => "text",
      "marks" => [
        {
          "type" => "link",
          "attrs" => {
            "href" => "https://example.com"
          }
        },
        { "type" => "bold" }
      ],
      "text" => "Bold link"
    }

    model = build_mock_record
    render_inline(Folio::Tiptap::Content::TextComponent.new(record: model, prosemirror_node: prosemirror_node))

    # TextComponent now renders text with marks applied
    # The exact nesting may vary (link with bold or bold with link)
    assert_text("Bold link")
  end

  def test_render_empty_text
    prosemirror_node = {
      "type" => "text",
      "text" => ""
    }

    model = build_mock_record
    component = Folio::Tiptap::Content::TextComponent.new(record: model, prosemirror_node: prosemirror_node)
    render_inline(component)

    # Should render empty text content (no visible text)
    assert_no_text(/\S/)
  end

  def test_render_text_with_special_characters
    prosemirror_node = {
      "type" => "text",
      "text" => "Special chars: <>&\"'"
    }

    model = build_mock_record
    render_inline(Folio::Tiptap::Content::TextComponent.new(record: model, prosemirror_node: prosemirror_node))

    assert_text("Special chars: <>&\"'")
  end

  def test_render_text_with_unicode_characters
    prosemirror_node = {
      "type" => "text",
      "text" => "Unicode: 🚀 ñáéíóú 中文"
    }

    model = build_mock_record
    render_inline(Folio::Tiptap::Content::TextComponent.new(record: model, prosemirror_node: prosemirror_node))

    assert_text("Unicode: 🚀 ñáéíóú 中文")
  end

  def test_render_text_with_newlines
    prosemirror_node = {
      "type" => "text",
      "text" => "Line one\nLine two\nLine three"
    }

    model = build_mock_record
    render_inline(Folio::Tiptap::Content::TextComponent.new(record: model, prosemirror_node: prosemirror_node))

    assert_text("Line one\nLine two\nLine three")
  end

  def test_render_text_with_whitespace
    prosemirror_node = {
      "type" => "text",
      "text" => "  Multiple   spaces   and   tabs  "
    }

    model = build_mock_record
    render_inline(Folio::Tiptap::Content::TextComponent.new(record: model, prosemirror_node: prosemirror_node))

    # HTML normalizes whitespace, so leading/trailing spaces may be trimmed
    assert_text("Multiple   spaces   and   tabs")
  end

  def test_render_text_with_complex_link_attributes
    prosemirror_node = {
      "type" => "text",
      "marks" => [
        {
          "type" => "link",
          "attrs" => {
            "href" => "mailto:test@example.com",
            "target" => "_self",
            "title" => "Send email",
            "rel" => "noopener noreferrer"
          }
        }
      ],
      "text" => "Email us"
    }

    model = build_mock_record
    render_inline(Folio::Tiptap::Content::TextComponent.new(record: model, prosemirror_node: prosemirror_node))

    # TextComponent now renders text with marks applied
    assert_selector("a[href='mailto:test@example.com']", text: "Email us")
  end



  def test_render_text_node_without_marks
    prosemirror_node = {
      "type" => "text",
      "text" => "Plain text without formatting"
    }

    model = build_mock_record
    render_inline(Folio::Tiptap::Content::TextComponent.new(record: model, prosemirror_node: prosemirror_node))

    assert_text("Plain text without formatting")
  end

  def test_render_text_with_empty_marks_array
    prosemirror_node = {
      "type" => "text",
      "marks" => [],
      "text" => "Text with empty marks array"
    }

    model = build_mock_record
    render_inline(Folio::Tiptap::Content::TextComponent.new(record: model, prosemirror_node: prosemirror_node))

    assert_text("Text with empty marks array")
  end

  def test_render_long_text_content
    long_text = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. " * 10
    prosemirror_node = {
      "type" => "text",
      "text" => long_text
    }

    model = build_mock_record
    render_inline(Folio::Tiptap::Content::TextComponent.new(record: model, prosemirror_node: prosemirror_node))

    assert_text(long_text)
  end

  def test_component_initialization_parameters
    prosemirror_node = {
      "type" => "text",
      "text" => "Test initialization"
    }

    model = build_mock_record
    component = Folio::Tiptap::Content::TextComponent.new(
      record: model,
      prosemirror_node: prosemirror_node
    )

    # Component should initialize without errors
    render_inline(component)
    assert_text("Test initialization")
  end

  def test_handles_missing_text_key
    prosemirror_node = {
      "type" => "text"
      # Missing "text" key
    }

    model = build_mock_record

    # Should handle gracefully (might render nil/empty)
    render_inline(Folio::Tiptap::Content::TextComponent.new(record: model, prosemirror_node: prosemirror_node))
    # No assertions needed - just ensure it doesn't crash
  end

  def test_xss_protection_plain_text
    prosemirror_node = {
      "type" => "text",
      "text" => "<script>alert('XSS')</script>Dangerous content"
    }

    model = build_mock_record
    render_inline(Folio::Tiptap::Content::TextComponent.new(record: model, prosemirror_node: prosemirror_node))

    # Script tags should be escaped, not executed
    assert_text("<script>alert('XSS')</script>Dangerous content")
    # Should not contain actual script tags in HTML
    assert_no_selector("script")
  end

  def test_xss_protection_with_marks
    prosemirror_node = {
      "type" => "text",
      "marks" => [{ "type" => "bold" }],
      "text" => "<script>alert('XSS')</script>Bold dangerous content"
    }

    model = build_mock_record
    render_inline(Folio::Tiptap::Content::TextComponent.new(record: model, prosemirror_node: prosemirror_node))

    # Script tags should be escaped within the bold tag
    assert_selector("strong", text: "<script>alert('XSS')</script>Bold dangerous content")
    # Should not contain actual script tags in HTML
    assert_no_selector("script")
  end

  def test_xss_protection_in_link_text
    prosemirror_node = {
      "type" => "text",
      "marks" => [
        {
          "type" => "link",
          "attrs" => {
            "href" => "https://example.com"
          }
        }
      ],
      "text" => "<script>alert('XSS')</script>Malicious link text"
    }

    model = build_mock_record
    render_inline(Folio::Tiptap::Content::TextComponent.new(record: model, prosemirror_node: prosemirror_node))

    # Script tags should be escaped within the link
    assert_selector("a[href='https://example.com']", text: "<script>alert('XSS')</script>Malicious link text")
    # Should not contain actual script tags in HTML
    assert_no_selector("script")
  end

  private
    def build_mock_record
      Object.new
    end
end
