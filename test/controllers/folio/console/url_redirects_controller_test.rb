# frozen_string_literal: true

require "test_helper"

class Folio::Console::UrlRedirectsControllerTest < Folio::Console::BaseControllerTest
  test "index" do
    get url_for([:console, Folio::UrlRedirect])

    assert_response :success

    create(:folio_url_redirect)

    get url_for([:console, Folio::UrlRedirect])

    assert_response :success
  end

  test "new" do
    get url_for([:console, Folio::UrlRedirect, action: :new])

    assert_response :success
  end

  test "edit" do
    model = create(:folio_url_redirect)

    get url_for([:edit, :console, model])

    assert_response :success
  end

  test "create" do
    params = build(:folio_url_redirect).serializable_hash

    assert_difference("Folio::UrlRedirect.count", 1) do
      post url_for([:console, Folio::UrlRedirect]), params: {
        folio_url_redirect: params,
      }
    end
  end

  test "update" do
    model = create(:folio_url_redirect)
    assert_not_equal("Title", model.title)

    put url_for([:console, model]), params: {
      folio_url_redirect: {
        title: "Title",
      },
    }

    assert_redirected_to url_for([:edit, :console, model])
    assert_equal("Title", model.reload.title)
  end

  test "destroy" do
    model = create(:folio_url_redirect)

    delete url_for([:console, model])

    assert_redirected_to url_for([:console, Folio::UrlRedirect])
    assert_not(Folio::UrlRedirect.exists?(id: model.id))
  end
end
