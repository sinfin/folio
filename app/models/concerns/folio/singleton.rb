# frozen_string_literal: true

module Folio::Singleton
  extend ActiveSupport::Concern
  include Folio::Indestructible

  class MissingError < ActiveRecord::RecordNotFound; end

  included do
    validate :validate_singularity
  end

  class_methods do
    def instance(fail_on_missing: true, includes: nil)
      if includes
        scope = self.includes(*includes)
      else
        scope = self
      end
      scope.first.presence || (fail_on_missing ? fail_on_missing_instance : nil)
    end

    def fail_on_missing_instance
      fail(MissingError, self.to_s)
    end

    def singleton?
      true
    end
  end

  private
    def validate_singularity
      if new_record?
        errors.add(:base, :invalid) if self.class.exists?
      else
        errors.add(:base, :invalid) if self.class.where.not(id:).exists?
      end
    end
end
