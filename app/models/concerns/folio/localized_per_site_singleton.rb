# frozen_string_literal: true

module Folio::LocalizedPerSiteSingleton
  extend ActiveSupport::Concern
  include Folio::Singleton

  class_methods do
    def instance(site: nil, fail_on_missing: true, includes: nil, locale: nil)
      if includes
        scope = self.includes(*includes)
      else
        scope = self
      end

      scope.find_by(site_id: site.id, locale:).presence || (fail_on_missing ? fail_on_missing_instance : nil)
    end
  end

  private
    def validate_singularity
      if new_record?
        errors.add(:type, :already_exists_for_site_and_locale, class: self.class) if self.class.exists?(site:, locale:)
      else
        errors.add(:type, :already_exists_for_site_and_locale, class: self.class) if self.class.where.not(id:).exists?(site:, locale:)
      end
    end
end
