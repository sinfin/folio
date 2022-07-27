# frozen_string_literal: true

class Folio::ApplicationMailer < ActionMailer::Base
  include Folio::Engine.routes.url_helpers
  include Folio::MailerEmailTemplates

  default from: -> { Folio.site_instance_for_mailers.email_from.presence || Folio.site_instance_for_mailers.email }
  layout "folio/mailer"

  def self.system_email
    if Folio.site_instance_for_mailers.system_email.present?
      Folio.site_instance_for_mailers.system_email_array
    else
      Folio.site_instance_for_mailers.email
    end
  end

  def self.system_email_copy
    Folio.site_instance_for_mailers.system_email_copy_array if Folio.site_instance_for_mailers.system_email_copy.present?
  end
end
