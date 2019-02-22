# frozen_string_literal: true

module Folio::LocalizedSingleton
  extend ActiveSupport::Concern
  include Folio::Singleton

  class_methods do
    def instance(fail_on_missing: true)
      self.find_by_locale(I18n.locale).presence || (fail_on_missing ? fail_on_missing_instance : nil)
    end
  end

  private

    def validate_singularity
      if new_record?
        errors.add(:base, :invalid) if self.class.exists?(locale: locale)
      else
        errors.add(:base, :invalid) if self.class.where.not(id: id).exists?(locale: locale)
      end
    end
end
