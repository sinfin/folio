# frozen_string_literal: true

require "test_helper"

class Folio::EmbedMiddlewareTest < ActionDispatch::IntegrationTest
  test "renders embed HTML for /folio/embed path" do
    create_and_host_site

    get "/folio/embed"

    assert_response :ok
    assert_equal "text/html", response.headers["Content-Type"]
    assert response.headers["ETag"].present?, "ETag header should be present"
    assert_not_empty response.body
  end

  test "ETag is cached between requests" do
    create_and_host_site

    get "/folio/embed"
    etag1 = response.headers["ETag"]
    assert_not_nil etag1, "ETag should not be nil"

    get "/folio/embed"
    etag2 = response.headers["ETag"]

    assert_equal etag1, etag2, "ETag should be the same for identical content"
  end
end
