# frozen_string_literal: true

require "test_helper"

class Folio::Users::EmailLoginChallengeTest < ActiveSupport::TestCase
  def setup
    travel_to Time.current
    @site = create_site(force: true)
    @user = create(:folio_user, auth_site: @site)
    @nonce = SecureRandom.hex(32)
    @challenge, @token = issue
  end

  test "email approval does not consume the challenge or sign in the user" do
    assert_no_difference("@user.reload.sign_in_count") do
      @challenge.approve!(token: @token, site: @site)
    end
    assert_equal "approved", @challenge.reload.state
    assert_nil @challenge.consumed_at
    assert_empty @user.trusted_browsers
  end

  test "only the original browser can consume an approved challenge once" do
    assert_raises(Folio::Devise::EmailLogin::InvalidChallenge) { @challenge.consume!(nonce: @nonce, site: @site) }
    @challenge.approve!(token: @token, site: @site)
    assert_raises(Folio::Devise::EmailLogin::InvalidChallenge) { @challenge.consume!(nonce: @token, site: @site) }
    assert_equal @user, @challenge.consume!(nonce: @nonce, site: @site)
    assert_equal "consumed", @challenge.reload.state
    assert_raises(Folio::Devise::EmailLogin::InvalidChallenge) { @challenge.consume!(nonce: @nonce, site: @site) }
    assert_raises(Folio::Devise::EmailLogin::InvalidChallenge) { @challenge.approve!(token: @token, site: @site) }
  end

  test "approval does not extend expiration" do
    travel_to @challenge.expires_at - 1.second do
      @challenge.approve!(token: @token, site: @site)
    end
    travel_to @challenge.expires_at do
      assert_raises(Folio::Devise::EmailLogin::InvalidChallenge) { @challenge.consume!(nonce: @nonce, site: @site) }
    end
  end

  test "wrong token or site cannot approve" do
    other_site = create_site(force: true)
    assert_raises(Folio::Devise::EmailLogin::InvalidChallenge) { @challenge.approve!(token: @nonce, site: @site) }
    assert_raises(Folio::Devise::EmailLogin::InvalidChallenge) { @challenge.approve!(token: @token, site: other_site) }
    assert_equal "waiting", @challenge.reload.state
  end

  test "password changes invalidate even already approved challenges" do
    @challenge.approve!(token: @token, site: @site)
    @user.update!(password: "Another@Password123")
    assert_raises(Folio::Devise::EmailLogin::InvalidChallenge) { @challenge.consume!(nonce: @nonce, site: @site) }
  end

  test "resend replaces the old challenge" do
    replacement, token = issue(previous: @challenge)
    assert_equal "revoked", @challenge.reload.state
    assert_raises(Folio::Devise::EmailLogin::InvalidChallenge) { @challenge.approve!(token: @token, site: @site) }
    replacement.approve!(token:, site: @site)
    assert_equal "approved", replacement.reload.state
  end

  test "another browser does not revoke the original challenge" do
    travel Folio::Devise::EmailLogin::RESEND_INTERVAL do
      other, = issue(nonce: SecureRandom.hex(32))
      assert_equal "waiting", @challenge.reload.state
      assert_equal "waiting", other.state
    end
  end

  test "locking a site permanently revokes its challenges and trust without affecting another site" do
    @user.update!(superadmin: true)
    other_site = create_site(force: true)
    other_challenge, = Folio::Devise::EmailLogin::IssueChallenge.call(user: @user, site: other_site,
                                                                    nonce: @nonce, purpose: "password")
    trust_attributes = { token_digest: Folio::Devise::EmailLogin.digest(SecureRandom.hex(32)), verified_at: Time.current,
                         last_authenticated_at: Time.current, authentication_version: @user.email_authentication_version }
    trust = @user.trusted_browsers.create!(site: @site, **trust_attributes)
    other_trust = @user.trusted_browsers.create!(site: other_site, **trust_attributes.merge(token_digest: SecureRandom.hex(32)))
    link = @user.site_user_links.find_or_create_by!(site: @site)

    link.update!(locked_at: Time.current)
    link.update!(locked_at: nil)

    assert_equal "revoked", @challenge.reload.state
    assert_not_nil trust.reload.revoked_at
    assert_equal "waiting", other_challenge.reload.state
    assert_nil other_trust.reload.revoked_at
    assert_raises(Folio::Devise::EmailLogin::InvalidChallenge) { @challenge.approve!(token: @token, site: @site) }
  end

  private
    def issue(**options)
      Folio::Devise::EmailLogin::IssueChallenge.call(user: @user, site: @site, nonce: @nonce, purpose: "password", **options)
    end
end
