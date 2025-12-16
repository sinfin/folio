# frozen_string_literal: true

require "test_helper"

class Folio::PagesControllerTest < Folio::BaseControllerTest
  def setup
    super
    @page = create(:folio_page)
  end

  test "root page should get show" do
    get url_for(@page)
    assert_response :ok
  end

  test "slug change -> redirect" do
    old_slug = @page.slug

    get url_for(@page)
    assert_response :ok

    new_slug = "#{old_slug}-changed"
    @page.update!(slug: new_slug)

    get "/#{new_slug}"
    assert_response :ok

    get "/#{old_slug}"
    assert_redirected_to url_for(@page)
  end

  class ::NonPublicPage < Folio::Page
    def self.public?
      false
    end
  end

  test "public?" do
    get url_for(@page)
    assert_response :ok

    @page.becomes!(NonPublicPage)
    @page.save!
    assert_raises(ActiveRecord::RecordNotFound) { get url_for(@page) }
  end

  class ::NonPublicRedirectPage < Folio::Page
    def self.public_rails_path
      :root_path
    end
  end

  test "public_rails_path" do
    get url_for(@page)
    assert_response :ok

    @page.becomes!(NonPublicRedirectPage)
    @page.save!
    get url_for(@page)
    assert_redirected_to(root_path)
  end

  test "published does not have a no-cache Cache-Control header" do
    with_config(
      folio_cache_headers_enabled: true,
      folio_cache_headers_default_ttl: 15,
    ) do
      # Sign out to test public cache (BaseControllerTest auto-signs in superadmin)
      sign_out @superadmin

      get url_for(@page)
      assert_response(:ok)
      # With cache headers enabled, pages get public cache with TTL for anonymous users
      cache_control = response.get_header("Cache-Control")
      assert_match(/public/, cache_control)
      assert_match(/max-age=/, cache_control)
      assert_not_equal "no-store", cache_control
    end
  end

  test "unpublished does have a no-cache Cache-Control header" do
    with_config(
      folio_cache_headers_enabled: true,
      folio_cache_headers_default_ttl: 15,
    ) do
      @page.update!(published: false)

      get url_for([@page, preview: @page.preview_token])
      assert_response(:ok)
      assert_not_equal ActionDispatch::Http::Cache::Response::DEFAULT_CACHE_CONTROL, response.get_header("Cache-Control")
      assert_equal "no-store", response.get_header("Cache-Control")
    end
  end
end
