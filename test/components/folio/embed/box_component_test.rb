# frozen_string_literal: true

require "test_helper"

class Folio::Embed::BoxComponentTest < Folio::ComponentTest
  def test_render_inactive
    folio_embed_data = { "active" => false }

    render_inline(Folio::Embed::BoxComponent.new(folio_embed_data:))

    assert_selector(".f-embed-box")
  end

  def test_render_html
    folio_embed_data = { "active" => true, "html" => '<iframe width="560" height="315" src="https://www.youtube.com/embed/8DPcXHMGMBc?si=D0qtVp8LBUJWDTsp" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>' }

    render_inline(Folio::Embed::BoxComponent.new(folio_embed_data:))

    assert_selector(".f-embed-box")
  end

  def test_render_youtube
    folio_embed_data = { "active" => true, "url" => "https://www.youtube.com/watch?v=8DPcXHMGMBc", "type" => "youtube" }

    render_inline(Folio::Embed::BoxComponent.new(folio_embed_data:))

    assert_selector(".f-embed-box")
  end

  def test_render_dual_theme_background_colors
    folio_embed_data = { "active" => false }

    render_inline(Folio::Embed::BoxComponent.new(
      folio_embed_data:,
      light_mode_background_color: "#ffffff",
      dark_mode_background_color: "#111111"
    ))

    assert_selector(".f-embed-box[data-f-embed-box-light-mode-background-color-value='#ffffff']")
    assert_selector(".f-embed-box[data-f-embed-box-dark-mode-background-color-value='#111111']")
    assert_selector(".f-embed-box[style='background-color: #ffffff;']")
  end

  def test_render_partial_dual_theme_background_falls_back_to_legacy_background_color
    folio_embed_data = { "active" => false }

    render_inline(Folio::Embed::BoxComponent.new(
      folio_embed_data:,
      background_color: "#111111",
      light_mode_background_color: "#ffffff"
    ))

    assert_selector(".f-embed-box[style='background-color: #111111;']")
    assert_selector(".f-embed-box.folio-inversed-loader")
  end

  def test_render_invalid_dual_theme_background_falls_back_to_legacy_background_color
    folio_embed_data = { "active" => false }

    render_inline(Folio::Embed::BoxComponent.new(
      folio_embed_data:,
      background_color: "#112233",
      light_mode_background_color: "not-hex",
      dark_mode_background_color: "#000000"
    ))

    assert_selector(".f-embed-box[style='background-color: #112233;']")
  end

  def test_render_invalid_background_color_is_ignored
    folio_embed_data = { "active" => false }

    render_inline(Folio::Embed::BoxComponent.new(
      folio_embed_data:,
      background_color: "not-hex"
    ))

    assert_selector(".f-embed-box:not([style])")
  end
end
