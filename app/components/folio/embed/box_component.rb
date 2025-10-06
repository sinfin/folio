# frozen_string_literal: true

class Folio::Embed::BoxComponent < ApplicationComponent
  def initialize(folio_embed_data: {}, data: nil)
    @folio_embed_data = folio_embed_data.is_a?(Hash) ? folio_embed_data : {}
    @data = data
  end

  private
    def wrap_data
      h = stimulus_controller("f-embed-box",
                              values: {
                                folio_embed_data: @folio_embed_data.to_json,
                                intersected: false,
                              },
                              action: {
                                "message@window" => "onWindowMessage",
                                "f-observer:intersect" => "onIntersect",
                                "f-input-embed-inner:update" => "onInnerUpdate",
                              })

      if @data
        stimulus_merge(@data, h)
      else
        h
      end
    end
end
