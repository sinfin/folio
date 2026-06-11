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

  def test_render_orphaned_placement
    video = create(:folio_file_video)
    Folio::FilePlacement::VideoCover.create!(placement: nil, file: video)

    render_inline(Folio::Console::Files::Show::FilePlacementsComponent.new(file: video))

    assert_selector(".f-c-files-show-file-placements__row--orphaned")
    assert_selector(".f-c-files-show-file-placements__row--orphaned",
                    text: I18n.t("folio.console.files.show.file_placements_component.orphaned"))
  end

  def test_render_published_owner_state
    video = create(:folio_file_video)
    page = create(:folio_page, published: true)
    Folio::FilePlacement::VideoCover.create!(placement: page, file: video)

    render_inline(Folio::Console::Files::Show::FilePlacementsComponent.new(file: video))

    assert_selector(".f-c-files-show-file-placements__row .text-success",
                    text: I18n.t("folio.console.files.show.file_placements_component.published"))
    assert_no_selector(".f-c-files-show-file-placements__row--orphaned")
  end

  def test_render_unpublished_owner_state
    video = create(:folio_file_video)
    page = create(:folio_page, published: false)
    Folio::FilePlacement::VideoCover.create!(placement: page, file: video)

    render_inline(Folio::Console::Files::Show::FilePlacementsComponent.new(file: video))

    assert_selector(".f-c-files-show-file-placements__row .text-danger",
                    text: I18n.t("folio.console.files.show.file_placements_component.unpublished"))
  end

  def test_render_owner_label_for_regular_placement
    file_placement = create(:folio_file_placement_cover)

    render_inline(Folio::Console::Files::Show::FilePlacementsComponent.new(file: file_placement.file))

    assert_selector(".f-c-files-show-file-placements__row",
                    text: file_placement.placement.to_label)
  end
end
