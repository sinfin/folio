# frozen_string_literal: true

require "test_helper"

class Dummy::Blog::Articles::ShowCellTest < Cell::TestCase
  test "show" do
    model = create(:dummy_blog_article)
    html = cell("dummy/blog/articles/show", model).(:show)
    assert html.has_css?(".d-blog-articles-show")
  end
end
