# frozen_string_literal: true

class Dummy::Tiptap::Node::Embed < Folio::Tiptap::Node
  tiptap_node structure: {
    folio_embed_data: :embed,
  }
end
