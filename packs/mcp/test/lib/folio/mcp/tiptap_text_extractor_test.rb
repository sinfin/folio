# frozen_string_literal: true

require "test_helper"

class Folio::Mcp::TiptapTextExtractorTest < ActiveSupport::TestCase
  test "extracts text from simple paragraph" do
    tiptap = {
      "type" => "doc",
      "content" => [
        {
          "type" => "paragraph",
          "content" => [
            { "type" => "text", "text" => "Hello world" }
          ]
        }
      ]
    }

    extractor = Folio::Mcp::TiptapTextExtractor.new(tiptap)
    texts = extractor.extract

    assert_equal 1, texts.size
    assert_equal "Hello world", texts.first[:value]
    assert_equal "content.0.content.0.text", texts.first[:path]
    assert_equal "text", texts.first[:node_type]
  end

  test "extracts text from attrs" do
    tiptap = {
      "type" => "doc",
      "content" => [
        {
          "type" => "customCard",
          "attrs" => {
            "title" => "Card Title",
            "subtitle" => "Card Subtitle",
            "url" => "https://example.com"
          }
        }
      ]
    }

    extractor = Folio::Mcp::TiptapTextExtractor.new(tiptap)
    texts = extractor.extract

    # Should extract title and subtitle but not url
    titles = texts.select { |t| t[:field] == "title" }
    subtitles = texts.select { |t| t[:field] == "subtitle" }

    assert_equal 1, titles.size
    assert_equal "Card Title", titles.first[:value]

    assert_equal 1, subtitles.size
    assert_equal "Card Subtitle", subtitles.first[:value]

    # URL should not be extracted
    urls = texts.select { |t| t[:field] == "url" }
    assert_empty urls
  end

  test "skips empty values" do
    tiptap = {
      "type" => "doc",
      "content" => [
        {
          "type" => "customCard",
          "attrs" => {
            "title" => "",
            "subtitle" => nil
          }
        }
      ]
    }

    extractor = Folio::Mcp::TiptapTextExtractor.new(tiptap)
    texts = extractor.extract

    assert_empty texts
  end

  test "skips technical attributes" do
    tiptap = {
      "type" => "doc",
      "content" => [
        {
          "type" => "image",
          "attrs" => {
            "file_id" => 123,
            "alt" => "Image description"
          }
        }
      ]
    }

    extractor = Folio::Mcp::TiptapTextExtractor.new(tiptap)
    texts = extractor.extract

    # Should not extract file_id
    file_ids = texts.select { |t| t[:field] == "file_id" }
    assert_empty file_ids
  end

  test "handles nested content" do
    tiptap = {
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
                    { "type" => "text", "text" => "Item 1" }
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
                    { "type" => "text", "text" => "Item 2" }
                  ]
                }
              ]
            }
          ]
        }
      ]
    }

    extractor = Folio::Mcp::TiptapTextExtractor.new(tiptap)
    texts = extractor.extract

    assert_equal 2, texts.size
    assert_equal "Item 1", texts[0][:value]
    assert_equal "Item 2", texts[1][:value]
  end

  test "handles JSON string input" do
    tiptap_json = '{"type":"doc","content":[{"type":"paragraph","content":[{"type":"text","text":"Test"}]}]}'

    extractor = Folio::Mcp::TiptapTextExtractor.new(tiptap_json)
    texts = extractor.extract

    assert_equal 1, texts.size
    assert_equal "Test", texts.first[:value]
  end

  test "handles wrapped tiptap_content structure" do
    tiptap = {
      "tiptap_content" => {
        "type" => "doc",
        "content" => [
          {
            "type" => "paragraph",
            "content" => [
              { "type" => "text", "text" => "Wrapped content" }
            ]
          }
        ]
      }
    }

    extractor = Folio::Mcp::TiptapTextExtractor.new(tiptap)
    texts = extractor.extract

    assert_equal 1, texts.size
    assert_equal "Wrapped content", texts.first[:value]
  end
end
