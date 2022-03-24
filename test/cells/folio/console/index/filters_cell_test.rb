# frozen_string_literal: true

require "test_helper"

class Folio::Console::Index::FiltersCellTest < Folio::Console::CellTest
  test "show" do
    index_filters = {
      by_published: [
        ["All", nil],
        ["Published", "published"],
        ["Unpublished", "unpublished"],
      ]
    }
    html = cell("folio/console/index/filters", index_filters:,
                                               klass: Folio::Page).(:show)

    assert_equal 1,
                 html.find_css('input[type="hidden"][name="by_query"]').length
    assert_equal 1,
                 html.find_css('select[name="by_published"]').length
  end
end
