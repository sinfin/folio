# frozen_string_literal: true

require "test_helper"

class Folio::Console::Files::ShowModalComponentTest < Folio::ComponentTest
  def test_render_with_file
    with_controller_class(Folio::Console::File::ImagesController) do
      with_request_url "/console/file/images" do
        file = create(:folio_file_image)

        render_inline(Folio::Console::Files::ShowModalComponent.new(file:))

        assert_selector(".f-c-files-show-modal")
        assert_selector(".f-c-files-show-modal .f-c-files-show")
      end
    end
  end

  def test_render_without_file
    with_controller_class(Folio::Console::File::ImagesController) do
      with_request_url "/console/file/images" do
        render_inline(Folio::Console::Files::ShowModalComponent.new)

        assert_selector(".f-c-files-show-modal")
        assert_no_selector(".f-c-files-show-modal .f-c-files-show")
      end
    end
  end
end
