# frozen_string_literal: true

require "test_helper"

class Folio::Tiptap::ConfigTest < ActiveSupport::TestCase
  class Node < Folio::Tiptap::Node
    tiptap_node structure: {
      title: :string,
    }
  end

  class NestedNode < Folio::Tiptap::Node
    tiptap_node nested: true,
                structure: {
                   title: :string,
                 }
  end

  test "rejects nested nodes from explicit top-level registration" do
    assert_raises(ArgumentError) do
      Folio::Tiptap::Config.new(node_names: [NestedNode.name])
    end
  end

  test "accepts non-nested nodes for top-level registration" do
    config = Folio::Tiptap::Config.new(node_names: [Node.name])

    assert_equal [Node.name], config.node_names
  end
end
