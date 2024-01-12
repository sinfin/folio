# frozen_string_literal: true

require "test_helper"

class Dummy::Ui::ShareComponentTest < Folio::ComponentTest
  def test_render

    render_inline(Dummy::Ui::ShareComponent.new(mobile_collapsible: true))
    assert_selector(".d-ui-share")

  end
end
