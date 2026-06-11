# frozen_string_literal: true

require "test_helper"

class Folio::Console::FilePlacementsControllerTest < Folio::Console::BaseControllerTest
  test "destroy removes an orphaned placement" do
    video = create(:folio_file_video)
    placement = Folio::FilePlacement::VideoCover.create!(placement: nil, file: video)

    delete folio.console_file_placement_path(placement)

    assert_redirected_to url_for([:console, video])
    assert_not Folio::FilePlacement::Base.exists?(placement.id)
    assert_equal 0, video.reload.file_placements_count
  end

  test "destroy refuses a placement with a living owner" do
    video = create(:folio_file_video)
    page = create(:folio_page, published: true)
    placement = Folio::FilePlacement::VideoCover.create!(placement: page, file: video)

    assert_raises(ActiveRecord::RecordNotFound) do
      delete folio.console_file_placement_path(placement)
    end

    assert Folio::FilePlacement::Base.exists?(placement.id)
  end
end
