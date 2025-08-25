# frozen_string_literal: true

require "test_helper"

class Folio::Console::Api::TiptapControllerTest < Folio::Console::BaseControllerTest
  class Node < Folio::Tiptap::Node
    tiptap_node structure: {
      title: :string,
      content: :text,
      button_url_json: :url_json
    }

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

  test "render_nodes" do
    post render_nodes_console_api_tiptap_path(format: :json), params: {
      "nodes" => [
        {
          "unique_id" => "folioTiptapNode-1",
          "attrs" => {
            "version" => 1,
            "type" => "Dummy::Tiptap::Node::Card",
            "data" => { "title" => "asf" }
          }
        }
      ]
    }
    assert_response :ok

    hash = response.parsed_body

    assert_equal 1, hash["data"].size
    assert_equal "folioTiptapNode-1", hash["data"][0]["unique_id"]
    assert_nil hash["data"][0]["invalid"]
    assert_nil hash["data"][0]["error_message"]

    page = Capybara.string(hash["data"][0]["html"])
    assert page.has_css?(".d-tiptap-node-card")

    post render_nodes_console_api_tiptap_path(format: :json), params: {
      "nodes" => [
        {
          "unique_id" => "folioTiptapNode-1",
          "attrs" => {
            "version" => 1,
            "type" => "Dummy::Tiptap::Node::Card",
            "data" => { "title" => "", "content" => "invalid - missing title" }
          }
        }
      ]
    }
    assert_response :ok

    hash = response.parsed_body

    assert_equal 1, hash["data"].size
    assert_equal "folioTiptapNode-1", hash["data"][0]["unique_id"]
    assert_equal true, hash["data"][0]["invalid"]
    assert_nil hash["data"][0]["error_message"]
  end

  test "render_nodes - unknown folioTiptapNode type" do
    post render_nodes_console_api_tiptap_path(format: :json), params: {
      "nodes" => [
        {
          "unique_id" => "folioTiptapNode-1",
          "attrs" => {
            "version" => 1,
            "type" => "unknown",
            "data" => { "title" => "asf" }
          }
        }
      ]
    }
    assert_response :ok

    hash = response.parsed_body

    assert_equal 1, hash["data"].size
    assert_equal "folioTiptapNode-1", hash["data"][0]["unique_id"]
    assert_nil hash["data"][0]["html"]
    assert_equal true, hash["data"][0]["invalid"]
    assert_equal "Invalid Tiptap node type: unknown", hash["data"][0]["error_message"]
  end
end
