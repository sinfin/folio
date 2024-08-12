# frozen_string_literal: true

require "test_helper"

class Dummy::Ui::CardComponentTest < Folio::ComponentTest
  def test_render
    render_inline(Dummy::Ui::CardComponent.new(title: "title"))

    assert_selector(".d-ui-card")
  end
end
