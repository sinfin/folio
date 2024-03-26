# frozen_string_literal: true

require "test_helper"

class Dummy::Ui::ImageComponentTest < Folio::ComponentTest
  def test_render
    render_inline(Dummy::Ui::ImageComponent.new(placement: create(:folio_cover_placement),
                                                size: "100x100"))

    assert_selector(".d-ui-image")
  end
end
