# frozen_string_literal: true

require Folio::Engine.root.join("test/test_helper")

class Dummy::Ui::EmbedComponentTest < Folio::ComponentTest
  def test_render
    render_inline(Dummy::Ui::EmbedComponent.new(html: "hello", caption: "Embed caption"))

    assert_selector(".d-ui-embed")
  end
end
