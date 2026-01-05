# frozen_string_literal: true

module SitesHelper
  private
    def get_any_site
      get_current_or_existing_site_or_create_from_factory
    end

    def create_and_host_site(key: nil, attributes: {}, force: false)
      site = create_site(key:, attributes:, force:)
      host_site(site)

      site
    end

    def create_site(key: nil, attributes: {}, force: false)
      key_with_fallback = key || Rails.application.config.folio_site_default_test_factory || :folio_site
      factory = FactoryBot.factories[key_with_fallback]

      if force
        create(key_with_fallback, attributes)
      else
        factory.send(:class_name).constantize.last || create(key_with_fallback, attributes)
      end
    end

    def host_site(site)
      host_domain(site.env_aware_domain)

      unless is_a?(Folio::CapybaraTest)
        Folio::Current.site = site
      end

      @site = site
    end

    def host_domain(env_aware_domain)
      Rails.application.routes.default_url_options[:host] = env_aware_domain
      Rails.application.routes.default_url_options[:only_path] = false

      Rails.application.config.action_mailer.default_url_options ||= {}
      Rails.application.config.action_mailer.default_url_options[:host] = env_aware_domain

      if self.respond_to?(:host!)
        host!(env_aware_domain)
      end
    end
end
