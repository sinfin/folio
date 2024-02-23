# frozen_string_literal: true

require "test_helper"

class Dummy::Blog::Articles::CardsComponentTest < Folio::ComponentTest
  def test_render
    create_and_host_site

    articles = create_list(:dummy_blog_article, 1)

    render_inline(Dummy::Blog::Articles::CardsComponent.new(articles:))

    assert_selector(".d-blog-articles-cards")
  end
end
