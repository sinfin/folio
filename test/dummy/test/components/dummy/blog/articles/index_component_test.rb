# frozen_string_literal: true

require "test_helper"

class Dummy::Blog::Articles::IndexComponentTest < Folio::ComponentTest
  def test_render
    create_and_host_site

    articles = create_list(:dummy_blog_article, 1)

    render_inline(Dummy::Blog::Articles::IndexComponent.new(articles:))

    assert_selector(".d-blog-articles-index")
  end
end
