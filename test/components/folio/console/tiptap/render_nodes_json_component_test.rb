# frozen_string_literal: true

require "test_helper"

class Folio::Console::Tiptap::RenderNodesJsonComponentTest < Folio::Console::ComponentTest
  def test_render
    nodes_hash = {
      1 => Dummy::Tiptap::Node::Card.new(title: "foo"),
      2 => Dummy::Tiptap::Node::Card.new(content: "invalid"),
    }

    c = render_inline(Folio::Console::Tiptap::RenderNodesJsonComponent.new(nodes_hash:))
    hash = JSON.parse c.children[0].to_s

    assert_equal 2, hash["data"].size

    assert_equal 1, hash["data"][0]["unique_id"]
    assert hash["data"][0]["html"]
    assert_nil hash["data"][0]["error_message"]
    assert_nil hash["data"][0]["invalid"]
    page = Capybara.string(hash["data"][0]["html"])
    assert page.has_css?(".d-tiptap-node-card")
    assert_not page.has_css?(".f-c-tiptap-invalid-node")

    assert_equal 2, hash["data"][1]["unique_id"]
    assert_nil hash["data"][1]["html"]
    assert_nil hash["data"][1]["error_message"]
    assert_equal true, hash["data"][1]["invalid"]
  end
end
