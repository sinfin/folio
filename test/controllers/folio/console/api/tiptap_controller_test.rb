# frozen_string_literal: true

require "test_helper"

class Folio::Console::Api::TiptapControllerTest < Folio::Console::BaseControllerTest
  test "edit_node" do
    post edit_node_console_api_tiptap_path(format: :json), params: {
      tiptap_node_type: "Folio::Tiptap::Node::Card",
    }
    assert_response :ok

    page = Capybara.string(response.parsed_body["data"])
    assert page.has_css?(".f-c-tiptap-overlay-form")
  end
end
