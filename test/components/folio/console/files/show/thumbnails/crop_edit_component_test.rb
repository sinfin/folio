# frozen_string_literal: true

require "test_helper"

class Folio::Console::Files::Show::Thumbnails::CropEditComponentTest < Folio::Console::ComponentTest
  def test_render
    with_controller_class(Folio::Console::File::ImagesController) do
      with_request_url "/console/file/images" do
        file = create(:folio_file_image)

        thumbnail_size_keys = [
          Folio::Console::FileSerializer::ADMIN_THUMBNAIL_SIZE,
          Folio::Console::FileSerializer::ADMIN_RETINA_THUMBNAIL_SIZE
        ]

        render_inline(Folio::Console::Files::Show::Thumbnails::CropEditComponent.new(file:,
                                                                                     ratio: "1:1",
                                                                                     thumbnail_size_keys:))

        assert_selector(".f-c-files-show-thumbnails-crop-edit")
      end
    end
  end
end
