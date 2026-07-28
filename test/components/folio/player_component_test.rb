# frozen_string_literal: true

require "test_helper"

class Folio::PlayerComponentTest < Folio::ComponentTest
  def test_audio
    file = create(:folio_file_audio)

    render_inline(Folio::PlayerComponent.new(file:))

    assert_selector(".f-player")
    assert_selector(".f-player--audio")
  end

  def test_video
    file = create(:folio_file_video)

    render_inline(Folio::PlayerComponent.new(file:))

    assert_selector(".f-player")
    assert_selector(".f-player--video")
  end

  def test_vertical_video_gets_vertical_modifier
    file = create(:folio_file_video)
    file.file_width = 1080
    file.file_height = 1920

    render_inline(Folio::PlayerComponent.new(file:))

    assert_selector(".f-player--video.f-player--vertical")
  end

  def test_landscape_video_has_no_vertical_modifier
    file = create(:folio_file_video)
    file.file_width = 1920
    file.file_height = 1080

    render_inline(Folio::PlayerComponent.new(file:))

    assert_selector(".f-player--video")
    assert_no_selector(".f-player--vertical")
  end

  def test_square_video_has_no_vertical_modifier
    file = create(:folio_file_video)
    file.file_width = 1080
    file.file_height = 1080

    render_inline(Folio::PlayerComponent.new(file:))

    assert_no_selector(".f-player--vertical")
  end

  def test_video_without_dimensions_has_no_vertical_modifier
    file = create(:folio_file_video)
    file.file_width = nil
    file.file_height = nil

    render_inline(Folio::PlayerComponent.new(file:))

    assert_no_selector(".f-player--vertical")
  end
end
