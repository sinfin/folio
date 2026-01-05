# frozen_string_literal: true

require "test_helper"

class Folio::Console::Files::Batch::BarComponentTest < Folio::Console::ComponentTest
  def test_render
    with_controller_class(Folio::Console::File::ImagesController) do
      with_request_url "/console/file/images" do
        file_klass = Folio::File::Image

        render_inline(Folio::Console::Files::Batch::BarComponent.new(file_klass:))

        assert_selector(".f-c-files-batch-bar", visible: false)
      end
    end
  end
end
