# frozen_string_literal: true

module Folio::BelongsToSite
  extend ActiveSupport::Concern

  included do
    belongs_to :site, class_name: "Folio::Site",
                      required: false

    validate :validate_belongs_to_site

    scope :by_site_id, -> (site_id) { where(site_id:) }
    scope :by_site, -> (site) { site ? where(site:) : none }

    scope :by_atom_setting_site_id, -> (site_id) { by_site_id(site_id) }
  end

  class_methods do
    def has_belongs_to_site?
      true
    end

    def add_site_to_console_params?
      has_belongs_to_site?
    end
  end

  private
    def validate_belongs_to_site
      errors.add(:site, :blank) if site.nil?
    end
end
