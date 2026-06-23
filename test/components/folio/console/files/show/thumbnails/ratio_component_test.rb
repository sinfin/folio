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
                                                                                  thumbnail_size_keys:))

        assert_selector(".f-c-files-show-thumbnails-ratio")
      end
    end
  end

  test "collapsed card shows label fallback (ratio), variant count, and a collapsed detail" do
    with_controller_class(Folio::Console::File::ImagesController) do
      with_request_url "/console/file/images" do
        file = create(:folio_file_image)
        render_inline(Folio::Console::Files::Show::Thumbnails::RatioComponent.new(
          file:, ratio: "2:1", thumbnail_size_keys: %w[200x100# 400x200#]))

        # summary
        assert_selector ".f-c-files-show-thumbnails-ratio__summary"
        assert_text "2:1"                      # label fallback (hook returns nil)
        assert_text "2"                        # variant count
        # representative thumbnail preview in summary
        assert_selector ".f-c-files-show-thumbnails-ratio__summary-thumbnail"
        # detail collapsed by default (native <details> without `open`)
        assert_selector "details.f-c-files-show-thumbnails-ratio__detail"
        assert_no_selector "details.f-c-files-show-thumbnails-ratio__detail[open]"
        assert_selector "summary.f-c-files-show-thumbnails-ratio__detail-summary",
                        text: I18n.t("folio.console.files.show.thumbnails.ratio_component.show_all_thumbnails")
      end
    end
  end

  test "regular group renders no crop editor" do
    with_controller_class(Folio::Console::File::ImagesController) do
      with_request_url "/console/file/images" do
        file = create(:folio_file_image)
        render_inline(Folio::Console::Files::Show::Thumbnails::RatioComponent.new(
          file:, ratio: "regular", thumbnail_size_keys: %w[250x250 500x500]))
        assert_no_selector ".f-c-files-show-thumbnails-crop-edit"
      end
    end
  end
end
