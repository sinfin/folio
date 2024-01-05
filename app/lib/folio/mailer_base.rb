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
end
