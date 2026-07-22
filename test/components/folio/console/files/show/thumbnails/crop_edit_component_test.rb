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
                                                                                     ratio_label: "1×1",
                                                                                     thumbnail_size_keys:))

        assert_selector(".f-c-files-show-thumbnails-crop-edit")
      end
    end
  end

  test "renders the tile thumbnail with a crop trigger and an overlay holding the editor" do
    superadmin = create(:folio_user, :superadmin)
    Folio::Current.user = superadmin
    Folio::Current.reset_ability!

    with_controller_class(Folio::Console::File::ImagesController) do
      with_request_url "/console/file/images" do
        file = create(:folio_file_image, file_width: 1200, file_height: 800)
        render_inline(Folio::Console::Files::Show::Thumbnails::CropEditComponent.new(
          file:, ratio: "2:1", ratio_label: "2×1", thumbnail_size_keys: %w[200x100#]))

        # the tile box and its corner crop trigger
        assert_selector ".f-c-files-show-thumbnails-crop-edit__thumb"
        assert_selector ".f-c-files-show-thumbnails-crop-edit__crop-btn"
        # editor lives inside an overlay/modal container
        assert_selector ".f-c-files-show-thumbnails-crop-edit__overlay [data-f-c-files-show-thumbnails-crop-edit-target='editorImage']"
      end
    end
  ensure
    Folio::Current.user = nil
  end
end
