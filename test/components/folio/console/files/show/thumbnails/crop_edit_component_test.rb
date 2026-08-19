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
        assert_equal({ "group_type" => "crop", "ratio" => "2:1" }, api_data)
      end
    end
  end

  test "passes the main crop group type to the API" do
    with_controller_class(Folio::Console::File::ImagesController) do
      with_request_url "/console/file/images" do
        file = create(:folio_file_image)

        render_inline(Folio::Console::Files::Show::Thumbnails::CropEditComponent.new(
          file:,
          ratio: "16:9",
          ratio_label: "16×9",
          thumbnail_size_keys: %w[200x120# 400x250# 800x450#],
          group_type: "main_crop"))

        root = Nokogiri::HTML.fragment(rendered_content).at_css(".f-c-files-show-thumbnails-crop-edit")
        api_data = JSON.parse(root["data-f-c-files-show-thumbnails-crop-edit-api-data-value"])

        assert_equal({ "group_type" => "main_crop", "ratio" => "16:9" }, api_data)
      end
    end
  end

  test "uses an exact-ratio thumbnail for a main crop preview" do
    with_controller_class(Folio::Console::File::ImagesController) do
      with_request_url "/console/file/images" do
        file = create(:folio_file_image)
        file.update!(thumbnail_sizes: {
          "400x300#" => { url: "https://example.com/exact.jpg" },
          "480x320#" => { url: "https://example.com/larger.jpg" },
        })

        render_inline(Folio::Console::Files::Show::Thumbnails::CropEditComponent.new(
          file:,
          ratio: "4:3",
          ratio_label: "4×3",
          thumbnail_size_keys: %w[400x300# 480x320#],
          group_type: "main_crop"))

        assert_selector ".f-c-files-show-thumbnails-crop-edit__thumb-img[src='https://example.com/exact.jpg']"
      end
    end
  end

  test "renders a loading main preview for a pending family without an empty state" do
    with_controller_class(Folio::Console::File::ImagesController) do
      with_request_url "/console/file/images" do
        file = create(:folio_file_image)
        file.update!(thumbnail_sizes: {
          "100x50#" => pending_thumbnail(file, "100x50#"),
          "240x120#" => pending_thumbnail(file, "240x120#"),
        })

        render_inline(Folio::Console::Files::Show::Thumbnails::CropEditComponent.new(
          file:,
          ratio: "2:1",
          ratio_label: "2×1",
          thumbnail_size_keys: %w[100x50# 240x120#],
          group_type: "main_crop"))

        root = Nokogiri::HTML.fragment(rendered_content).at_css(".f-c-files-show-thumbnails-crop-edit")
        candidates = JSON.parse(root["data-f-c-files-show-thumbnails-crop-edit-preview-candidates-value"])

        assert_selector(".f-c-files-show-thumbnails-crop-edit__thumb-img[hidden]", visible: :all)
        assert_no_selector(".f-c-files-show-thumbnails-crop-edit__thumb-empty")
        assert_no_selector(".f-c-files-show-thumbnails-crop-edit__thumb-img[data-controller~='f-thumbnail']",
                           visible: :all)
        assert_equal ["240x120#"], candidates.pluck("size")
      end
    end
  end

  test "shows a ready main preview while waiting for a better candidate" do
    with_controller_class(Folio::Console::File::ImagesController) do
      with_request_url "/console/file/images" do
        file = create(:folio_file_image)
        file.update!(thumbnail_sizes: {
          "240x120#" => { uid: "ready", url: "https://example.com/ready.jpg" },
          "480x240#" => pending_thumbnail(file, "480x240#"),
        })

        render_inline(Folio::Console::Files::Show::Thumbnails::CropEditComponent.new(
          file:,
          ratio: "2:1",
          ratio_label: "2×1",
          thumbnail_size_keys: %w[240x120# 480x240#],
          group_type: "main_crop"))

        root = Nokogiri::HTML.fragment(rendered_content).at_css(".f-c-files-show-thumbnails-crop-edit")
        candidates = JSON.parse(root["data-f-c-files-show-thumbnails-crop-edit-preview-candidates-value"])

        assert_selector(".f-c-files-show-thumbnails-crop-edit__thumb-img[src='https://example.com/ready.jpg']:not([hidden])")
        assert_equal %w[480x240# 240x120#], candidates.pluck("size")
        assert_equal [true, false], candidates.pluck("pending")
      end
    end
  end

  test "serializes the configured crop for matching main preview events" do
    with_controller_class(Folio::Console::File::ImagesController) do
      with_request_url "/console/file/images" do
        file = create(:folio_file_image)
        file.update!(
          thumbnail_configuration: {
            "ratios" => { "2:1" => { "crop" => { "x" => 0.2, "y" => 0.3 } } }
          },
          thumbnail_sizes: {
            "240x120#" => pending_thumbnail(file, "240x120#"),
          }
        )

        render_inline(Folio::Console::Files::Show::Thumbnails::CropEditComponent.new(
          file:,
          ratio: "2:1",
          ratio_label: "2×1",
          thumbnail_size_keys: %w[240x120#],
          group_type: "main_crop"))

        root = Nokogiri::HTML.fragment(rendered_content).at_css(".f-c-files-show-thumbnails-crop-edit")
        preview_crop = JSON.parse(root["data-f-c-files-show-thumbnails-crop-edit-preview-crop-value"])

        assert_equal({ "x" => 0.2, "y" => 0.3 }, preview_crop)
        assert_equal file.id.to_s,
                     root["data-f-c-files-show-thumbnails-crop-edit-file-id-value"]
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
    def pending_thumbnail(file, size)
      {
        uid: nil,
        url: file.temporary_url(size),
      }
    end

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
