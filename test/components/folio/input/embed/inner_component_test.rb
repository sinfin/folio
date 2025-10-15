# frozen_string_literal: true

require "test_helper"

class Folio::Input::Embed::InnerComponentTest < Folio::ComponentTest
  def test_render
    render_inline(Folio::Input::Embed::InnerComponent.new(folio_embed_data: {}))

    assert_selector(".f-input-embed-inner")
  end
end
