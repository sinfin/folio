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
end
