# frozen_string_literal: true

require "test_helper"

class Folio::Tiptap::ModelTest < ActiveSupport::TestCase
  test "convert_titap_fields_to_hashes" do
    page = create(:folio_page)

    Folio::Page.stub(:has_folio_tiptap?, true) do
      page.tiptap_content = dummy_tiptap_doc.to_json
      assert page.tiptap_content.is_a?(Hash)
      assert_equal(dummy_tiptap_doc, page.tiptap_content)
    end
  end

  private
    def dummy_tiptap_doc
      {
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
    end
end
