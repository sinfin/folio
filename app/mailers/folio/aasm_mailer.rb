# frozen_string_literal: true

class Folio::AasmMailer < Folio::ApplicationMailer
  layout "folio/mailer"

  def event(email, subject, simple_text)
    @simple_text = simple_text

    mail to: email,
         subject: subject
  end
end
