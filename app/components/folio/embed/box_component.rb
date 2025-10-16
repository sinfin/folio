# frozen_string_literal: true

class Folio::Embed::BoxComponent < ApplicationComponent
  def initialize(folio_embed_data: {},
                 data: nil,
                 centered: true,
                 background_color: nil,
                 class_name: nil)
    @folio_embed_data = folio_embed_data.is_a?(Hash) ? folio_embed_data : {}
    @data = data
    @centered = centered
    @background_color = background_color
    @class_name = class_name
  end

  private
    def wrap_data
      return nil if inside_dev_tiptap?

      h = stimulus_controller("f-embed-box",
                              values: {
                                folio_embed_data: @folio_embed_data.to_json,
                                intersected: false,
                                centered: @centered,
                                background_color: @background_color,
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

    def inside_dev_tiptap?
      return @inside_dev_tiptap if defined?(@inside_dev_tiptap)
      @inside_dev_tiptap = ENV["FOLIO_TIPTAP_DEV"].present? && controller.is_a?(Folio::Console::Api::TiptapController) && controller.action_name == "render_nodes"
    end
end
