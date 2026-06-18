# frozen_string_literal: true

class Folio::Embed::BoxComponent < ApplicationComponent
  def initialize(folio_embed_data: {},
                 data: nil,
                 centered: true,
                 background_color: nil,
                 light_mode_background_color: nil,
                 dark_mode_background_color: nil,
                 class_name: nil)
    @folio_embed_data = folio_embed_data.is_a?(Hash) ? folio_embed_data : {}
    @data = data
    @centered = centered
    @background_color = background_color
    @light_mode_background_color = light_mode_background_color
    @dark_mode_background_color = dark_mode_background_color
    @class_name = class_name
  end

  private
    def before_render
      if dual_theme_background?
        color = @light_mode_background_color
      elsif valid_hex_color?(@background_color)
        color = @background_color
      end

      return unless color

      @style = "background-color: #{color};"
      @low_luminance = get_luminance(color) < 0.5
    end

    def valid_hex_color?(value)
      value.is_a?(String) && value.match?(/^#[0-9A-Fa-f]{6}$/)
    end

    def dual_theme_background?
      valid_hex_color?(@light_mode_background_color) && valid_hex_color?(@dark_mode_background_color)
    end

    def wrap_data
      return nil if inside_dev_tiptap?

      h = stimulus_controller("f-embed-box",
                              values: {
                                folio_embed_data: @folio_embed_data.to_json,
                                intersected: false,
                                centered: @centered,
                                background_color: @background_color,
                                light_mode_background_color: @light_mode_background_color,
                                dark_mode_background_color: @dark_mode_background_color,
                              },
                              action: {
                                "message@window" => "onWindowMessage",
                                "folioColorSchemeChange@window" => "onFolioColorSchemeChange",
                                "f-embed-box:load" => "onLoadTrigger",
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

    def get_luminance(hex)
      return 1 unless hex.is_a?(String) && hex.match?(/^#[0-9A-Fa-f]{6}$/)

      begin
        # Convert hex to RGB
        r = hex[1..2].to_i(16) / 255.0
        g = hex[3..4].to_i(16) / 255.0
        b = hex[5..6].to_i(16) / 255.0

        # Check for invalid values
        return 1 if [r, g, b].any? { |val| val.nan? }

        # Apply gamma correction
        r_linear = r <= 0.03928 ? r / 12.92 : ((r + 0.055) / 1.055)**2.4
        g_linear = g <= 0.03928 ? g / 12.92 : ((g + 0.055) / 1.055)**2.4
        b_linear = b <= 0.03928 ? b / 12.92 : ((b + 0.055) / 1.055)**2.4

        # Calculate relative luminance
        0.2126 * r_linear + 0.7152 * g_linear + 0.0722 * b_linear
      rescue
        # Return default luminance for light background if parsing fails
        1
      end
    end
end
