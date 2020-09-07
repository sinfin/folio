# frozen_string_literal: true

require "test_helper"

class Folio::Console::Index::ImagesCellTest < Folio::Console::CellTest
  test "show" do
    page = create(:folio_page)
    image = create(:folio_image)
    page.cover = image
    page.images << image
    page.images << image
    page.images << image
    page.images << image
    html = cell("folio/console/index/images", page).(:show)
    assert_equal 3, html.find_all(".f-c-index-images__item").size

    html = cell("folio/console/index/images", page, cover: true).(:show)
    assert_equal 1, html.find_all(".f-c-index-images__item").size
  end
end
