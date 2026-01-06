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

  class PasteableNode < Folio::Tiptap::Node
    tiptap_node structure: {
      title: :string,
      content: :text,
    }, tiptap_config: {
      paste: {
        pattern: %r{https?://example\.com/.*},
        lambda: ->(string) {
          PasteableNode.new(title: "Pasted from #{string}", content: "Content: #{string}")
        },
      },
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

  test "paste - successful match" do
    post paste_console_api_tiptap_path(format: :json), params: {
      pasted_string: "https://example.com/some-path",
      tiptap_node_type: "Folio::Console::Api::TiptapControllerTest::PasteableNode",
    }
    assert_response :ok

    hash = response.parsed_body

    assert_equal({ "tiptap_node" => {
      "type" => "folioTiptapNode",
      "attrs" => {
        "version" => 1,
        "type" => "Folio::Console::Api::TiptapControllerTest::PasteableNode",
        "data" => {
          "title" => "Pasted from https://example.com/some-path",
          "content" => "Content: https://example.com/some-path",
        },
      },
    } }, hash["data"])
  end

  test "paste - no match" do
    post paste_console_api_tiptap_path(format: :json), params: {
      pasted_string: "https://other-site.com/path",
      tiptap_node_type: "Folio::Console::Api::TiptapControllerTest::PasteableNode",
    }
    assert_response :unprocessable_entity

    hash = response.parsed_body

    assert_equal({ "error" => "Paste string does not match pattern" }, hash)
  end

  test "paste - missing pasted_string" do
    post paste_console_api_tiptap_path(format: :json), params: {
      tiptap_node_type: "Folio::Console::Api::TiptapControllerTest::PasteableNode",
    }
    assert_response :bad_request
  end

  test "paste - missing tiptap_node_type" do
    post paste_console_api_tiptap_path(format: :json), params: {
      pasted_string: "https://example.com/some-path",
    }
    assert_response :bad_request
  end

  test "paste - node type without paste config" do
    post paste_console_api_tiptap_path(format: :json), params: {
      pasted_string: "https://example.com/some-path",
      tiptap_node_type: "Folio::Console::Api::TiptapControllerTest::Node",
    }
    assert_response :unprocessable_entity

    hash = response.parsed_body

    assert_equal({ "error" => "Node type does not have paste configuration" }, hash)
  end

  test "paste - invalid node type" do
    post paste_console_api_tiptap_path(format: :json), params: {
      pasted_string: "https://example.com/some-path",
      tiptap_node_type: "Invalid::Node::Type",
    }
    assert_response :bad_request
  end
end
