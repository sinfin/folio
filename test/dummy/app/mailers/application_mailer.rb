# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: "from@example.com",
          bcc: Rails.application.config.folio_mailer_global_bcc

  layout "mailer"
end
