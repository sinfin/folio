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
    @rich_text = '<p class="redactor-component folio-redactor-button"><a class="btn btn-redactor btn-redactor--fill" href="https://github.com/sinfin/folio/">button label</a></p>'

    mail to: @recipients, from: "Folio Test", subject: "Test"
  end
end
