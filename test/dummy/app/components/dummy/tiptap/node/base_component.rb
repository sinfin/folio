# frozen_string_literal: true

class Dummy::Tiptap::Node::BaseComponent < ApplicationComponent
  def initialize(node:, tiptap_content_information:)
    @node = node
    @tiptap_content_information = tiptap_content_information
  end
end
