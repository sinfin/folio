# frozen_string_literal: true

require "test_helper"

class Dummy::Ui::ImageComponentTest < Folio::ComponentTest
  def test_render
    render_inline(Dummy::Ui::ImageComponent.new(placement: create(:folio_file_placement_cover),
                                                size: "100x100"))

    assert_selector(".d-ui-image")

    render_inline(Dummy::Ui::ImageComponent.new(placement: create(:folio_file_placement_cover),
                                                size: "100x100",
                                                spacer_background: false))

    assert_selector(".d-ui-image")
  end
end
