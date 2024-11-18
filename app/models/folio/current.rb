# frozen_string_literal: true

class Folio::Current < ActiveSupport::CurrentAttributes
  attribute :user,
            :site_record,
            :master_site_record,
            :request_id,
            :user_agent,
            :ip_address,
            :url,
            :session,
            :ability

  def to_h
    attributes
  end

  def setup!(request:, user: nil, session: nil)
    setup_folio_data(request:, user:, session:)
  end

  def setup_folio_data(request:, user:, session:)
    self.request_id = request.uuid
    self.user_agent = request.user_agent
    self.ip_address = request.remote_ip
    self.url = request.url
    self.user = user
    self.ability = Folio::Ability.new(user, site)
    self.session = session
    self.site_record = nil
    self.master_site_record = nil
  end

  def site
    self.site_record ||= Folio.current_site
  end

  def site=(record)
    self.site_record = record
  end

  def master_site
    self.master_site_record ||= Folio.main_site
  end

  def master_site=(record)
    self.master_site_record = record
  end

  def reset_ability!
    self.ability = Folio::Ability.new(user, site)
  end

  def site_is_master?
    return @site_is_master unless @site_is_master.nil?
    @site_is_master = master_site.id == site.try(:id)
  end

  def auth_site
    @auth_site ||= Folio.enabled_site_for_crossdomain_devise || site
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
