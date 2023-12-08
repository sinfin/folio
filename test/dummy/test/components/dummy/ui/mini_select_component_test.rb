# frozen_string_literal: true

require "test_helper"

class Dummy::Ui::MiniSelectComponentTest < Folio::ComponentTest
  def test_render
    render_inline(Dummy::Ui::MiniSelectComponent.new(type: :currency))

    assert_select(".d-ui-mini-select")
  end
end
