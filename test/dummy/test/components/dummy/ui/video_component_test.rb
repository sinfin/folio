# frozen_string_literal: true

require "test_helper"

class Dummy::Ui::VideoComponentTest < Folio::ComponentTest
  def test_render
    video = create(:folio_file_video)

    render_inline(Dummy::Ui::VideoComponent.new(video:))

    assert_selector(".d-ui-video")
  end
end
