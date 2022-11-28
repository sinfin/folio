# frozen_string_literal: true

module Folio::LocalizedSingleton
  extend ActiveSupport::Concern
  include Folio::Singleton

  class_methods do
    def instance(fail_on_missing: true, includes: nil, locale: nil, site: nil)
      if includes
        scope = self.includes(*includes)
      else
        scope = self
      end

      scope.find_by_locale(locale || I18n.locale).presence || (fail_on_missing ? fail_on_missing_instance : nil)
    end
  end

  private
    def validate_singularity
      if new_record?
        errors.add(:type, :already_exists_with_locale, class: self.class, rec_locale: locale) if self.class.exists?(locale:)
      else
        errors.add(:type, :already_exists_with_locale, class: self.class, rec_locale: locale) if self.class.where.not(id:).exists?(locale:)
      end
    end
end
