# frozen_string_literal: true

require Folio::Engine.root.join("test/test_helper")

class Dummy::Blog::ArticlesControllerTest < Folio::BaseControllerTest
  test "index" do
    create_page_singleton(Dummy::Page::Blog::Articles::Index)
    get url_for(Dummy::Blog::Article)
    assert_response :ok

    create(:dummy_blog_article)
    get url_for(Dummy::Blog::Article)
    assert_response :ok
  end

  test "show" do
    create_page_singleton(Dummy::Page::Blog::Articles::Index)
    article = create(:dummy_blog_article)
    get url_for(article)
    assert_response :ok

    article.update!(published: false)

    assert_raises(ActiveRecord::RecordNotFound) { get url_for(article) }

    get url_for([article, Folio::Publishable::PREVIEW_PARAM_NAME => article.preview_token])
    assert_response(:ok)
  end
end
