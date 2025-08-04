# frozen_string_literal: true

Folio::Page.class_eval do
  def tiptap_config
    Folio::Tiptap::Config.new(single_image_node: "Dummy::Tiptap::Node::Card")
  end
end
