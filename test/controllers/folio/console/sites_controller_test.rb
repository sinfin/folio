# frozen_string_literal: true

require "test_helper"

class Folio::Console::SitesControllerTest < Folio::Console::BaseControllerTest
  test "edit" do
    get edit_console_site_path
    assert_response :ok
  end

  test "update" do
    assert_not_equal "foo", Folio::Current.main_site.title

    put console_site_path, params: {
      site: {
        title: "foo",
      }
    }

    assert_equal "foo", Folio::Current.main_site.title
  end

  test "clear_cache button and action for a superadmin and an administrator" do
    get edit_console_site_path
    assert_select "a[href='#{clear_cache_console_site_path}']", count: 1

    sign_out(superadmin)
    sign_in create(:folio_site_user_link, site: @site, roles: [:administrator]).user

    get edit_console_site_path
    assert_select "a[href='#{clear_cache_console_site_path}']", count: 1

    post clear_cache_console_site_path
    assert_redirected_to edit_console_site_path
  end

  test "a manager does not see the clear_cache button and cannot clear the cache" do
    sign_out(superadmin)
    sign_in create(:folio_site_user_link, site: @site, roles: [:manager]).user

    get edit_console_site_path
    assert_response :ok
    assert_select "a[href='#{clear_cache_console_site_path}']", count: 0

    assert_raises(CanCan::AccessDenied) { post clear_cache_console_site_path }
  end
end
