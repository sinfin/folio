# frozen_string_literal: true

class Dummy::Tiptap::Node::CardComponent < ApplicationComponent
  def initialize(node:, editor_preview: false)
    @node = node
    @editor_preview = editor_preview
  end
end
