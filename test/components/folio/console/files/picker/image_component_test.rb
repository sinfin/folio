# frozen_string_literal: true

require "test_helper"

class Folio::Console::Files::Picker::ImageComponentTest < Folio::Console::ComponentTest
  def test_render
    file = create(:folio_file_image)

    render_inline(Folio::Console::Files::Picker::ImageComponent.new(file:))

    assert_selector(".f-c-files-picker-image")
  end
end
