# frozen_string_literal: true

module Folio::Users::EmailLoginVerifiable
  extend ActiveSupport::Concern

  included do
    attr_writer :authentication_site

    has_many :email_login_challenges, class_name: "Folio::Users::EmailLoginChallenge", dependent: :delete_all, inverse_of: :user
    has_many :trusted_browsers, class_name: "Folio::Users::TrustedBrowser", dependent: :delete_all, inverse_of: :user

    before_update :advance_email_authentication_version,
                  if: -> { has_attribute?(:email_authentication_version) && (will_save_change_to_encrypted_password? || will_save_change_to_email?) }
  end

  def revoke_email_login_verifications!
    with_lock { increment!(:email_authentication_version) }
  end

  private
    def advance_email_authentication_version
      self.email_authentication_version = self.class.where(id:).lock.pick(:email_authentication_version) + 1
    end
end
