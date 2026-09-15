# frozen_string_literal: true

class Folio::Users::EmailLoginDeliveryJob < Folio::ApplicationJob
  queue_as :mailers
  self.log_arguments = false

  def self.deliver_later(challenge, token, locale:)
    payload = token_encryptor.encrypt_and_sign(token, purpose: "email_login:#{challenge.id}", expires_at: challenge.expires_at)
    perform_later(challenge.id, payload, locale)
  end

  def self.token_encryptor
    @token_encryptor ||= ActiveSupport::MessageEncryptor.new(
      Rails.application.key_generator.generate_key("folio.email_login.delivery", 32),
      cipher: "aes-256-gcm", serializer: JSON,
    )
  end
  private_class_method :token_encryptor

  def perform(challenge_id, payload, locale)
    token = self.class.send(:token_encryptor).decrypt_and_verify(payload, purpose: "email_login:#{challenge_id}")
    challenge = Folio::Users::EmailLoginChallenge.find_by(id: challenge_id)
    return unless challenge&.token_matches?(token) && challenge.usable_for?(challenge.site)

    message = challenge.user.send(:devise_mailer).email_login(challenge, token, locale:).deliver_now
    if message.is_a?(Mail::Message) && message.perform_deliveries
      Folio::Devise::EmailLogin.instrument("delivered", site_id: challenge.site_id, purpose: challenge.purpose)
    end
  rescue ActiveSupport::MessageEncryptor::InvalidMessage
    nil
  end
end
