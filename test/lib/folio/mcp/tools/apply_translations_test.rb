# frozen_string_literal: true

require "test_helper"

class Folio::Mcp::Tools::ApplyTranslationsTest < ActiveSupport::TestCase
  setup do
    @server_context = {
      user: nil,
      site: nil,
      audit_logger: nil
    }
  end

  test "applies translations to simple text" do
    original = {
      "type" => "doc",
      "content" => [
        {
          "type" => "paragraph",
          "content" => [
            { "type" => "text", "text" => "Hello" }
          ]
        }
      ]
    }

    translations = [
      { "path" => "content.0.content.0.text", "value" => "Ahoj" }
    ]

    result = Folio::Mcp::Tools::ApplyTranslations.call(
      original_tiptap: original,
      translations: translations,
      server_context: @server_context
    )

    assert_not result[:isError]

    content = JSON.parse(result[:content].first[:text])
    assert_equal "Ahoj", content["tiptap"]["content"][0]["content"][0]["text"]
    assert_equal 1, content["translations_applied"]
  end

  test "applies translations to attrs" do
    original = {
      "type" => "doc",
      "content" => [
        {
          "type" => "card",
          "attrs" => {
            "title" => "Original Title"
          }
        }
      ]
    }

    translations = [
      { "path" => "content.0.attrs.title", "value" => "Translated Title" }
    ]

    result = Folio::Mcp::Tools::ApplyTranslations.call(
      original_tiptap: original,
      translations: translations,
      server_context: @server_context
    )

    assert_not result[:isError]

    content = JSON.parse(result[:content].first[:text])
    assert_equal "Translated Title", content["tiptap"]["content"][0]["attrs"]["title"]
  end

  test "validates structure hash" do
    original = { "type" => "doc", "content" => [] }
    correct_hash = Digest::SHA256.hexdigest(original.to_json)[0..15]

    result = Folio::Mcp::Tools::ApplyTranslations.call(
      original_tiptap: original,
      translations: [],
      structure_hash: "wrong_hash",
      server_context: @server_context
    )

    assert result[:isError]
    assert_includes result[:content].first[:text], "Structure has changed"
  end

  test "returns error for missing original tiptap" do
    result = Folio::Mcp::Tools::ApplyTranslations.call(
      original_tiptap: nil,
      translations: [],
      server_context: @server_context
    )

    assert result[:isError]
  end

  test "does not modify original structure" do
    original = {
      "type" => "doc",
      "content" => [
        {
          "type" => "paragraph",
          "content" => [
            { "type" => "text", "text" => "Hello" }
          ]
        }
      ]
    }

    original_copy = JSON.parse(original.to_json)

    translations = [
      { "path" => "content.0.content.0.text", "value" => "Ahoj" }
    ]

    Folio::Mcp::Tools::ApplyTranslations.call(
      original_tiptap: original,
      translations: translations,
      server_context: @server_context
    )

    # Original should be unchanged
    assert_equal original_copy, original
  end
end
