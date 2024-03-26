# frozen_string_literal: true

class Folio::AasmMailer < Folio::ApplicationMailer
  layout "folio/mailer"

  def event(email, subject, simple_text)
    @simple_text = simple_text

    mail to: email,
         subject:,
         bcc: bcc_email,
         reply_to: reply_to_email,
         from: from_email
  end

  def bcc_email
    Rails.application.config.folio_aasm_mailer_config.try(:[], :bcc) || Rails.application.config.folio_mailer_global_bcc
  end

  def reply_to_email
    Rails.application.config.folio_aasm_mailer_config.try(:[], :reply_to)
  end

  def from_email
    Rails.application.config.folio_aasm_mailer_config.try(:[], :from) || site.email_from.presence || site.email
  end
end
