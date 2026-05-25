# frozen_string_literal: true

class Dummy::Tiptap::Node::CardGroup < Folio::Tiptap::Node
  class Card < Folio::Tiptap::Node
    BACKGROUNDS = %w[white blue].freeze

    tiptap_node nested: true,
                structure: {
                   title: :string,
                   text: :text,
                   content: :rich_text,
                   button_url_json: :url_json,
                   background: BACKGROUNDS,
                   cover: :image,
                 }

    validates :title,
              presence: true
  end

  tiptap_node structure: {
    title: :string,
    intro: :text,
    cards: {
      type: :nested_nodes,
      node_class: Card,
    },
  }

  validates :title,
            presence: true
end
