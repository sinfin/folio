# frozen_string_literal: true

require "test_helper"

class Folio::Console::Files::Show::Thumbnails::RatioComponentTest < Folio::Console::ComponentTest
  def test_render
    with_controller_class(Folio::Console::File::ImagesController) do
      with_request_url "/console/file/images" do
        file = create(:folio_file_image)

        thumbnail_size_keys = [
          Folio::Console::FileSerializer::ADMIN_THUMBNAIL_SIZE,
          Folio::Console::FileSerializer::ADMIN_RETINA_THUMBNAIL_SIZE
        ]

        render_inline(Folio::Console::Files::Show::Thumbnails::RatioComponent.new(file:,
                                                                                  ratio: "1:1",
                                                                                  ratio_label: "1×1",
                                                                                  thumbnail_size_keys:))

        assert_selector('.f-c-files-show-thumbnails-ratio[data-ratio="1:1"]')
      end
    end
  end

  test "tile shows the ratio label and a crop editor, without summary/count/per-tile disclosure" do
    with_controller_class(Folio::Console::File::ImagesController) do
      with_request_url "/console/file/images" do
        file = create(:folio_file_image)
        render_inline(Folio::Console::Files::Show::Thumbnails::RatioComponent.new(
          file:, ratio: "2:1", ratio_label: "2×1", thumbnail_size_keys: %w[200x100# 400x200#]))

        assert_selector ".f-c-files-show-thumbnails-ratio__label", text: "2×1"
        # the crop editor tile is rendered
        assert_selector ".f-c-files-show-thumbnails-crop-edit"

        # the old summary / variant count / per-tile disclosure are gone
        assert_no_selector ".f-c-files-show-thumbnails-ratio__summary"
        assert_no_selector "details.f-c-files-show-thumbnails-ratio__detail"
      end
    end
  end
end
