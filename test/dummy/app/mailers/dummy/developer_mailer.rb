# frozen_string_literal: true

class Dummy::DeveloperMailer < ApplicationMailer
  def debug
    # Note: if more than one recipient is specified, the email may drop into the spam inbox
    @recipients = []

    # Litmus - Sinfin (paused account)
    # @recipients << "sinfin.9e34@litmusemail.com"

    # Litmus - David (inactive account)
    # @recipients << "davidduben1.e423@litmusemail.com"

    # Email on Acid - David (please dont use this address (only one possible preview left))
    # @recipients << "DavidTheTester+default@precheck.emailonacid.com"

    # Outlook
    # @recipients << "test.sinfin@outlook.cz"

    # Outlook 2. account
    # @recipients << "test.sinfin@outlook.com"

    # Gmail
    @recipients << "david.duben@sinfin.cz"

    # Seznam
    # @recipients << "duben4@seznam.cz"

    # Centrum
    # @recipients << "best.test@centrum.cz"

    # Denis
    # @recipients << "denis@sinfin.cz"

    mail to: @recipients, from: "Folio Test", subject: "Test"
  end
end
