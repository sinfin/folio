# frozen_string_literal: true

require "test_helper"

class Folio::Console::Files::Show::Thumbnails::Ratio::ThumbnailComponentTest < Folio::Console::ComponentTest
  def test_render
    thumbnail = { uid: "foo/bar/baz.jpg", signature: "123456", url: "https://a/b/c/d.jpg", width: 250, height: 167, quality: 82, x: nil, y: nil, private: false, gravity: nil, webp_uid: "https://a/b/c/d.webp", webp_url: "https://a/b/c/d.webp", webp_signature: "654321" }

    render_inline(Folio::Console::Files::Show::Thumbnails::Ratio::ThumbnailComponent.new(thumbnail:,
                                                                                         thumbnail_size_key: "250x167#",
                                                                                         file: create(:folio_file_image)))

    assert_selector(".f-c-files-show-thumbnails-ratio-thumbnail")
  end

  test "renders a temporary webp variant while a crop is regenerating" do
    file = create(:folio_file_image)
    thumbnail_size_key = "250x167#"
    thumbnail = {
      url: file.temporary_url(thumbnail_size_key),
      webp_url: file.temporary_url("#{thumbnail_size_key}.webp")
    }

    render_inline(Folio::Console::Files::Show::Thumbnails::Ratio::ThumbnailComponent.new(
      thumbnail:, thumbnail_size_key:, file:, variant: :detail))

    assert_selector(".f-c-files-show-thumbnails-ratio-thumbnail__extension", text: "JPG")
    assert_selector(".f-c-files-show-thumbnails-ratio-thumbnail__extension", text: "WEBP")
  end

  test "detail variant fits a landscape thumbnail within 100 pixels" do
    thumbnail = { url: "https://a/b/c/d.jpg" }

    render_inline(Folio::Console::Files::Show::Thumbnails::Ratio::ThumbnailComponent.new(
      thumbnail:, thumbnail_size_key: "250x167#", file: create(:folio_file_image), variant: :detail))

    assert_selector(".f-c-files-show-thumbnails-ratio-thumbnail--detail")
    assert_selector(".f-c-files-show-thumbnails-ratio-thumbnail__img-wrap[style='width: 100px; height: 66.8px;']")
    assert_selector(".f-c-files-show-thumbnails-ratio-thumbnail__extension", text: "JPG")
    assert_selector(".f-c-files-show-thumbnails-ratio-thumbnail__dimensions", text: "250×167px")
  end

  test "detail variant fits a portrait thumbnail within 100 pixels" do
    thumbnail = { url: "https://a/b/c/d.jpg" }

    render_inline(Folio::Console::Files::Show::Thumbnails::Ratio::ThumbnailComponent.new(
      thumbnail:, thumbnail_size_key: "400x800#", file: create(:folio_file_image), variant: :detail))

    assert_selector(".f-c-files-show-thumbnails-ratio-thumbnail__img-wrap[style='width: 50px; height: 100px;']")
  end

  test "detail variant enlarges a small crop thumbnail" do
    thumbnail = { url: "https://a/b/c/d.jpg", width: 40, height: 40 }

    render_inline(Folio::Console::Files::Show::Thumbnails::Ratio::ThumbnailComponent.new(
      thumbnail:, thumbnail_size_key: "40x40#", file: create(:folio_file_image), variant: :detail))

    assert_selector(".f-c-files-show-thumbnails-ratio-thumbnail__img-wrap[style='width: 100px; height: 100px;']")
  end

  test "detail variant enlarges a small forced-gravity crop thumbnail" do
    thumbnail = { url: "https://a/b/c/d.jpg", width: 40, height: 40 }

    render_inline(Folio::Console::Files::Show::Thumbnails::Ratio::ThumbnailComponent.new(
      thumbnail:, thumbnail_size_key: "40x40#c", file: create(:folio_file_image), variant: :detail))

    assert_selector(".f-c-files-show-thumbnails-ratio-thumbnail__img-wrap[style='width: 100px; height: 100px;']")
  end

  test "detail variant uses the generated thumbnail dimensions" do
    thumbnail = { url: "https://a/b/c/d.jpg", width: 400, height: 600 }

    render_inline(Folio::Console::Files::Show::Thumbnails::Ratio::ThumbnailComponent.new(
      thumbnail:, thumbnail_size_key: "400x400#", file: create(:folio_file_image), variant: :detail))

    assert_selector(".f-c-files-show-thumbnails-ratio-thumbnail__img-wrap[style='width: 66.67px; height: 100px;']")
  end

  test "detail variant falls back to the regular file dimensions" do
    file = create(:folio_file_image)
    file.update_columns(file_width: 400, file_height: 600)

    render_inline(Folio::Console::Files::Show::Thumbnails::Ratio::ThumbnailComponent.new(
      thumbnail: { url: "https://a/b/c/d.jpg" }, thumbnail_size_key: "400x400", file:, variant: :detail))

    assert_selector(".f-c-files-show-thumbnails-ratio-thumbnail__img-wrap[style='width: 66.67px; height: 100px;']")
  end
end
