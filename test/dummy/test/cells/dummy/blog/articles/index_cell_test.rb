# frozen_string_literal: true

require "test_helper"

class Dummy::Blog::Articles::IndexCellTest < Cell::TestCase
  test "show" do
    model = create_list(:dummy_blog_article, 4)
    html = cell("dummy/blog/articles/index", [model[0]]).(:show)
    assert html.has_css?(".d-blog-articles-index")

    html = cell("dummy/blog/articles/index", model[0..1]).(:show)
    assert html.has_css?(".d-blog-articles-index")

    html = cell("dummy/blog/articles/index", model).(:show)
    assert html.has_css?(".d-blog-articles-index")
  end
end
