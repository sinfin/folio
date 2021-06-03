# frozen_string_literal: true

require "test_helper"

class Folio::Console::Dummy::Blog::ArticlesControllerTest < Folio::Console::BaseControllerTest
  test "index" do
    get url_for([:console, Dummy::Blog::Article])

    assert_response :success

    create(:dummy_blog_article)

    get url_for([:console, Dummy::Blog::Article])

    assert_response :success
  end

  test "new" do
    get url_for([:console, Dummy::Blog::Article, action: :new])

    assert_response :success
  end

  test "edit" do
    model = create(:dummy_blog_article)

    get url_for([:edit, :console, model])

    assert_response :success
  end

  test "create" do
    params = build(:dummy_blog_article).serializable_hash
    assert_equal(0, Dummy::Blog::Article.count)

    post url_for([:console, Dummy::Blog::Article]), params: {
      dummy_blog_article: params,
    }

    assert_equal(1, Dummy::Blog::Article.count, "Creates record")
  end

  test "update" do
    model = create(:dummy_blog_article)
    assert_not_equal("Title", model.title)

    put url_for([:console, model]), params: {
      dummy_blog_article: {
        title: "Title",
      },
    }

    assert_redirected_to url_for([:edit, :console, model])
    assert_equal("Title", model.reload.title)
  end

  test "destroy" do
    model = create(:dummy_blog_article)

    delete url_for([:console, model])

    assert_redirected_to url_for([:console, Dummy::Blog::Article])
    assert_not(Dummy::Blog::Article.exists?(id: model.id))
  end
end
