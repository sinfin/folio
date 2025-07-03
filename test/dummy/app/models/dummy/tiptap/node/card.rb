# frozen_string_literal: true

class Dummy::Tiptap::Node::Card < Folio::Tiptap::Node
  tiptap_node structure: {
    title: :string,
    content: :text,
    button_url_json: :url_json,
    cover: :image,
    reports: :documents,
    page: { class_name: "Folio::Page" },
  }

  validates :title,
            presence: true
end
