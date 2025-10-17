# frozen_string_literal: true

class Folio::Input::Embed::InnerComponent < ApplicationComponent
  bem_class_name :compact

  def initialize(folio_embed_data:, compact: false)
    @folio_embed_data = folio_embed_data
    @compact = compact
  end

  private
    def data
      stimulus_controller("f-input-embed-inner",
                          values: {
                            state:,
                            supported_types: supported_types_json,
                            folio_embed_data: folio_embed_data_json,
                          },
                          action: {
                            "input" => "onInput",
                          })
    end

    def value
      if @folio_embed_data
        return @folio_embed_data["html"] if @folio_embed_data["html"]
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

    def supported_types_json
      Folio::Embed::SUPPORTED_TYPES.transform_values(&:source).to_json
    end

    def folio_embed_data_json
      (@folio_embed_data || {}).to_json
    end

    def html_or_url_input_id
      "f-input-embed-inner__input-#{SecureRandom.hex(10)}"
    end

    def hint
      helpers.safe_join [
        content_tag(:span, t(".hint"), class: "f-input-embed-inner__hint f-input-embed-inner__hint--regular"),
        content_tag(:span, t(".invalid_url"), class: "f-input-embed-inner__hint f-input-embed-inner__hint--invalid"),
      ]
    end
end
