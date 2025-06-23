# frozen_string_literal: true

require "test_helper"

class Folio::Console::Api::TiptapControllerTest < Folio::Console::BaseControllerTest
  class Node < Folio::Tiptap::Node
    tiptap_node title: :string,
                content: :text,
                button_url_json: :url_json

    validates :title,
              presence: true
  end

  test "edit_node" do
    post edit_node_console_api_tiptap_path(format: :json), params: {
      tiptap_node_attrs: { type: "Folio::Console::Api::TiptapControllerTest::Node" },
    }
    assert_response :ok

    page = Capybara.string(response.parsed_body["data"])
    assert page.has_css?(".f-c-tiptap-overlay-form")
  end

  test "save_node" do
    post save_node_console_api_tiptap_path(format: :json), params: {
      tiptap_node_attrs: {
        type: "Folio::Console::Api::TiptapControllerTest::Node"
      },
    }
    assert_response :ok

    hash = response.parsed_body

    assert_nil hash["meta"]

    page = Capybara.string(hash["data"])
    assert page.has_css?(".f-c-tiptap-overlay-form")
    assert page.has_css?('[name="tiptap_node_attrs[data][title]"].is-invalid')

    post save_node_console_api_tiptap_path(format: :json), params: {
      tiptap_node_attrs: {
        type: "Folio::Console::Api::TiptapControllerTest::Node",
        data: {
          title: "foo",
        }
      },
    }
    assert_response :ok

    hash = response.parsed_body

    assert_equal true, hash["meta"]["tiptap_node_valid"]
    assert_equal({ "tiptap_node" => {
      "type" => "folioTiptapNode",
      "attrs" => {
        "version" => 1,
        "type" => "Folio::Console::Api::TiptapControllerTest::Node",
        "data" => { "title" => "foo" },
      },
    } }, hash["data"])
  end
end
