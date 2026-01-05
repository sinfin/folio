# frozen_string_literal: true

class Dummy::Tiptap::Node::Card < Folio::Tiptap::Node
  BACKGROUNDS = %w[gray blue]

  tiptap_node structure: {
    title: :string,
    text: :text,
    content: :rich_text,
    button_url_json: :url_json,
    background: BACKGROUNDS,
    cover: :image,
    reports: :documents,
    page: { class_name: "Folio::Page" },
  }

  validates :title,
            presence: true
end
