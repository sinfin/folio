# frozen_string_literal: true

require "test_helper"

class Folio::ErrorsControllerTest < ActionDispatch::IntegrationTest
  setup do
    create_and_host_site
  end

  test "should get 404" do
    with_config(
      folio_cache_headers_enabled: true,
      folio_cache_headers_default_ttl: 60,
    ) do
      get "/404"
      assert_response :not_found
      # 404 errors get shorter TTL but still cached (not no-store)
      cache_control = response.get_header("Cache-Control")
      assert_match(/max-age=/, cache_control)
      assert_select "h1", "404"
    end
  end

  test "should get 500" do
    # 500 errors should not be cached even with cache headers enabled
    with_config(
      folio_cache_headers_enabled: true,
      folio_cache_headers_default_ttl: 60,
    ) do
      get "/500"
      assert_response :internal_server_error
      cache_control = response.get_header("Cache-Control")
      # 500 errors get no-store (not cacheable due to server error)
      assert_equal "no-store", cache_control
      assert_select "h1", "500"
    end
  end

  test "should get 403" do
    get "/403"
    assert_response :forbidden
    assert_equal "no-store", response.get_header("Cache-Control")
    assert_select "h1", "403"
  end
end
