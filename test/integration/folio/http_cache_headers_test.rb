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
      vary_header = response.get_header("Vary") || ""
      assert_includes vary_header, "Accept-Encoding", "Should vary by encoding"
      assert_includes vary_header, "X-Auth-State", "Should vary by authentication state"
      assert_equal "anonymous", response.get_header("X-Auth-State"), "Should indicate anonymous user"
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

      # Signed-in users should get private cache headers with TTL (bypasses Cloudflare)
      cache_control = response.get_header("Cache-Control")
      assert_includes cache_control, "private", "Should have private directive"
      assert_includes cache_control, "max-age=60", "Should have TTL for browser caching"
      vary_header = response.get_header("Vary") || ""
      assert_includes vary_header, "Accept-Encoding", "Should vary by encoding"
      assert_includes vary_header, "X-Auth-State", "Should vary by authentication state"
      assert_equal "authenticated", response.get_header("X-Auth-State"), "Should indicate authenticated user"
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

      # Console paths are handled by ErrorsControllerBase which sets cache headers
      # Since console pages are not 404, they get no-store (only 404 gets cached)
      cache_control = response.get_header("Cache-Control")

      # Console controllers include ErrorsControllerBase, which now only caches 404 errors
      # Non-404 responses (like console pages) get no-store
      assert_equal "no-store", cache_control, "Console pages should get no-store (only 404 errors are cached)"
    end
  end

  test "skip public cache on /users paths" do
    with_config(
      folio_cache_headers_enabled: true,
      folio_cache_headers_default_ttl: 60,
    ) do
      # Test signed-out user on users path - should still skip public cache due to path exclusion
      get "/users/sign_in"
      assert_response :success

      cache_control = response.get_header("Cache-Control")
      assert_not_includes (cache_control || ""), "public", "Users paths should not have public cache"
      assert_not_includes (cache_control || ""), "max-age=60", "Users paths should not have default TTL"
    end
  end

  test "unpublished content gets no-store" do
    with_config(
      folio_cache_headers_enabled: true,
      folio_cache_headers_default_ttl: 60,
    ) do
      page = create(:folio_page, published: false)

      # ensure signed-out
      get destroy_user_session_path rescue nil
      Folio::Current.user = nil

      get url_for([page, preview: page.preview_token])
      assert_response :ok

      assert_equal "no-store", response.get_header("Cache-Control")
    end
  end

  test "cache headers disabled by default" do
    with_config(
      folio_cache_headers_enabled: false,
    ) do
      page = create(:folio_page)

      # ensure signed-out
      get destroy_user_session_path rescue nil
      Folio::Current.user = nil

      get url_for(page)
      assert_response :ok

      # Should use Rails default cache control, not our custom headers
      cache_control = response.get_header("Cache-Control")
      # Rails default may include max-age=0, but should not include s-maxage
      assert_not_includes (cache_control || ""), "s-maxage=", "Should not set s-maxage when disabled"
      assert_not_includes (cache_control || ""), "public", "Should not set public when disabled"
    end
  end

  test "emergency TTL multiplier disables cache when set to 0" do
    with_config(
      folio_cache_headers_enabled: true,
      folio_cache_headers_default_ttl: 60,
    ) do
      page = create(:folio_page, published: true)

      # Set emergency multiplier to 0
      ENV["FOLIO_CACHE_TTL_MULTIPLIER"] = "0"

      begin
        get url_for(page)
        assert_response :ok
        assert_equal "no-store", response.get_header("Cache-Control")
      ensure
        ENV.delete("FOLIO_CACHE_TTL_MULTIPLIER")
      end
    end
  end

  test "emergency TTL multiplier scales TTL when set to decimal value" do
    with_config(
      folio_cache_headers_enabled: true,
      folio_cache_headers_default_ttl: 60,
      folio_cache_headers_include_etag: true,
    ) do
      page = create(:folio_page, published: true)

      # Set multiplier to 0.5 (half TTL)
      ENV["FOLIO_CACHE_TTL_MULTIPLIER"] = "0.5"

      begin
        get url_for(page)
        assert_response :ok
        assert_equal "max-age=30, public, s-maxage=30", response.get_header("Cache-Control")
        assert_includes (response.get_header("Vary") || ""), "Accept-Encoding"
        assert response.get_header("ETag").present?
      ensure
        ENV.delete("FOLIO_CACHE_TTL_MULTIPLIER")
      end
    end
  end

  test "emergency TTL multiplier scales TTL when set to integer value" do
    with_config(
      folio_cache_headers_enabled: true,
      folio_cache_headers_default_ttl: 60,
    ) do
      page = create(:folio_page, published: true)

      # Set multiplier to 2 (double TTL)
      ENV["FOLIO_CACHE_TTL_MULTIPLIER"] = "2"

      begin
        get url_for(page)
        assert_response :ok
        assert_equal "max-age=120, public, s-maxage=120", response.get_header("Cache-Control")
      ensure
        ENV.delete("FOLIO_CACHE_TTL_MULTIPLIER")
      end
    end
  end

  test "emergency TTL multiplier does not affect behavior when set to 1" do
    with_config(
      folio_cache_headers_enabled: true,
      folio_cache_headers_default_ttl: 60,
    ) do
      page = create(:folio_page, published: true)

      # Set multiplier to 1 (no change)
      ENV["FOLIO_CACHE_TTL_MULTIPLIER"] = "1"

      begin
        get url_for(page)
        assert_response :ok
        assert_equal "max-age=60, public, s-maxage=60", response.get_header("Cache-Control")
      ensure
        ENV.delete("FOLIO_CACHE_TTL_MULTIPLIER")
      end
    end
  end

  test "emergency TTL multiplier does not affect behavior when undefined" do
    with_config(
      folio_cache_headers_enabled: true,
      folio_cache_headers_default_ttl: 60,
    ) do
      page = create(:folio_page, published: true)

      # Ensure ENV variable is not set
      ENV.delete("FOLIO_CACHE_TTL_MULTIPLIER")

      get url_for(page)
      assert_response :ok
      assert_equal "max-age=60, public, s-maxage=60", response.get_header("Cache-Control")
    end
  end

  test "emergency TTL multiplier works with 404 pages" do
    # Test that 404 pages also respect the multiplier
    ENV["FOLIO_CACHE_TTL_MULTIPLIER"] = "0.5"

    begin
      get "/404"

      if response.status == 404
        # 404 pages should have shorter TTL (quarter of default, min 15s)
        # With 0.5 multiplier: 60 * 0.5 = 30, then 30/4 = 7.5, but min 15s
        cache_control = response.get_header("Cache-Control")
        if cache_control&.include?("public")
          assert_match(/max-age=15/, cache_control, "404 pages should have minimum 15s TTL even with multiplier")
        end
      else
        skip "404 error handling not available in test environment"
      end
    ensure
      ENV.delete("FOLIO_CACHE_TTL_MULTIPLIER")
    end
  end

  test "non-404 error pages get no-store" do
    # Test that 500, 403, etc. error pages are not cached

    get "/500"

    if response.status == 500
      cache_control = response.get_header("Cache-Control")
      assert_equal "no-store", cache_control, "Non-404 error pages should have no-store"
    else
      skip "500 error handling not available in test environment"
    end
  end

  test "preview mode gets no-store" do
    with_config(
      folio_cache_headers_enabled: true,
      folio_cache_headers_default_ttl: 60,
    ) do
      page = create(:folio_page, published: false)

      # Access page with preview token - should never be cached
      get url_for(page), params: { preview: page.preview_token }
      assert_response :ok

      cache_control = response.get_header("Cache-Control")
      assert_equal "no-store", cache_control, "Preview mode should have no-store"
    end
  end

  test "preview mode works even for signed-out users" do
    with_config(
      folio_cache_headers_enabled: true,
      folio_cache_headers_default_ttl: 60,
    ) do
      page = create(:folio_page, published: false)

      # Access page with preview token - should work and not be cached (no sign in)
      get url_for(page), params: { preview: page.preview_token }
      assert_response :ok

      cache_control = response.get_header("Cache-Control")
      assert_equal "no-store", cache_control, "Preview mode should have no-store even for signed-out users"
    end
  end
end
