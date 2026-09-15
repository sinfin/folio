# frozen_string_literal: true

class Folio::Users::EmailLoginChallenge < Folio::ApplicationRecord
  PURPOSES = %w[password magic_link rememberable oauth invitation password_reset registration].freeze

  belongs_to :user, class_name: "Folio::User", inverse_of: :email_login_challenges
  belongs_to :site, class_name: "Folio::Site"

  validates :purpose, inclusion: { in: PURPOSES }
  validates :token_digest, :browser_nonce_digest, :expires_at, :authentication_version, presence: true
  validates :token_digest, uniqueness: true

  scope :pending, -> { where(consumed_at: nil, revoked_at: nil).where("expires_at > ?", Time.current) }

  def state
    return "consumed" if consumed_at?
    return "revoked" if revoked_at?
    return "expired" if expires_at <= Time.current

    approved_at? ? "approved" : "waiting"
  end

  def token_matches?(token)
    token.is_a?(String) && token.match?(/\A[0-9a-f]{64}\z/) &&
      ActiveSupport::SecurityUtils.secure_compare(token_digest, Folio::Devise::EmailLogin.digest(token))
  end

  def browser_matches?(nonce)
    nonce.is_a?(String) && nonce.match?(/\A[0-9a-f]{64}\z/) &&
      ActiveSupport::SecurityUtils.secure_compare(browser_nonce_digest, Folio::Devise::EmailLogin.digest(nonce))
  end

  def usable_for?(site)
    return false unless site_id == site.id && %w[waiting approved].include?(state)

    user.authentication_site = site
    authentication_version == user.email_authentication_version &&
      (user.auth_site_id == site.id || user.superadmin?) &&
      user.active_for_authentication? && !(user.respond_to?(:invited_to_sign_up?) && user.invited_to_sign_up?)
  end

  def approve!(token:, site:)
    approved = false
    user.with_lock do
      with_lock do
        raise Folio::Devise::EmailLogin::InvalidChallenge unless token_matches?(token) && usable_for?(site)

        unless approved_at?
          update!(approved_at: Time.current)
          approved = true
        end
      end
    end
    Folio::Devise::EmailLogin.instrument("approved", site_id:, purpose:) if approved
  end

  def consume!(nonce:, site:)
    user.with_lock do
      with_lock do
        unless approved_at? && browser_matches?(nonce) && usable_for?(site)
          raise Folio::Devise::EmailLogin::InvalidChallenge
        end

        update!(consumed_at: Time.current)
      end
    end
    user
  end
end

# == Schema Information
#
# Table name: folio_users_email_login_challenges
#
#  id                     :bigint(8)        not null, primary key
#  user_id                :bigint(8)        not null
#  site_id                :bigint(8)        not null
#  purpose                :string           not null
#  token_digest           :string           not null
#  browser_nonce_digest   :string           not null
#  expires_at             :datetime         not null
#  approved_at            :datetime
#  consumed_at            :datetime
#  revoked_at             :datetime
#  authentication_version :integer          not null
#  return_path            :string
#  remember_me            :boolean          default(FALSE), not null
#  trust_browser          :boolean          default(TRUE), not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
# Indexes
#
#  index_folio_email_login_deliveries                        (user_id,site_id,created_at)
#  index_folio_users_email_login_challenges_on_expires_at    (expires_at)
#  index_folio_users_email_login_challenges_on_site_id       (site_id)
#  index_folio_users_email_login_challenges_on_token_digest  (token_digest) UNIQUE
#  index_folio_users_email_login_challenges_on_user_id       (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (site_id => folio_sites.id)
#  fk_rails_...  (user_id => folio_users.id)
#
