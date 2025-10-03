# frozen_string_literal: true

def create_and_host_site(key: nil, attributes: {})
  key_with_fallback = key || Rails.application.config.folio_site_default_test_factory || :folio_site
  factory = FactoryBot.factories[key_with_fallback]

  @site = factory.send(:class_name).constantize.last || create(key_with_fallback, attributes)

  host_domain!(@site.env_aware_domain)

  @site
end

def host_domain!(env_aware_domain)
  Rails.application.routes.default_url_options[:host] = env_aware_domain
  Rails.application.routes.default_url_options[:only_path] = false
  Rails.application.config.action_mailer.default_url_options[:host] = env_aware_domain

  if self.respond_to?(:host!)
    host!(env_aware_domain)
  end
end
