# frozen_string_literal: true

require "test_helper"

class Dummy::Ui::EmbedComponentTest < Folio::ComponentTest
  def test_render
    model = "hello"

    render_inline(Dummy::Ui::EmbedComponent.new(model:))

    assert_selector(".d-ui-embed")
  end
end
