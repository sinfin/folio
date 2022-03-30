# frozen_string_literal: true

class Folio::ApplicationMailer < ActionMailer::Base
  include Folio::Engine.routes.url_helpers
  include Folio::MailerEmailTemplates

  default from: -> { Folio::Site.instance_for_mailers.email_from.presence || Folio::Site.instance_for_mailers.email }
  layout "folio/mailer"

  def self.system_email
    if Folio::Site.instance_for_mailers.system_email.present?
      Folio::Site.instance_for_mailers.system_email_array
    else
      Folio::Site.instance_for_mailers.email
    end
  end

  def self.system_email_copy
    Folio::Site.instance_for_mailers.system_email_copy_array if Folio::Site.instance_for_mailers.system_email_copy.present?
  end
end
