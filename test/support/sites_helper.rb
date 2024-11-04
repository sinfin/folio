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
      Rails.application.routes.default_url_options[:host] = site.env_aware_domain
      Rails.application.routes.default_url_options[:only_path] = false
      Folio::Current.site = site

      if self.respond_to?(:host!)
        host!(site.env_aware_domain)
      end
      Folio.instance_variable_set(:@main_site, nil) # to clear the cached version from other tests
      @site = site
    end
end
