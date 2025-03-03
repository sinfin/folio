# frozen_string_literal: true

module Folio::PerSiteSingleton
  extend ActiveSupport::Concern
  include Folio::Singleton

  class_methods do
    def instance(site: nil, fail_on_missing: true, includes: nil)
      if includes
        scope = self.includes(*includes)
      else
        scope = self
      end

      scope.find_by_site_id(site&.id).presence || (fail_on_missing ? fail_on_missing_instance : nil)
    end

    def is_clonable?
      false
    end
  end

  private
    def validate_singularity
      if new_record?
        errors.add(:type, :already_exists_for_site, class: self.class) if self.class.exists?(site:)
      else
        errors.add(:type, :already_exists_for_site, class: self.class) if self.class.where.not(id:).exists?(site:)
      end
    end
end
