# frozen_string_literal: true

require "test_helper"

class Folio::Console::Files::Show::PreviewComponentTest < Folio::Console::ComponentTest
  def test_render
    file = create(:folio_file_image)

    render_inline(Folio::Console::Files::Show::PreviewComponent.new(file:))

    assert_selector(".f-c-files-show-preview")
  end
end
