# frozen_string_literal: true

def create_and_host_site(key: nil, attributes: {})
  key_with_fallback = key || Rails.application.config.folio_site_default_test_factory || :folio_site
  factory = FactoryBot.factories[key_with_fallback]

  site = factory.send(:class_name).constantize.last || create(key_with_fallback, attributes)

  host_site(site)

  site
end

def host_site(site)
  Rails.application.routes.default_url_options[:host] = site.domain
  Rails.application.routes.default_url_options[:only_path] = false

  if self.respond_to?(:host!)
    host!(site.domain)
  end
  Folio.instance_variable_set(:@main_site, nil) # to clear the cached version from other tests
  @site = site
end
