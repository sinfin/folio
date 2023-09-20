# frozen_string_literal: true

require "test_helper"

class Folio::ImageCellTest < Cell::TestCase
  def size
    Folio::Console::FileSerializer::ADMIN_THUMBNAIL_SIZE
  end

  test "show" do
    html = cell("folio/image", nil).(:show)
    assert_not html.has_css?(".f-image")

    html = cell("folio/image", nil, size:).(:show)
    assert html.has_css?(".f-image")
    assert html.has_css?(".f-image__fallback")

    placement = create(:folio_image_placement)
    html = cell("folio/image", placement).(:show)
    assert_not html.has_css?(".f-image")

    html = cell("folio/image", placement, size:).(:show)
    assert html.has_css?(".f-image")
    assert_not html.has_css?(".f-image__fallback")
    assert html.has_css?(".f-image__img")

    html = cell("folio/image", placement, size:, lightbox: true).(:show)
    assert html.has_css?(".f-image--lightboxable")
    assert html.has_css?(".f-image[data-lightbox-src]")
  end

  test "alt" do
    placement = create(:folio_image_placement)
    option_alt = "option_alt"

    html = cell("folio/image", placement, size:, alt: option_alt).(:show)
    assert html.has_css?(".f-image__img[data-alt='option_alt']")

    placement.file.update(description: "file_description")
    html = cell("folio/image", placement, size:).(:show)
    assert html.has_css?(".f-image__img[data-alt='file_description']")

    placement.update(description: "file_placement_description")
    html = cell("folio/image", placement, size:).(:show)
    assert html.has_css?(".f-image__img[data-alt='file_placement_description']")

    html = cell("folio/image", placement, size:, alt: option_alt).(:show)
    assert html.has_css?(".f-image__img[data-alt='option_alt']")

    placement.file.update(alt: "file_alt")
    html = cell("folio/image", placement, size:).(:show)
    assert html.has_css?(".f-image__img[data-alt='file_alt']")

    placement.update(alt: "file_placement_alt")
    html = cell("folio/image", placement, size:).(:show)
    assert html.has_css?(".f-image__img[data-alt='file_placement_alt']")

    html = cell("folio/image", placement, size:, alt: option_alt).(:show)
    assert html.has_css?(".f-image__img[data-alt='option_alt']")
  end
end
