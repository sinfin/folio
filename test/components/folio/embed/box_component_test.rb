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
end
