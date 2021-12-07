# frozen_string_literal: true

module Folio::HasSecretHash
  extend ActiveSupport::Concern

  included do
    before_validation :set_secret_hash

    validates :secret_hash,
              presence: true,
              uniqueness: true
  end

  def set_secret_hash
    return if secret_hash?

    secret_hash = nil

    loop do
      secret_hash = SecureRandom.urlsafe_base64(self.class.secret_hash_length)
                                .gsub(/-|_/, ("a".."z").to_a[rand(26)])
      break unless self.class.base_class.exists?(secret_hash: secret_hash)
    end

    self.secret_hash = secret_hash
  end

  class_methods do
    def secret_hash_length
      24
    end
  end
end
