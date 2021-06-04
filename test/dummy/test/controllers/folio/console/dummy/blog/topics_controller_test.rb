# frozen_string_literal: true

require "test_helper"

class Folio::Console::Dummy::Blog::TopicsControllerTest < Folio::Console::BaseControllerTest
  test "index" do
    get url_for([:console, Dummy::Blog::Topic])

    assert_response :success

    create(:dummy_blog_category)

    get url_for([:console, Dummy::Blog::Topic])

    assert_response :success
  end

  test "new" do
    get url_for([:console, Dummy::Blog::Topic, action: :new])

    assert_response :success
  end

  test "edit" do
    model = create(:dummy_blog_category)

    get url_for([:edit, :console, model])

    assert_response :success
  end

  test "create" do
    params = build(:dummy_blog_category).serializable_hash
    assert_equal(0, Dummy::Blog::Topic.count)

    post url_for([:console, Dummy::Blog::Topic]), params: {
      dummy_blog_category: params,
    }

    assert_equal(1, Dummy::Blog::Topic.count, "Creates record")
  end

  test "update" do
    model = create(:dummy_blog_category)
    assert_not_equal("Title", model.title)

    put url_for([:console, model]), params: {
      dummy_blog_category: {
        title: "Title",
      },
    }

    assert_redirected_to url_for([:edit, :console, model])
    assert_equal("Title", model.reload.title)
  end

  test "destroy" do
    model = create(:dummy_blog_category)

    delete url_for([:console, model])

    assert_redirected_to url_for([:console, Dummy::Blog::Topic])
    assert_not(Dummy::Blog::Topic.exists?(id: model.id))
  end
end
