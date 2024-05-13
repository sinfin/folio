# frozen_string_literal: true

class Dummy::DeveloperMailer < ApplicationMailer
  def debug
    # Note: if more than one recipient is specified, the email may drop into the spam inbox
    @recipients = []

    # Litmus - Sinfin (paused account)
    # @recipients << "sinfin.9e34@litmusemail.com"

    # Gmail
    @recipients << "david.duben@sinfin.cz"

    # Denis
    # @recipients << "denis@sinfin.cz"

    mail to: @recipients, from: "Folio Test", subject: "Test"
  end
end
