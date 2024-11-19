# frozen_string_literal: true

module Folio::IsSiteLockable
  extend ActiveSupport::Concern
  include Folio::HasSiteRoles

  def locked
    locked?
  end

  def locked?
    # TODO: because this is called from Warden::Managerbefore Folio::Current is set,
    # it will always check against the main site
    # we need somehow prebend Warden
    locked_for?(Folio::Current.site || Folio::Current.main_site)
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
