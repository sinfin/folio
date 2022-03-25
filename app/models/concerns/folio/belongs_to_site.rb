# frozen_string_literal: true

module Folio::BelongsToSite
  extend ActiveSupport::Concern

  included do
    belongs_to :site, class_name: "Folio::Site",
                      required: false

    validate :validate_belongs_to_site
  end

  private
    def validate_belongs_to_site
      return if Rails.application.config.folio_site_is_a_singleton

      return errors.add(:site, :blank) if site.nil?

      if Rails.application.config.folio_site_validate_belongs_to_namespace
        if site.class.name.deconstantize != self.class.name.deconstantize
          errors.add(:base, :wrong_namespace)
        end
      end
    end
end
