# frozen_string_literal: true

require "test_helper"

class Folio::Users::EmailLoginCleanupJobTest < ActiveJob::TestCase
  test "cleanup preserves active attempts and the seven day retention window" do
    travel_to Time.current
    site = create_site(force: true)
    user = create(:folio_user, auth_site: site)
    challenge, = Folio::Devise::EmailLogin::IssueChallenge.call(user:, site:, nonce: SecureRandom.hex(32), purpose: "password")
    old = challenge.dup
    old.assign_attributes(token_digest: SecureRandom.hex(32), expires_at: 8.days.ago)
    old.save!
    recent = challenge.dup
    recent.assign_attributes(token_digest: SecureRandom.hex(32), expires_at: 6.days.ago)
    recent.save!
    attrs = { site:, token_digest: SecureRandom.hex(32), verified_at: 40.days.ago,
              last_authenticated_at: 38.days.ago, authentication_version: user.email_authentication_version }
    old_trust = user.trusted_browsers.create!(**attrs)
    recent_trust = user.trusted_browsers.create!(**attrs.merge(token_digest: SecureRandom.hex(32), last_authenticated_at: 31.days.ago))
    active_trust = user.trusted_browsers.create!(**attrs.merge(token_digest: SecureRandom.hex(32), last_authenticated_at: Time.current))
    revoked_trust = user.trusted_browsers.create!(**attrs.merge(token_digest: SecureRandom.hex(32), last_authenticated_at: 9.days.ago, revoked_at: 8.days.ago))

    events = []
    ActiveSupport::Notifications.subscribed(->(*args) { events << args.last }, "email_login.folio") do
      Folio::Users::EmailLoginCleanupJob.perform_now
    end
    assert_equal [{ event: "expired_pending", site_id: nil, purpose: nil, count: 2, kind: "gauge" }], events

    assert_not Folio::Users::EmailLoginChallenge.exists?(old.id)
    assert Folio::Users::EmailLoginChallenge.exists?(challenge.id)
    assert Folio::Users::EmailLoginChallenge.exists?(recent.id)
    assert_not Folio::Users::TrustedBrowser.exists?(old_trust.id)
    assert Folio::Users::TrustedBrowser.exists?(recent_trust.id)
    assert Folio::Users::TrustedBrowser.exists?(active_trust.id)
    assert_not Folio::Users::TrustedBrowser.exists?(revoked_trust.id)
  end
end
