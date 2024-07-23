# frozen_string_literal: true

require "test_helper"

class Folio::Console::Dummy::Blog::AuthorsControllerTest < Folio::Console::BaseControllerTest
  test "index" do
    get url_for([:console, Dummy::Blog::Author])

    assert_response :success

    create(:dummy_blog_author)

    get url_for([:console, Dummy::Blog::Author])

    assert_response :success
  end

  test "new" do
    get url_for([:console, Dummy::Blog::Author, action: :new])

    assert_response :success
  end

  test "edit" do
    model = create(:dummy_blog_author)

    get url_for([:edit, :console, model])

    assert_response :success
  end

  test "create" do
    params = build(:dummy_blog_author).serializable_hash

    assert_difference("Dummy::Blog::Author.count", 1) do
      post url_for([:console, Dummy::Blog::Author]), params: {
        dummy_blog_author: params,
      }
    end
  end

  test "update" do
    model = create(:dummy_blog_author)
    assert_not_equal("Title", model.last_name)

    put url_for([:console, model]), params: {
      dummy_blog_author: {
        last_name: "Title",
      },
    }

    assert_redirected_to url_for([:edit, :console, model])
    assert_equal("Title", model.reload.last_name)
  end

  test "destroy" do
    model = create(:dummy_blog_author)

    delete url_for([:console, model])

    assert_redirected_to url_for([:console, Dummy::Blog::Author])
    assert_not(Dummy::Blog::Author.exists?(id: model.id))
  end
end
