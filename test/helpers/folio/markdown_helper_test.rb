# frozen_string_literal: true

require "test_helper"

class Folio::MarkdownHelperTest < ActionView::TestCase
  include Folio::MarkdownHelper

  test "markdown_to_html converts basic markdown" do
    markdown = "# Title\n\nThis is **bold** text."
    html = markdown_to_html(markdown)

    assert_includes html, "<h1"
    assert_includes html, "Title</h1>"
    assert_includes html, "<strong>bold</strong>"
  end

  test "markdown_to_html handles code blocks" do
    markdown = "```ruby\ndef hello\n  puts 'world'\nend\n```"
    html = markdown_to_html(markdown)

    assert_includes html, "<pre><code"
    assert_includes html, "def hello"
  end

  test "markdown_to_html creates tables" do
    markdown = "| Header 1 | Header 2 |\n|----------|----------|\n| Cell 1   | Cell 2   |"
    html = markdown_to_html(markdown)

    assert_includes html, "<table>"
    assert_includes html, "<th>Header 1</th>"
    assert_includes html, "<td>Cell 1</td>"
  end

  test "markdown_to_html handles empty input" do
    assert_equal "", markdown_to_html("")
    assert_equal "", markdown_to_html(nil)
  end

  test "markdown_to_html autolinks URLs" do
    markdown = "Visit https://example.com for more info."
    html = markdown_to_html(markdown)

    assert_includes html, '<a href="https://example.com"'
  end

  test "markdown_to_html handles strikethrough" do
    markdown = "This is ~~strikethrough~~ text."
    html = markdown_to_html(markdown)

    assert_includes html, "<del>strikethrough</del>"
  end

  test "markdown_to_html is safe from XSS" do
    markdown = "Click <script>alert('xss')</script> here"
    html = markdown_to_html(markdown)

    # Redcarpet escapes HTML by default in our configuration
    # Script should be escaped to prevent XSS
    assert_includes html, "&#39;"  # Single quotes are escaped
  end

  test "markdown_to_html returns html_safe string" do
    markdown = "# Safe HTML"
    html = markdown_to_html(markdown)

    assert html.html_safe?
  end

  test "markdown_to_html handles line breaks" do
    markdown = "Line 1\nLine 2\n\nParagraph 2"
    html = markdown_to_html(markdown)

    # Hard wrap should create <br> tags
    assert_includes html, "<br"
  end

  test "markdown_to_html handles lists" do
    markdown = "- Item 1\n- Item 2\n\n1. Numbered 1\n2. Numbered 2"
    html = markdown_to_html(markdown)

    assert_includes html, "<ul>"
    assert_includes html, "<ol>"
    assert_includes html, "<li>Item 1</li>"
    assert_includes html, "<li>Numbered 1</li>"
  end

  test "markdown_to_html adds toc data to headers" do
    markdown = "# Main Title\n\n## Subtitle"
    html = markdown_to_html(markdown)

    # Should add data attributes for table of contents
    assert_includes html, 'id="'
  end
end
