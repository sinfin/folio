# frozen_string_literal: true

class Folio::Current < ActiveSupport::CurrentAttributes
  attribute :user,
            :site_record,
            :main_site_record,
            :site_for_crossdomain_devise_record,
            :site_for_mailers_record,
            :host,
            :request_id,
            :user_agent,
            :ip_address,
            :url,
            :session,
            :ability

  SITE_KEYS = %i[
    site
    main_site
    site_for_crossdomain_devise
    site_for_mailers
  ]

  def to_h
    attributes
  end

  def setup!(request:, user: nil, session: nil)
    setup_folio_data(request:, user:, session:)
  end

  def setup_folio_data(request:, user:, session:)
    self.host = request.host
    self.request_id = request.uuid
    self.user_agent = request.user_agent
    self.ip_address = request.remote_ip
    self.url = request.url
    self.user = user
    self.ability = Folio::Ability.new(user, site)
    self.session = session

    nillify_site_records unless self.class.site_matches_host?(site:, host:)
  end

  def nillify_site_records
    SITE_KEYS.each do |key|
      send("#{key}_record=", nil)
    end
  end

  def self.site_matches_host?(site:, host:)
    return false if host.nil?
    return false if site.nil?

    if Rails.env.development?
      slug = host.delete_suffix(".localhost")
      site.slug == slug
    else
      site.domain == host
    end
  end

  def self.get_site(host: nil)
    if host.nil?
      main_site
    else
      if Rails.env.development?
        slug = host.delete_suffix(".localhost")

        begin
          Folio::Site.friendly.find(slug)
        rescue ActiveRecord::RecordNotFound
          raise "Could not find site with '#{slug}' slug. Available are #{Folio::Site.pluck(:slug)}"
        end
      else
        Folio::Site.find_by(domain: host) || main_site
      end
    end
  end

  def site
    self.site_record ||= self.class.get_site(host:)
  end

  def self.get_main_site
    Folio::Site.order(id: :asc).first
  end

  def main_site
    self.main_site_record ||= self.class.get_main_site
  end

  def reset_ability!
    self.ability = Folio::Ability.new(user, site)
  end

  def site_is_master?
    main_site.id == site.id
  end

  def site_for_mailers
    self.site_for_mailers_record ||= main_site
  end

  def enabled_site_for_crossdomain_devise
    Rails.application.config.folio_crossdomain_devise ? site_for_crossdomain_devise : nil
  end

  def site_for_crossdomain_devise
    self.site_for_crossdomain_devise_record ||= main_site
  end

  SITE_KEYS.each do |key|
    define_method "#{key}=" do |record|
      send("#{key}_record=", record)
    end
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
