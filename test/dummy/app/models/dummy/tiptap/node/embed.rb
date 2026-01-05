# frozen_string_literal: true

class Dummy::Tiptap::Node::Embed < Folio::Tiptap::Node
  include Folio::Embed::Validation

  tiptap_node structure: {
    folio_embed_data: :embed,
  }
end
