# frozen_string_literal: true

class Dummy::Tiptap::Node::CardComponent < ApplicationComponent
  def initialize(node:)
    @node = node
  end
end
