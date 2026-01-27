# frozen_string_literal: true

require Folio::Engine.root.join("test/test_helper")

class Dummy::Blog::Articles::CardComponentTest < Folio::ComponentTest
  def test_render
    create_and_host_site

    article = create(:dummy_blog_article)

    render_inline(Dummy::Blog::Articles::CardComponent.new(article:))

    assert_selector(".d-blog-articles-card")
  end
end
