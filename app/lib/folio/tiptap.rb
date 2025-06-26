# frozen_string_literal: true

module Folio
  module Tiptap
    def self.remote_script_urls(context:)
      {
        urls: [context.asset_path("folio-tiptap.js")],
        cssUrls: [context.asset_path("folio-tiptap.css")],
      }
    end

    def self.default_tiptap_nodes
      %w[
        Dummy::Tiptap::Node::Card
      ]
    end
  end
end
