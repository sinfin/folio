# frozen_string_literal: true

module Folio::HasHashId
  extend ActiveSupport::Concern

  included do
    extend ::FriendlyId
    before_create :set_hash_id
    friendly_id :hash_id
  end

  def set_hash_id
    hash_id = nil

    loop do
      hash_id = SecureRandom.urlsafe_base64(self.class.hash_id_length)
                            .gsub(/-|_/, ('a'..'z').to_a[rand(26)])
      break unless self.class.name.constantize.exists?(hash_id: hash_id)
    end

    self.hash_id = hash_id
  end

  class_methods do
    def hash_id_length
      4
    end
  end
end
