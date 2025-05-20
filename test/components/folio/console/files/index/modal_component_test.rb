# frozen_string_literal: true

require "test_helper"

class Folio::Console::Files::Index::ModalComponentTest < Folio::Console::ComponentTest
  def test_render
    with_controller_class(Folio::Console::File::ImagesController) do
      with_request_url "/console/file/images" do
        file_type = "Folio::File::Image"

        render_inline(Folio::Console::Files::Index::ModalComponent.new(file_type:))

        assert_selector(".f-c-files-index-modal")
      end
    end
  end
end
