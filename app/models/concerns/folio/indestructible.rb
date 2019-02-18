# frozen_string_literal: true

module Folio::Indestructible
  extend ActiveSupport::Concern

  included do
    attribute :force_destroy, :boolean, default: false
    before_destroy :before_destroy_indestructible
  end

  class_methods do
    def indestructible?
      true
    end
  end

  private

    def before_destroy_indestructible
      unless force_destroy?
        errors.add(:base, :indestructible)
        throw(:abort)
      end
    end
end
