# frozen_string_literal: true

class Folio::ApplicationMailer < ActionMailer::Base
  include Folio::Engine.routes.url_helpers

  default from: -> { Folio::Site.instance.email_from.presence || Folio::Site.instance.email }
  layout "folio/mailer"

  def self.system_email
    if Folio::Site.instance.system_email.present?
      Folio::Site.instance.system_email_array
    else
      Folio::Site.instance.email
    end
  end

  def self.system_email_copy
    Folio::Site.instance.system_email_copy_array if Folio::Site.instance.system_email_copy.present?
  end
end
