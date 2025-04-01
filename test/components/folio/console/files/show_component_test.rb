# frozen_string_literal: true

require "test_helper"

class Folio::Console::Files::ShowComponentTest < Folio::Console::ComponentTest
  def test_render
    with_controller_class(Folio::Console::File::ImagesController) do
      with_request_url "/console/file/images" do
        file = create(:folio_file_image)

        render_inline(Folio::Console::Files::ShowComponent.new(file:))

        assert_selector(".f-c-files-show")
      end
    end
  end
end
