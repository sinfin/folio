# frozen_string_literal: true

require "test_helper"

class Dummy::Blog::Articles::ShowBodyComponentTest < Folio::ComponentTest
  def test_render
    create_and_host_site

    article = create(:dummy_blog_article)
    recommended_articles = create_list(:dummy_blog_article, 1)

    render_inline(Dummy::Blog::Articles::ShowBodyComponent.new(article:, recommended_articles:))

    assert_selector(".d-blog-articles-show-body")
  end
end
