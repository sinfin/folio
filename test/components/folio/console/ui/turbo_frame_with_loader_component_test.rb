# frozen_string_literal: true

require "test_helper"

class Folio::Console::Ui::TurboFrameWithLoaderComponentTest < Folio::Console::ComponentTest
  def test_render
    render_inline(Folio::Console::Ui::TurboFrameWithLoaderComponent.new(id: "foo"))

    assert_selector(".f-c-ui-turbo-frame-with-loader")
    assert_selector(".f-c-ui-turbo-frame-with-loader turbo-frame#foo")
  end
end
