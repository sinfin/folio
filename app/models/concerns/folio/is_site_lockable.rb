# frozen_string_literal: true

module Folio::IsSiteLockable
  extend ActiveSupport::Concern
  include Folio::HasSiteRoles

  def locked?
    locked_for?(Folio::Current.site || Folio.main_site)
  end

  def locked_for?(site)
    user_link_for(site:)&.locked_at.present?
  end

  def active_for_authentication?
    super && !locked?
  end

  def inactive_message
    locked? ? :user_locked : super
  end
end
