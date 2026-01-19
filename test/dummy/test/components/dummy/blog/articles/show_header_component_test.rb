# frozen_string_literal: true

require Folio::Engine.root.join("test/test_helper")

class Dummy::Blog::Articles::ShowHeaderComponentTest < Folio::ComponentTest
  def test_render
    create_and_host_site

    article = create(:dummy_blog_article)

    render_inline(Dummy::Blog::Articles::ShowHeaderComponent.new(article:))

    assert_selector(".d-blog-articles-show-header")
  end

  def test_render_with_topics
    create_and_host_site

    article = create(:dummy_blog_article)
    article.topics << create(:dummy_blog_topic)

    render_inline(Dummy::Blog::Articles::ShowHeaderComponent.new(article:))

    assert_selector(".d-blog-articles-show-header")
  end
end
