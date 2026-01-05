# frozen_string_literal: true

require "test_helper"

class Folio::Console::Files::Show::FilePlacementsComponentTest < Folio::Console::ComponentTest
  def test_render_no_placements
    file = create(:folio_file_image)

    render_inline(Folio::Console::Files::Show::FilePlacementsComponent.new(file:))

    assert_selector(".f-c-files-show-file-placements")
    assert_no_selector(".f-c-files-show-file-placements__table")
  end

  def test_render_with_placements
    file = create(:folio_file_placement_cover).file

    render_inline(Folio::Console::Files::Show::FilePlacementsComponent.new(file:))

    assert_selector(".f-c-files-show-file-placements")
    assert_selector(".f-c-files-show-file-placements__table")
  end
end
