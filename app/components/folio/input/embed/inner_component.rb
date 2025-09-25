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

    def data
      stimulus_controller("f-input-embed-inner",
                          values: {
                            state:,
                          },
                          action: {
                            input: "onInput",
                          })
    end

    def html_value
      if @folio_embed_data
        @folio_embed_data["html"]
      end
    end

    def url_value
      if @folio_embed_data
        @folio_embed_data["url"]
      end
    end

    def state
      if @folio_embed_data && @folio_embed_data["active"]
        return "valid-html" if @folio_embed_data["html"].present?

        if @folio_embed_data["url"].present?
          type = Folio::Embed.url_type(@folio_embed_data["url"])
          if type && @folio_embed_data["type"] == type
            return "valid-url"
          else
            return "invalid-url"
          end
        end
      end

      "blank"
    end
end
