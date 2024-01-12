# frozen_string_literal: true

require "test_helper"

class Dummy::Ui::EmbedComponentTest < Folio::ComponentTest
  def test_render
    render_inline(Dummy::Ui::EmbedComponent.new(html: "hello", caption: "Embed caption"))

    assert_selector(".d-ui-embed")
  end
end
