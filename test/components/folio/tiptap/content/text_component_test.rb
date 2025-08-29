# frozen_string_literal: true

require "test_helper"

class Folio::Tiptap::Content::TextComponentTest < Folio::ComponentTest
  def test_render_simple_text
    prose_mirror_node = {
      "type" => "text",
      "text" => "Hello world"
    }

    render_inline(Folio::Tiptap::Content::TextComponent.new(record: build_mock_record, prose_mirror_node:))

    assert_text("Hello world")
  end

  def test_render_text_with_bold_mark
    prose_mirror_node = {
      "type" => "text",
      "marks" => [{ "type" => "bold" }],
      "text" => "Bold text"
    }

    render_inline(Folio::Tiptap::Content::TextComponent.new(record: build_mock_record, prose_mirror_node:))

    # TextComponent now renders text with marks applied
    assert_selector("strong", text: "Bold text")
  end

  def test_render_text_with_italic_mark
    prose_mirror_node = {
      "type" => "text",
      "marks" => [{ "type" => "italic" }],
      "text" => "Italic text"
    }

    render_inline(Folio::Tiptap::Content::TextComponent.new(record: build_mock_record, prose_mirror_node:))

    # TextComponent now renders text with marks applied
    assert_selector("em", text: "Italic text")
  end

  def test_render_text_with_underline_mark
    prose_mirror_node = {
      "type" => "text",
      "marks" => [{ "type" => "underline" }],
      "text" => "Underlined text"
    }

    render_inline(Folio::Tiptap::Content::TextComponent.new(record: build_mock_record, prose_mirror_node:))

    # TextComponent now renders text with marks applied
    assert_selector("u", text: "Underlined text")
  end

  def test_render_text_with_strike_mark
    prose_mirror_node = {
      "type" => "text",
      "marks" => [{ "type" => "strike" }],
      "text" => "Strikethrough text"
    }

    render_inline(Folio::Tiptap::Content::TextComponent.new(record: build_mock_record, prose_mirror_node:))

    # TextComponent now renders text with marks applied
    assert_selector("strike", text: "Strikethrough text")
  end

  def test_render_text_with_code_mark
    prose_mirror_node = {
      "type" => "text",
      "marks" => [{ "type" => "code" }],
      "text" => "console.log('hello')"
    }

    render_inline(Folio::Tiptap::Content::TextComponent.new(record: build_mock_record, prose_mirror_node:))

    # TextComponent now renders text with marks applied
    assert_selector("code", text: "console.log('hello')")
  end

  def test_render_text_with_subscript_mark
    prose_mirror_node = {
      "type" => "text",
      "marks" => [{ "type" => "subscript" }],
      "text" => "2"
    }

    render_inline(Folio::Tiptap::Content::TextComponent.new(record: build_mock_record, prose_mirror_node:))

    # TextComponent now renders text with marks applied
    assert_selector("sub", text: "2")
  end

  def test_render_text_with_superscript_mark
    prose_mirror_node = {
      "type" => "text",
      "marks" => [{ "type" => "superscript" }],
      "text" => "2"
    }

    render_inline(Folio::Tiptap::Content::TextComponent.new(record: build_mock_record, prose_mirror_node:))

    # TextComponent now renders text with marks applied
    assert_selector("sup", text: "2")
  end

  def test_render_text_with_link_mark
    prose_mirror_node = {
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

    render_inline(Folio::Tiptap::Content::TextComponent.new(record: build_mock_record, prose_mirror_node:))

    # TextComponent now renders text with marks applied
    assert_selector("a[href='https://example.com'][target='_blank']", text: "Visit our website")
  end

  def test_render_text_with_multiple_marks
    prose_mirror_node = {
      "type" => "text",
      "marks" => [
        { "type" => "bold" },
        { "type" => "italic" },
        { "type" => "underline" }
      ],
      "text" => "Bold, italic, and underlined"
    }

    render_inline(Folio::Tiptap::Content::TextComponent.new(record: build_mock_record, prose_mirror_node:))

    # TextComponent now renders text with nested marks applied
    # The exact nesting may vary based on implementation
    assert_text("Bold, italic, and underlined")
  end

  def test_render_text_with_link_and_formatting_marks
    prose_mirror_node = {
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

    render_inline(Folio::Tiptap::Content::TextComponent.new(record: build_mock_record, prose_mirror_node:))

    # TextComponent now renders text with marks applied
    # The exact nesting may vary (link with bold or bold with link)
    assert_text("Bold link")
  end

  def test_render_empty_text
    prose_mirror_node = {
      "type" => "text",
      "text" => ""
    }

    component = Folio::Tiptap::Content::TextComponent.new(record: build_mock_record, prose_mirror_node:)
    render_inline(component)

    # Should render empty text content (no visible text)
    assert_no_text(/\S/)
  end

  def test_render_text_with_special_characters
    prose_mirror_node = {
      "type" => "text",
      "text" => "Special chars: <>&\"'"
    }

    render_inline(Folio::Tiptap::Content::TextComponent.new(record: build_mock_record, prose_mirror_node:))

    assert_text("Special chars: <>&\"'")
  end

  def test_render_text_with_unicode_characters
    prose_mirror_node = {
      "type" => "text",
      "text" => "Unicode: 🚀 ñáéíóú 中文"
    }

    render_inline(Folio::Tiptap::Content::TextComponent.new(record: build_mock_record, prose_mirror_node:))

    assert_text("Unicode: 🚀 ñáéíóú 中文")
  end

  def test_render_text_with_newlines
    prose_mirror_node = {
      "type" => "text",
      "text" => "Line one\nLine two\nLine three"
    }

    render_inline(Folio::Tiptap::Content::TextComponent.new(record: build_mock_record, prose_mirror_node:))

    assert_text("Line one\nLine two\nLine three")
  end

  def test_render_text_with_whitespace
    prose_mirror_node = {
      "type" => "text",
      "text" => "  Multiple   spaces   and   tabs  "
    }

    render_inline(Folio::Tiptap::Content::TextComponent.new(record: build_mock_record, prose_mirror_node:))

    # HTML normalizes whitespace, so leading/trailing spaces may be trimmed
    assert_text("Multiple   spaces   and   tabs")
  end

  def test_render_text_with_complex_link_attributes
    prose_mirror_node = {
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

    render_inline(Folio::Tiptap::Content::TextComponent.new(record: build_mock_record, prose_mirror_node:))

    # TextComponent now renders text with marks applied
    assert_selector("a[href='mailto:test@example.com']", text: "Email us")
  end



  def test_render_text_node_without_marks
    prose_mirror_node = {
      "type" => "text",
      "text" => "Plain text without formatting"
    }

    render_inline(Folio::Tiptap::Content::TextComponent.new(record: build_mock_record, prose_mirror_node:))

    assert_text("Plain text without formatting")
  end

  def test_render_text_with_empty_marks_array
    prose_mirror_node = {
      "type" => "text",
      "marks" => [],
      "text" => "Text with empty marks array"
    }

    render_inline(Folio::Tiptap::Content::TextComponent.new(record: build_mock_record, prose_mirror_node:))

    assert_text("Text with empty marks array")
  end

  def test_render_long_text_content
    long_text = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. " * 10
    prose_mirror_node = {
      "type" => "text",
      "text" => long_text
    }

    render_inline(Folio::Tiptap::Content::TextComponent.new(record: build_mock_record, prose_mirror_node:))

    assert_text(long_text)
  end

  def test_component_initialization_parameters
    prose_mirror_node = {
      "type" => "text",
      "text" => "Test initialization"
    }

    component = Folio::Tiptap::Content::TextComponent.new(
      record: build_mock_record,
      prose_mirror_node:
    )

    # Component should initialize without errors
    render_inline(component)
    assert_text("Test initialization")
  end

  def test_handles_missing_text_key
    prose_mirror_node = {
      "type" => "text"
      # Missing "text" key
    }


    # Should handle gracefully (might render nil/empty)
    assert render_inline(Folio::Tiptap::Content::TextComponent.new(record: build_mock_record, prose_mirror_node:))
  end

  def test_xss_protection_plain_text
    prose_mirror_node = {
      "type" => "text",
      "text" => "<script>alert('XSS')</script>Dangerous content"
    }

    render_inline(Folio::Tiptap::Content::TextComponent.new(record: build_mock_record, prose_mirror_node:))

    # Script tags should be escaped, not executed
    assert_text("<script>alert('XSS')</script>Dangerous content")
    # Should not contain actual script tags in HTML
    assert_no_selector("script")
  end

  def test_xss_protection_with_marks
    prose_mirror_node = {
      "type" => "text",
      "marks" => [{ "type" => "bold" }],
      "text" => "<script>alert('XSS')</script>Bold dangerous content"
    }

    render_inline(Folio::Tiptap::Content::TextComponent.new(record: build_mock_record, prose_mirror_node:))

    # Script tags should be escaped within the bold tag
    assert_selector("strong", text: "<script>alert('XSS')</script>Bold dangerous content")
    # Should not contain actual script tags in HTML
    assert_no_selector("script")
  end

  def test_xss_protection_in_link_text
    prose_mirror_node = {
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

    render_inline(Folio::Tiptap::Content::TextComponent.new(record: build_mock_record, prose_mirror_node:))

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
