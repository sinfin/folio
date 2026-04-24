# frozen_string_literal: true

require "test_helper"

class Folio::Tiptap::PlainTextTest < ActiveSupport::TestCase
  test "uses stored text when present" do
    value = TiptapHelper.tiptap_text_content("Stored text")

    assert_equal "Stored text", Folio::Tiptap::PlainText.from_value(value)
  end

  test "extracts text from tiptap content when stored text is blank" do
    value = {
      Folio::Tiptap::TIPTAP_CONTENT_JSON_STRUCTURE[:content] => {
        "type" => "doc",
        "content" => [
          {
            "type" => "heading",
            "content" => [{ "type" => "text", "text" => "Title" }],
          },
          {
            "type" => "paragraph",
            "content" => [
              { "type" => "text", "text" => "First" },
              { "type" => "hardBreak" },
              { "type" => "text", "text" => "Second" },
            ],
          },
        ],
      },
    }

    assert_equal "Title\nFirst\nSecond", Folio::Tiptap::PlainText.from_value(value)
  end

  test "returns empty string for invalid json" do
    assert_equal "", Folio::Tiptap::PlainText.from_value("{")
  end
end
