# frozen_string_literal: true

require Folio::Engine.root.join("test/test_helper")

class Dummy::Blog::Articles::IndexComponentTest < Folio::ComponentTest
  def test_render
    create_and_host_site

    render_inline(Dummy::Blog::Articles::IndexComponent.new)

    assert_selector(".d-blog-articles-index")
    assert_no_selector(".d-blog-articles-card")

    create_list(:dummy_blog_article, 1)

    render_inline(Dummy::Blog::Articles::IndexComponent.new)

    assert_selector(".d-blog-articles-index")
    assert_selector(".d-blog-articles-card")
  end
end
