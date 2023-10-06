# frozen_string_literal: true

require "test_helper"

class Dummy::Ui::IconComponentTest < Folio::ComponentTest
  def test_render
    render_inline(Dummy::Ui::IconComponent.new(name: :close))

    assert_selector(".d-ui-icon")
  end
end
