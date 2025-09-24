# frozen_string_literal: true

class Folio::Input::Embed::InnerComponent < ApplicationComponent
  def initialize(folio_embed_data:)
    @folio_embed_data = folio_embed_data
  end

  private
    def html_label
      [
        content_tag(:span,
                    t(".label/html"),
                    class: "f-input-embed-inner__html-label f-input-embed-inner__html-label--html"),
        content_tag(:span,
                    t(".label/html_or_url"),
                    class: "f-input-embed-inner__html-label f-input-embed-inner__html-label--html-or-url"),
      ].join(" ").html_safe
    end
end
