# frozen_string_literal: true

require "test_helper"

class Folio::Console::Files::IndexModalComponentTest < Folio::Console::ComponentTest
  def test_render
    with_controller_class(Folio::Console::File::ImagesController) do
      with_request_url "/console/file/images" do
        render_inline(Folio::Console::Files::IndexModalComponent.new)

        assert_selector(".f-c-files-index-modal")
      end
    end
  end
end
