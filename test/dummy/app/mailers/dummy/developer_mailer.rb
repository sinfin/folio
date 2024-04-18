# frozen_string_literal: true

class Dummy::DeveloperMailer < ApplicationMailer
  def debug
    # Litmus - Sinfin
    # @recipient = "sinfin.9e34@litmusemail.com"

    # Litmus - David
    # @recipient = "davidduben1.e423@litmusemail.com"

    # Outlook
    # @recipient = "test.sinfin@outlook.cz"

    # Gmail
    @recipient = "david.duben@sinfin.cz"

    # Seznam
    # @recipient = "duben4@seznam.cz"

    # Centrum
    # @recipient = "best.test@centrum.cz"

    # Denis
    # @recipient = "denis@sinfin.cz"

    mail to: @recipient, from: "Folio Test", subject: "Test"
  end
end
