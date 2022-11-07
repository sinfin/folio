# frozen_string_literal: true

module Folio::MailerBase
  extend ActiveSupport::Concern

  included do
    helper_method :site
  end

  def site
    @site ||= Folio.site_instance_for_mailers
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

  module ClassMethods
    def site
      logger.error("Folio deprecation: Class method `site` is deprecated, use instance method instead.")

      if Rails.application.config.folio_site_is_a_singleton
        Folio::Site.instance
      else
        Folio::Site.ordered.first
      end
    end

    def system_email
      logger.error("Folio deprecation: Class method `system_email` is deprecated, use instance method instead.")

      if site.system_email.present?
        site.system_email_array
      else
        site.email
      end
    end

    def system_email_copy
      logger.error("Folio deprecation: Class method `system_email_copy` is deprecated, use instance method instead.")

      site.system_email_copy_array if site.system_email_copy.present?
    end
  end
end
