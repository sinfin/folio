# frozen_string_literal: true

require "test_helper"

class Dummy::Blog::ArticlesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    create(:folio_site)
  end

  test "index" do
    get url_for(Dummy::Blog::Article)
    assert_response :ok

    create(:dummy_blog_article)
    get url_for(Dummy::Blog::Article)
    assert_response :ok
  end

  test "show" do
    article = create(:dummy_blog_article)
    get url_for(article)
    assert_response :ok

    article.update!(published: false)

    assert_raises(ActiveRecord::RecordNotFound) { get url_for(article) }

    sign_in create(:folio_admin_account)
    get url_for(article)
    assert_redirected_to url_for([:preview, article])
  end

  test "preview" do
    article = create(:dummy_blog_article, published: false)
    assert_raises(ActiveRecord::RecordNotFound) { get url_for([:preview, article]) }

    admin = create(:folio_admin_account)
    sign_in admin
    get url_for([:preview, article])

    article.update!(published: true)
    sign_in admin
    get url_for([:preview, article])
    assert_redirected_to url_for(article)
  end
end
