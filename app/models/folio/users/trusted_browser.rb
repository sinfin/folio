# frozen_string_literal: true

class Folio::Users::TrustedBrowser < Folio::ApplicationRecord
  belongs_to :user, class_name: "Folio::User", inverse_of: :trusted_browsers
  belongs_to :site, class_name: "Folio::Site"

  validates :token_digest, :verified_at, :last_authenticated_at, :authentication_version, presence: true
  validates :token_digest, uniqueness: true

  def expires_at
    last_authenticated_at + Folio::Devise::EmailLogin::TRUST_LIFETIME
  end

  def trusted_for?(user:, site:)
    user_id == user.id && site_id == site.id && !revoked_at? &&
      authentication_version == user.email_authentication_version && expires_at > Time.current
  end
end

# == Schema Information
#
# Table name: folio_users_trusted_browsers
#
#  id                     :bigint(8)        not null, primary key
#  user_id                :bigint(8)        not null
#  site_id                :bigint(8)        not null
#  token_digest           :string           not null
#  verified_at            :datetime         not null
#  last_authenticated_at  :datetime         not null
#  revoked_at             :datetime
#  authentication_version :integer          not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
# Indexes
#
#  index_folio_users_trusted_browsers_on_last_authenticated_at  (last_authenticated_at)
#  index_folio_users_trusted_browsers_on_site_id                (site_id)
#  index_folio_users_trusted_browsers_on_token_digest           (token_digest) UNIQUE
#  index_folio_users_trusted_browsers_on_user_id                (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (site_id => folio_sites.id)
#  fk_rails_...  (user_id => folio_users.id)
#
