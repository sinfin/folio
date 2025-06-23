# frozen_string_literal: true

class Folio::Tiptap::Node::Card < Folio::Tiptap::Node
  tiptap_node title: :string,
              content: :text,
              button_url_json: :url_json

  validates :title,
            presence: true
end
