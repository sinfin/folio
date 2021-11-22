# frozen_string_literal: true

class Folio::AasmMailer < Folio::ApplicationMailer
  layout "folio/mailer"

  def event(email, subject, simple_text)
    @simple_text = simple_text

    mail to: email,
         subject: subject,
         bcc: self.class.bcc_email
  end

  def self.bcc_email
    Rails.application.config.folio_aasm_mailer_bcc
  end
end
