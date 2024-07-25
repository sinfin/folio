# frozen_string_literal: true

require "test_helper"

class Dummy::Blog::AuthorsControllerTest < Folio::BaseControllerTest
  test "show" do
    create_page_singleton(Dummy::Page::Blog::Articles::Index)

    author = create(:dummy_blog_author)
    get url_for(author)
    assert_response :ok
    assert_select(".d-blog-articles-card", 0)

    create(:dummy_blog_article, authors: [author])

    get url_for(author)
    assert_response :ok
    assert_select(".d-blog-articles-card")

    author.update!(published: false)

    assert_raises(ActiveRecord::RecordNotFound) { get url_for(author) }

    get url_for([author, Folio::Publishable::PREVIEW_PARAM_NAME => author.preview_token])
    assert_response(:ok)
  end
end
