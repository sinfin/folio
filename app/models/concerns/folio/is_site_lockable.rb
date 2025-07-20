# frozen_string_literal: true

module Folio::IsSiteLockable
  extend ActiveSupport::Concern
  include Folio::HasSiteRoles

  def locked
    locked?
  end

  def locked?
    # This is called from Warden::Manager before Folio::Current is set, it would always check against the main site
    # -> during auth, use the site from warden params (stored during find_for_authentication)
    if instance_variable_defined?(:@authentication_site) && @authentication_site.present?
      locked_for?(@authentication_site)
    else
      # for non-auth contexts, fall back to the current site
      locked_for?(Folio::Current.site || Folio::Current.main_site)
    end
  end

  def locked_for?(site)
    site.present? && user_link_for(site:)&.locked_at.present?
  end

  def locked=(bool)
    site = Folio::Current.site

    hash = { locked: bool, site:, site_id: site.id }

    if ul = user_link_for(site:)
      hash[:id] = ul.id
    end

    self.site_user_links_attributes = { 0 => hash.stringify_keys }
  end

  def active_for_authentication?
    super && !locked?
  end

  def inactive_message
    locked? ? :user_locked : super
  end
end
