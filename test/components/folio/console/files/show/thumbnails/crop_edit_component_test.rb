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

  test "renders the tile thumbnail with a crop trigger and full-screen modal shell" do
    superadmin = create(:folio_user, :superadmin)
    Folio::Current.user = superadmin
    Folio::Current.reset_ability!

    with_controller_class(Folio::Console::File::ImagesController) do
      with_request_url "/console/file/images" do
        file = create(:folio_file_image, file_width: 1200, file_height: 800)
        render_inline(Folio::Console::Files::Show::Thumbnails::CropEditComponent.new(
          file:, ratio: "2:1", ratio_label: "2×1", thumbnail_size_keys: %w[200x100#]))

        assert_selector ".f-c-files-show-thumbnails-crop-edit__thumb"
        assert_selector ".f-c-files-show-thumbnails-crop-edit__crop-btn"
        assert_selector "dialog.f-c-files-show-thumbnails-crop-edit__overlay[data-f-c-files-show-thumbnails-crop-edit-target='overlay']"
        assert_selector ".f-c-files-show-thumbnails-crop-edit__backdrop"
        assert_selector ".f-c-files-show-thumbnails-crop-edit__modal"
        assert_selector ".f-c-files-show-thumbnails-crop-edit__contain .f-c-files-show-thumbnails-crop-edit__image"
        assert_selector ".f-c-files-show-thumbnails-crop-edit__buttons [data-action*='#saveEditing']", text: "Uložit"
        assert_selector ".f-c-files-show-thumbnails-crop-edit__buttons .btn-medium-dark", text: "Zrušit"
        assert_selector ".f-c-files-show-thumbnails-crop-edit__close[title='Zavřít']"
      end
    end
  ensure
    Folio::Current.user = nil
  end

  test "passes the ratio and stored image-relative crop to the editor" do
    with_controller_class(Folio::Console::File::ImagesController) do
      with_request_url "/console/file/images" do
        file = create(:folio_file_image,
                      thumbnail_configuration: {
                        "ratios" => {
                          "2:1" => {
                            "crop" => {
                              "x" => 0.25,
                              "y" => 0.125
                            }
                          }
                        }
                      })

        render_inline(Folio::Console::Files::Show::Thumbnails::CropEditComponent.new(
          file:, ratio: "2:1", ratio_label: "2×1", thumbnail_size_keys: %w[200x100#]))

        root = Nokogiri::HTML.fragment(rendered_content).at_css(".f-c-files-show-thumbnails-crop-edit")
        cropper_data = JSON.parse(root["data-f-c-files-show-thumbnails-crop-edit-cropper-data-value"])
        api_data = JSON.parse(root["data-f-c-files-show-thumbnails-crop-edit-api-data-value"])

        assert_equal({ "aspect_ratio" => 2.0, "x" => 0.25, "y" => 0.125 }, cropper_data)
        assert_equal({ "ratio" => "2:1", "thumbnail_size_keys" => ["200x100#"] }, api_data)
        assert_includes root["data-f-c-files-show-thumbnails-crop-edit-api-url-value"], "action=update_thumbnails_crop"
      end
    end
  end

  test "centers an uncropped landscape image when gravity is unset" do
    file = image_with_dimensions(width: 1200, height: 800)

    cropper_data = render_cropper_data(file:)

    assert_in_delta 1.0 / 6, cropper_data["x"]
    assert_equal 0.0, cropper_data["y"]
  end

  test "centers an uncropped portrait image when gravity is unset" do
    file = image_with_dimensions(width: 800, height: 1200)

    cropper_data = render_cropper_data(file:)

    assert_equal 0.0, cropper_data["x"]
    assert_in_delta 1.0 / 6, cropper_data["y"]
  end

  test "aligns an uncropped landscape image east" do
    file = image_with_dimensions(width: 1200, height: 800, gravity: "east")

    cropper_data = render_cropper_data(file:)

    assert_in_delta 1.0 / 3, cropper_data["x"]
    assert_equal 0.0, cropper_data["y"]
  end

  test "aligns an uncropped landscape image west" do
    file = image_with_dimensions(width: 1200, height: 800, gravity: "west")

    cropper_data = render_cropper_data(file:)

    assert_equal 0.0, cropper_data["x"]
    assert_equal 0.0, cropper_data["y"]
  end

  test "aligns an uncropped portrait image north" do
    file = image_with_dimensions(width: 800, height: 1200, gravity: "north")

    cropper_data = render_cropper_data(file:)

    assert_equal 0.0, cropper_data["x"]
    assert_equal 0.0, cropper_data["y"]
  end

  test "aligns an uncropped portrait image south" do
    file = image_with_dimensions(width: 800, height: 1200, gravity: "south")

    cropper_data = render_cropper_data(file:)

    assert_equal 0.0, cropper_data["x"]
    assert_in_delta 1.0 / 3, cropper_data["y"]
  end

  test "keeps an uncropped selection at the origin when the image already matches the ratio" do
    file = image_with_dimensions(width: 800, height: 800, gravity: "east")

    cropper_data = render_cropper_data(file:)

    assert_equal 0.0, cropper_data["x"]
    assert_equal 0.0, cropper_data["y"]
  end

  test "detail variant keeps a fixed-width preview with the crop ratio" do
    with_controller_class(Folio::Console::File::ImagesController) do
      with_request_url "/console/file/images" do
        file = create(:folio_file_image)

        render_inline(Folio::Console::Files::Show::Thumbnails::CropEditComponent.new(
          file:, ratio: "2:1", ratio_label: "2×1", thumbnail_size_keys: %w[200x100#], variant: :detail))

        assert_selector(".f-c-files-show-thumbnails-crop-edit--detail .f-c-files-show-thumbnails-crop-edit__thumb[style='aspect-ratio: 2 / 1;']")
      end
    end
  end

  private
    def image_with_dimensions(width:, height:, gravity: nil)
      create(:folio_file_image).tap do |file|
        file.update_columns(file_width: width,
                            file_height: height,
                            default_gravity: gravity)
      end
    end

    def render_cropper_data(file:, ratio: "1:1")
      with_controller_class(Folio::Console::File::ImagesController) do
        with_request_url "/console/file/images" do
          render_inline(Folio::Console::Files::Show::Thumbnails::CropEditComponent.new(
            file:, ratio:, ratio_label: ratio.tr(":", "×"), thumbnail_size_keys: ["100x100#"]))

          root = Nokogiri::HTML.fragment(rendered_content).at_css(".f-c-files-show-thumbnails-crop-edit")
          JSON.parse(root["data-f-c-files-show-thumbnails-crop-edit-cropper-data-value"])
        end
      end
    end
end
