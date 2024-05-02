# frozen_string_literal: true

class Folio::Current < ActiveSupport::CurrentAttributes
  attribute :user,
            :site,
            :request_id,
            :user_agent,
            :ip_address,
            :url,
            :session,
            :ability,
            :master_site

  def to_h
    attributes
  end

  def setup!(request:, site:, user: nil, session: nil)
    setup_folio_data(request:, site:, user:, session:)
  end

  def setup_folio_data(request:, site:, user:, session:)
    self.request_id = request.uuid
    self.user_agent = request.user_agent
    self.ip_address = request.remote_ip
    self.url = request.url
    self.site = site
    self.user = user
    self.session = session
    self.ability = Folio::Ability.new(user, site)
    self.master_site = Folio.main_site
  end

  def site_is_master?
    return @site_is_master unless @site_is_master.nil?
    @site_is_master = master_site.id == site.try(:id)
  end

  if Rails.env.test?
    alias :original_reset :reset

    def reset
      run_callbacks :reset do
        # self.attributes = {}
      end
    end
  end
end
