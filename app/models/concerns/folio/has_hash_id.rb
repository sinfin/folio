# frozen_string_literal: true

module Folio::HasHashId
  extend ActiveSupport::Concern

  included do
    extend ::FriendlyId
    before_create :set_hash_id
    friendly_id :hash_id

    validates :hash_id,
              presence: true
  end

  def hash_id
    super || set_hash_id
  end

  def set_hash_id
    return read_attribute(:hash_id) if read_attribute(:hash_id)

    hash_id = nil

    loop do
      hash_id = SecureRandom.urlsafe_base64(self.class.hash_id_length)
                            .gsub(/-|_/, ("a".."z").to_a[rand(26)])
      exists = self.class.hash_id_classes.any? do |klass|
        klass.exists?(hash_id: hash_id)
      end
      break unless exists
    end

    self.hash_id = hash_id
  end

  class_methods do
    def hash_id_length
      4
    end

    def hash_id_additional_classes
      []
    end

    def hash_id_classes
      [self] + hash_id_additional_classes
    end
  end
end
