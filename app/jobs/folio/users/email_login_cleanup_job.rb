# frozen_string_literal: true

class Folio::Users::EmailLoginCleanupJob < Folio::ApplicationJob
  queue_as :default

  RETENTION = 7.days

  def perform
    expired = Folio::Users::EmailLoginChallenge.where(consumed_at: nil, revoked_at: nil).where("expires_at <= ?", Time.current).count
    Folio::Devise::EmailLogin.instrument("expired_pending", count: expired, kind: "gauge")
    Folio::Users::EmailLoginChallenge.where("expires_at < ?", RETENTION.ago).in_batches.delete_all
    Folio::Users::TrustedBrowser.where("revoked_at < ? OR last_authenticated_at < ?",
                                      RETENTION.ago, (RETENTION + Folio::Devise::EmailLogin::TRUST_LIFETIME).ago).in_batches.delete_all
  end
end
