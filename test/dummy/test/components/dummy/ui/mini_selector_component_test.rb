# frozen_string_literal: true

require "test_helper"

class Dummy::Ui::MiniSelectorComponentTest < Folio::ComponentTest
  def test_render
    model = "hello"

    render_inline(Dummy::Ui::MiniSelectorComponent.new(model:))

    assert_selector(".d-ui-mini-selector")
  end
end
