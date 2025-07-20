# frozen_string_literal: true

require "test_helper"

class Folio::Console::Api::SiteUserLinksControllerTest < Folio::Console::BaseControllerTest
  test "set_locked" do
    link = create(:folio_site_user_link, site: @site)
    assert_not link.locked?

    patch url_for([:set_locked, :console, :api, link]), params: {
      site_user_link: {
        locked: true,
      }
    }

    assert_response :ok

    assert link.reload.locked?
  end

  test "set_locked signs out user everywhere and prevents re-login" do
    user = create(:folio_user, auth_site: @site)
    link = create(:folio_site_user_link, site: @site, user: user)

    original_salt = user.authenticatable_salt

    assert_not link.locked?

    # user can authenticate before locking
    warden_params = { email: user.email, auth_site_id: @site.id.to_s }
    found_user_before = Folio::User.find_for_authentication(warden_params)
    assert_equal user, found_user_before
    assert found_user_before.active_for_authentication?

    patch url_for([:set_locked, :console, :api, link]), params: {
      site_user_link: {
        locked: true,
      }
    }

    assert_response :ok
    assert link.reload.locked?

    # user's authenticatable_salt changed (signs out everywhere)
    user.reload
    assert_not_equal original_salt, user.authenticatable_salt

    # authentication would fail - simulate find_for_authentication and active_for_authentication?
    warden_params = { email: user.email, auth_site_id: @site.id.to_s }
    found_user = Folio::User.find_for_authentication(warden_params)

    assert_equal user, found_user
    assert_not found_user.active_for_authentication?
  end

  test "authentication respects site-specific locking for superadmins" do
    main_site = Folio::Current.main_site
    superadmin = create(:folio_user, :superadmin, auth_site: main_site)

    # site_user_link for a different site, already locked
    other_site = create_site(force: true)
    link = create(:folio_site_user_link, site: other_site, user: superadmin, locked_at: Time.current)

    assert link.locked?

    # authentication on the locked site should fail
    warden_params = { email: superadmin.email, auth_site_id: other_site.id.to_s }
    found_user = Folio::User.find_for_authentication(warden_params)

    assert_equal superadmin, found_user
    assert_not found_user.active_for_authentication?

    # authentication on the main site should still work
    main_site_params = { email: superadmin.email, auth_site_id: main_site.id.to_s }
    found_user_main = Folio::User.find_for_authentication(main_site_params)

    assert_equal superadmin, found_user_main
    assert found_user_main.active_for_authentication?
  end
end
