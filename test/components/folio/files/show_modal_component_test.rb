# frozen_string_literal: true

require "test_helper"

class Folio::Console::Files::ShowModalComponentTest < Folio::ComponentTest
  def test_render_with_file
    file = create(:folio_file_image)

    render_inline(Folio::Console::Files::ShowModalComponent.new(file: file))

    assert_selector(".f-c-files-show-modal")
  end

  def test_render_without_file
    render_inline(Folio::Console::Files::ShowModalComponent.new)

    assert_selector(".f-c-files-show-modal")
  end
end
