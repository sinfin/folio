# frozen_string_literal: true

class Dummy::Tiptap::Node::CardComponent < Dummy::Tiptap::Node::BaseComponent
  private
    def style
      [
        "overflow-wrap: break-word;",
        "background: #{@node.background === 'blue' ? '#d7e9ff' : '#e8e8e8'};",
        @node.color ? "color: #{@node.color};" : nil,
      ].compact.join(" ")
    end
end
