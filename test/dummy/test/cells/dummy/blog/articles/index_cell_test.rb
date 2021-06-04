# frozen_string_literal: true

require "test_helper"

class Dummy::Blog::Articles::IndexCellTest < Cell::TestCase
  test "show" do
    html = cell("dummy/blog/articles/index", nil).(:show)
    assert html.has_css?(".d-blog-articles-index")
  end
end
