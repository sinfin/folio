# frozen_string_literal: true

require "test_helper"

class Folio::Console::Ui::ImageComponentTest < Folio::Console::ComponentTest
  def test_render
    render_inline(Folio::Console::Ui::ImageComponent.new(placement: create(:folio_cover_placement),
                                                         size: "100x100"))

    assert_selector(".f-c-ui-image")
  end
end
