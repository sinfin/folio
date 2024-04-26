# frozen_string_literal: true

class Folio::Current < ActiveSupport::CurrentAttributes
  attribute :user,
            :site,
            :request_id,
            :user_agent,
            :ip_address,
            :url

  def to_h
    attributes
  end

  def site
    super || master_site
  end

  def ability
    @ability ||= Folio::Ability.new(user, site)
  end

  def master_site
    @master_site ||= Folio.main_site
  end

  def site_is_master?
    return @site_is_master unless @site_is_master.nil?
    @site_is_master = master_site.id == site.try(:id)
  end
end
