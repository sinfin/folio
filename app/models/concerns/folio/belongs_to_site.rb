# frozen_string_literal: true

module Folio::BelongsToSite
  extend ActiveSupport::Concern

  included do
    belongs_to :site, class_name: "Folio::Site",
                      required: false

    validate :validate_belongs_to_site

    scope :by_atom_setting_site_id, -> (site_id) { where(site_id:) }
    scope :by_site, ->(site) { where(site: site) }
    scope :by_site_id, ->(site_id) { where(site_id: site_id) }
  end

  class_methods do
    def has_belongs_to_site?
      !Rails.application.config.folio_site_is_a_singleton
    end
  end

  private
    def validate_belongs_to_site
      return if Rails.application.config.folio_site_is_a_singleton

      return errors.add(:site, :blank) if site.nil?

      if Rails.application.config.folio_site_validate_belongs_to_namespace
        unless self.class.name.deconstantize.starts_with?(site.class.name.deconstantize)
          errors.add(:base, :wrong_namespace)
        end
      end
    end
end
