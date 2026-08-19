# frozen_string_literal: true

require "test_helper"

class Folio::Console::Files::Show::PreviewComponentTest < Folio::Console::ComponentTest
  def test_render
    file = create(:folio_file_image)

    render_inline(Folio::Console::Files::Show::PreviewComponent.new(file:))

    assert_selector(".f-c-files-show-preview")
  end

  def test_vertical_cra_video_passes_orientation_to_player
    file = create(:folio_file_video)
    file.define_singleton_method(:cra_media_cloud_vertical?) { true }

    render_inline(Folio::Console::Files::Show::PreviewComponent.new(file:))

    assert_selector(".f-player--vertical")
    assert_selector('[data-f-player-vertical-value="true"]')
  end
end
