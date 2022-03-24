# frozen_string_literal: true

class Folio::AasmMailer < Folio::ApplicationMailer
  layout "folio/mailer"

  def event(email, subject, simple_text)
    @simple_text = simple_text

    mail to: email,
         subject:,
         bcc: self.class.bcc_email,
         reply_to: self.class.reply_to_email,
         from: self.class.from_email
  end

  def self.bcc_email
    Rails.application.config.folio_aasm_mailer_config.try(:[], :bcc)
  end

  def self.reply_to_email
    Rails.application.config.folio_aasm_mailer_config.try(:[], :reply_to)
  end

  def self.from_email
    Rails.application.config.folio_aasm_mailer_config.try(:[], :from) || Folio::Site.instance.email_from.presence || Folio::Site.instance.email
  end
end
