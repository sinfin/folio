# frozen_string_literal: true

class Dummy::Tiptap::Node::BaseComponent < ApplicationComponent
  def initialize(node:, tiptap_content_information:, editor_preview: false)
    @node = node
    @tiptap_content_information = tiptap_content_information
    @editor_preview = editor_preview
  end
end
