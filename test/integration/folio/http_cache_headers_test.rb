# frozen_string_literal: true

require "test_helper"

class Folio::HttpCacheHeadersTest < ActionDispatch::IntegrationTest
  include Folio::Engine.routes.url_helpers
  include SitesHelper

  def setup
    super
    @site = create_site()
    host_site(@site)
    Folio::Current.reset
  end

  test "public cache headers for signed-out GET on published page" do
    with_config(
      folio_cache_headers_enabled: true,
      folio_cache_headers_default_ttl: 60,
      folio_cache_headers_include_etag: true,
      folio_cache_headers_include_last_modified: true,
    ) do
      page = create(:folio_page)

      # ensure signed-out
      get destroy_user_session_path rescue nil
      Folio::Current.user = nil

      get url_for(page)
      assert_response :ok

      assert_equal "max-age=60, public, s-maxage=60", response.get_header("Cache-Control")
      assert_includes (response.get_header("Vary") || ""), "Accept-Encoding"
      assert response.get_header("ETag").present?, "ETag should be present"
    end
  end

  test "private cache headers for signed-in user" do
    with_config(
      folio_cache_headers_enabled: true,
      folio_cache_headers_default_ttl: 60,
    ) do
      # sign in a user
      user = create(:folio_user, :superadmin)
      sign_in user
      Folio::Current.user = user

      page = create(:folio_page)
      get url_for(page)
      assert_response :ok

      assert_equal "no-cache", response.get_header("Cache-Control")
    end
  end

  test "skip public cache on /console paths" do
    with_config(
      folio_cache_headers_enabled: true,
      folio_cache_headers_default_ttl: 60,
    ) do
      user = create(:folio_user, :superadmin)
      sign_in user
      Folio::Current.user = user

      get console_pages_path
      assert_response :success

      assert_not_equal "max-age=60, public, s-maxage=60", response.get_header("Cache-Control")
    end
  end
end
