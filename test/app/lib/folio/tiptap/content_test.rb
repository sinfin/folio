# frozen_string_literal: true

require "test_helper"

class Folio::Tiptap::ContentTest < ActiveSupport::TestCase
  test "scrubs HTML from JSON string values" do
    record = Object.new
    content = Folio::Tiptap::Content.new(record: record)

    input_value = {
      "content" => [
        {
          "type" => "paragraph",
          "content" => [
            {
              "type" => "text",
              "text" => unsafe_html_input
            }
          ]
        }
      ]
    }

    result = content.convert_and_sanitize_value(input_value)

    assert result[:ok]
    assert_equal expected_scrubbed_text, result[:value]["content"][0]["content"][0]["text"]
  end

  test "scrubs HTML from JSON keys when keys are safe" do
    record = Object.new
    content = Folio::Tiptap::Content.new(record: record)

    input_value = {
      "safe_key" => "safe value",
      "nested" => {
        "another_safe_key" => "another safe value"
      }
    }

    result = content.convert_and_sanitize_value(input_value)

    assert result[:ok]
    assert_equal "safe value", result[:value]["safe_key"]
    assert_equal "another safe value", result[:value]["nested"]["another_safe_key"]
  end

  test "scrubs HTML from array values" do
    record = Object.new
    content = Folio::Tiptap::Content.new(record: record)

    input_value = {
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
                      "text" => unsafe_html_input
                    }
                  ]
                }
              ]
            }
          ]
        }
      ]
    }

    result = content.convert_and_sanitize_value(input_value)

    assert result[:ok]
    text_content = result[:value]["content"][0]["content"][0]["content"][0]["content"][0]["text"]
    assert_equal expected_scrubbed_text, text_content
  end

  test "preserves non-string values" do
    record = Object.new
    content = Folio::Tiptap::Content.new(record: record)

    input_value = {
      "number" => 42,
      "boolean" => true,
      "null_value" => nil,
      "array_mixed" => [
        123,
        unsafe_html_input,
        true,
        { "nested_html" => unsafe_html_input }
      ]
    }

    result = content.convert_and_sanitize_value(input_value)

    assert result[:ok]
    assert_equal 42, result[:value]["number"]
    assert_equal true, result[:value]["boolean"]
    assert_nil result[:value]["null_value"]

    # Check mixed array
    assert_equal 123, result[:value]["array_mixed"][0]
    assert_equal expected_scrubbed_text, result[:value]["array_mixed"][1]
    assert_equal true, result[:value]["array_mixed"][2]
    assert_equal expected_scrubbed_text, result[:value]["array_mixed"][3]["nested_html"]
  end

  test "handles JSON string input" do
    record = Object.new
    content = Folio::Tiptap::Content.new(record: record)

    json_string = {
      "content" => [
        {
          "type" => "text",
          "text" => unsafe_html_input
        }
      ]
    }.to_json

    result = content.convert_and_sanitize_value(json_string)

    assert result[:ok]
    assert_equal expected_scrubbed_text, result[:value]["content"][0]["text"]
  end

  test "handles nested content JSON structure" do
    record = Object.new
    content = Folio::Tiptap::Content.new(record: record)

    input_value = {
      "tiptap_content" => JSON.generate([
        {
          "type" => "paragraph",
          "content" => [
            {
              "type" => "text",
              "text" => unsafe_html_input
            }
          ]
        }
      ])
    }

    result = content.convert_and_sanitize_value(input_value)

    assert result[:ok]
    content_array = result[:value]["tiptap_content"]
    assert content_array.is_a?(Array)
    assert_equal expected_scrubbed_text, content_array[0]["content"][0]["text"]
  end

  test "returns error for invalid input types" do
    record = Object.new
    content = Folio::Tiptap::Content.new(record: record)

    result = content.convert_and_sanitize_value(123)
    assert_not result[:ok]
  end

  test "returns error for invalid JSON string" do
    record = Object.new
    content = Folio::Tiptap::Content.new(record: record)

    result = content.convert_and_sanitize_value("invalid json {")
    assert_not result[:ok]
  end

  test "handles nil input" do
    record = Object.new
    content = Folio::Tiptap::Content.new(record: record)

    result = content.convert_and_sanitize_value(nil)
    assert result[:ok]
    assert_nil result[:value]
  end

  test "sanitizes javascript href in link marks" do
    record = Object.new
    content = Folio::Tiptap::Content.new(record: record)

    input_value = {
      "content" => [
        {
          "type" => "paragraph",
          "content" => [
            {
              "type" => "text",
              "marks" => [
                {
                  "type" => "link",
                  "attrs" => {
                    "href" => "javascript:alert('xss')",
                    "target" => "_blank"
                  }
                }
              ],
              "text" => "Malicious link"
            }
          ]
        }
      ]
    }

    result = content.convert_and_sanitize_value(input_value)

    assert result[:ok]
    href = result[:value]["content"][0]["content"][0]["marks"][0]["attrs"]["href"]
    assert_nil href
  end

  test "sanitizes data href in link marks" do
    record = Object.new
    content = Folio::Tiptap::Content.new(record: record)

    input_value = {
      "content" => [
        {
          "type" => "paragraph",
          "content" => [
            {
              "type" => "text",
              "marks" => [
                {
                  "type" => "link",
                  "attrs" => {
                    "href" => "data:text/html,<script>alert('xss')</script>",
                    "title" => "Data URL attack"
                  }
                }
              ],
              "text" => "Click me"
            }
          ]
        }
      ]
    }

    result = content.convert_and_sanitize_value(input_value)

    assert result[:ok]
    attrs = result[:value]["content"][0]["content"][0]["marks"][0]["attrs"]
    assert_nil attrs["href"]
    assert_equal "Data URL attack", attrs["title"]
  end

  test "preserves safe href in link marks" do
    record = Object.new
    content = Folio::Tiptap::Content.new(record: record)

    input_value = {
      "content" => [
        {
          "type" => "paragraph",
          "content" => [
            {
              "type" => "text",
              "marks" => [
                {
                  "type" => "link",
                  "attrs" => {
                    "href" => "https://example.com/path?param=value",
                    "target" => "_blank",
                    "rel" => "noopener noreferrer",
                    "title" => "Safe link"
                  }
                }
              ],
              "text" => "Safe link"
            }
          ]
        }
      ]
    }

    result = content.convert_and_sanitize_value(input_value)

    assert result[:ok]
    attrs = result[:value]["content"][0]["content"][0]["marks"][0]["attrs"]
    assert_equal "https://example.com/path?param=value", attrs["href"]
    assert_equal "_blank", attrs["target"]
    assert_equal "noopener noreferrer", attrs["rel"]
    assert_equal "Safe link", attrs["title"]
  end

  test "preserves mailto and tel links" do
    record = Object.new
    content = Folio::Tiptap::Content.new(record: record)

    input_value = {
      "content" => [
        {
          "type" => "paragraph",
          "content" => [
            {
              "type" => "text",
              "marks" => [
                {
                  "type" => "link",
                  "attrs" => {
                    "href" => "mailto:test@example.com?subject=Hello"
                  }
                }
              ],
              "text" => "Email"
            },
            {
              "type" => "text",
              "marks" => [
                {
                  "type" => "link",
                  "attrs" => {
                    "href" => "tel:+1-555-123-4567"
                  }
                }
              ],
              "text" => "Phone"
            }
          ]
        }
      ]
    }

    result = content.convert_and_sanitize_value(input_value)

    assert result[:ok]
    content_items = result[:value]["content"][0]["content"]
    assert_equal "mailto:test@example.com?subject=Hello", content_items[0]["marks"][0]["attrs"]["href"]
    assert_equal "tel:+1-555-123-4567", content_items[1]["marks"][0]["attrs"]["href"]
  end

  test "sanitizes vbscript and file protocols in link marks" do
    record = Object.new
    content = Folio::Tiptap::Content.new(record: record)

    input_value = {
      "content" => [
        {
          "type" => "paragraph",
          "content" => [
            {
              "type" => "text",
              "marks" => [
                {
                  "type" => "link",
                  "attrs" => {
                    "href" => "vbscript:msgbox('xss')"
                  }
                }
              ],
              "text" => "VBScript"
            },
            {
              "type" => "text",
              "marks" => [
                {
                  "type" => "link",
                  "attrs" => {
                    "href" => "file:///etc/passwd"
                  }
                }
              ],
              "text" => "File"
            }
          ]
        }
      ]
    }

    result = content.convert_and_sanitize_value(input_value)

    assert result[:ok]
    content_items = result[:value]["content"][0]["content"]
    assert_nil content_items[0]["marks"][0]["attrs"]["href"]
    assert_nil content_items[1]["marks"][0]["attrs"]["href"]
  end

  test "sanitizes link marks with multiple marks" do
    record = Object.new
    content = Folio::Tiptap::Content.new(record: record)

    input_value = {
      "content" => [
        {
          "type" => "paragraph",
          "content" => [
            {
              "type" => "text",
              "marks" => [
                {
                  "type" => "link",
                  "attrs" => {
                    "href" => "javascript:alert('bold link')"
                  }
                },
                {
                  "type" => "bold"
                },
                {
                  "type" => "italic"
                }
              ],
              "text" => "Bold italic malicious link"
            }
          ]
        }
      ]
    }

    result = content.convert_and_sanitize_value(input_value)

    assert result[:ok]
    marks = result[:value]["content"][0]["content"][0]["marks"]
    link_mark = marks.find { |mark| mark["type"] == "link" }
    assert_nil link_mark["attrs"]["href"]

    # Other marks should be preserved
    assert marks.any? { |mark| mark["type"] == "bold" }
    assert marks.any? { |mark| mark["type"] == "italic" }
  end

  private
    def unsafe_html_input
      "<script>alert('xss')</script><p>text with <a href=\"javascript:evil()\">link</a></p>"
    end

    def expected_scrubbed_text
      "alert('xss')text with link"
    end
end
