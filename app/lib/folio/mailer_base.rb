# frozen_string_literal: true

module Folio::MailerBase
  extend ActiveSupport::Concern

  included do
    helper_method :site
    helper_method :compiled_asset_contents
  end

  def site
    @site ||= Folio.site_instance_for_mailers
  end

  def default_url_options
    {
      only_path: false,
      host: site.env_aware_domain,
      locale: ::Rails.application.config.folio_console_add_locale_to_preview_links ? (site.locale || I18n.locale) : nil
    }.compact
  end

  def system_email
    if site.system_email.present?
      site.system_email_array
    else
      site.email
    end
  end

  def system_email_copy
    site.system_email_copy_array if site.system_email_copy.present?
  end

  def compiled_asset_contents(key)
    if Rails.application.assets
      Rails.application.assets.find_asset(key).to_s
    else
      manifest_file = Rails.application.assets_manifest.assets[key]
      File.read(File.join(Rails.application.assets_manifest.directory, manifest_file))
    end
  end
end
