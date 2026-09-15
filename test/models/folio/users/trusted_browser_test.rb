# frozen_string_literal: true

require "test_helper"

class Folio::Users::TrustedBrowserTest < ActiveSupport::TestCase
  def setup
    travel_to Time.current
    @site = create_site(force: true)
    @user = create(:folio_user, auth_site: @site)
    @browser = @user.trusted_browsers.create!(site: @site,
                                            token_digest: Folio::Devise::EmailLogin.digest(SecureRandom.hex(32)),
                                            verified_at: Time.current,
                                            last_authenticated_at: Time.current,
                                            authentication_version: @user.email_authentication_version)
  end

  test "trust expires thirty days after the last login" do
    original_verification = @browser.verified_at
    travel 20.days do
      assert @browser.trusted_for?(user: @user, site: @site)
      @browser.update!(last_authenticated_at: Time.current)
    end
    travel 31.days do
      assert @browser.trusted_for?(user: @user, site: @site)
      assert_equal original_verification, @browser.verified_at
    end
    travel_to @browser.expires_at do
      assert_not @browser.trusted_for?(user: @user, site: @site)
    end
  end

  test "trust is bound to the user and site" do
    assert_not @browser.trusted_for?(user: create(:folio_user), site: @site)
    assert_not @browser.trusted_for?(user: @user, site: create_site(force: true))
  end

  test "normal sign out preserves trust but password changes revoke it" do
    @user.sign_out_everywhere!
    assert @browser.trusted_for?(user: @user, site: @site)
    @user.update!(password: "Another@Password123")
    assert_not @browser.trusted_for?(user: @user, site: @site)
  end

  test "explicit revocation invalidates trust" do
    @user.revoke_email_login_verifications!
    assert_not @browser.trusted_for?(user: @user, site: @site)
  end

  test "a pending email change preserves trust until the new email is confirmed" do
    @user.update!(email: "changed-address@example.test")
    assert_equal "changed-address@example.test", @user.unconfirmed_email
    assert @browser.trusted_for?(user: @user, site: @site)

    assert @user.confirm

    assert_equal "changed-address@example.test", @user.reload.email
    assert_not @browser.trusted_for?(user: @user, site: @site)
  end
end
