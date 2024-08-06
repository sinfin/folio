# frozen_string_literal: true

require "test_helper"

class Folio::Console::Catalogue::CoverComponentTest < Folio::Console::ComponentTest
  def test_render
    render_inline(Folio::Console::Catalogue::CoverComponent.new(file: create(:folio_file_image)))

    assert_selector(".f-c-catalogue-cover")
  end
end
